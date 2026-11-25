#!/usr/bin/env bash
# ==============================================================================
# tests/test_installer.sh - Smoke tests and syntax/lint checks for dotfiles
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASSED=0
FAILED=0

pass() {
  echo "  PASS: $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "  FAIL: $1" >&2
  FAILED=$((FAILED + 1))
}

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$msg"
  else
    fail "$msg (expected=$expected, actual=$actual)"
  fi
}

assert_ne() {
  local unexpected="$1" actual="$2" msg="$3"
  if [[ "$unexpected" != "$actual" ]]; then
    pass "$msg"
  else
    fail "$msg (unexpected=$unexpected)"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="$3"
  if grep -qF "$needle" <<<"$haystack"; then
    pass "$msg"
  else
    fail "$msg (missing '$needle')"
  fi
}

assert_symlink() {
  local path="$1" msg="$2"
  if [[ -L "$path" ]]; then
    pass "$msg"
  else
    fail "$msg (not a symlink: $path)"
  fi
}

# 1. Syntax & lint checks
echo "==> Syntax and lint checks"
mapfile -t SHELL_FILES < <(find "$REPO_DIR" -name '*.sh' -not -path '*/.git/*' | sort)
if [[ ${#SHELL_FILES[@]} -gt 0 ]] && bash -n "${SHELL_FILES[@]}"; then
  pass "bash -n passed on ${#SHELL_FILES[@]} shell scripts"
else
  fail "bash -n failed"
fi

if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error "${SHELL_FILES[@]}"; then
    pass "shellcheck -S error passed"
  else
    fail "shellcheck -S error failed"
  fi
else
  echo "  SKIP: shellcheck not installed"
fi

# 2. --help and --list
echo "==> Help and list flags"
HELP_HOME="$TMP_ROOT/home_help"
mkdir -p "$HELP_HOME"

out="$(HOME="$HELP_HOME" bash "$REPO_DIR/install.sh" --help 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "--help exits 0"
assert_contains "$out" "USAGE:" "--help prints usage"

out="$(HOME="$HELP_HOME" bash "$REPO_DIR/install.sh" --list 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "--list exits 0"
assert_contains "$out" "Available Configurations" "--list shows configs"
assert_contains "$out" "Available Applications" "--list shows apps"

# 3. Default install + backup + idempotency
echo "==> Default install, backup, and idempotency"
DEF_HOME="$TMP_ROOT/home_default"
mkdir -p "$DEF_HOME"
echo "# existing bashrc" >"$DEF_HOME/.bashrc"

HOME="$DEF_HOME" bash "$REPO_DIR/install.sh" >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 0 "$rc" "default install exits 0"
assert_symlink "$DEF_HOME/.bashrc" "default install links ~/.bashrc"
assert_symlink "$DEF_HOME/.config/bash_scripts" "default install links ~/.config/bash_scripts"
assert_symlink "$DEF_HOME/.config/superfile" "default install links ~/.config/superfile"
assert_symlink "$DEF_HOME/.config/nvim" "default install links ~/.config/nvim"
assert_symlink "$DEF_HOME/.config/zellij" "default install links ~/.config/zellij"

if find "$DEF_HOME/.dotfiles_backup" -name '.bashrc' 2>/dev/null | grep -q .; then
  pass "existing ~/.bashrc backed up before symlinking"
else
  fail "existing ~/.bashrc was not backed up"
fi

HOME="$DEF_HOME" bash "$REPO_DIR/install.sh" >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 0 "$rc" "re-running default install is idempotent"

# 4. --all install (run on a temp repo copy so ssh chmod does not dirty git mode)
echo "==> --all install"
ALL_REPO="$TMP_ROOT/repo_all"
ALL_HOME="$TMP_ROOT/home_all"
mkdir -p "$ALL_REPO" "$ALL_HOME"
cp -a "$REPO_DIR/install.sh" "$REPO_DIR/dotfiles.conf" "$REPO_DIR/lib" "$REPO_DIR/configs" "$REPO_DIR/apps" "$ALL_REPO/"

HOME="$ALL_HOME" bash "$ALL_REPO/install.sh" --all >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 0 "$rc" "--all exits 0"
assert_symlink "$ALL_HOME/.config/starship.toml" "--all links starship.toml"
assert_symlink "$ALL_HOME/.config/ghostty" "--all links ghostty"
assert_symlink "$ALL_HOME/.config/mpv" "--all links mpv"
assert_symlink "$ALL_HOME/.config/ssh/config" "--all links ~/.config/ssh/config"
if [[ -f "$ALL_HOME/.ssh/config" ]]; then
  pass "--all creates ~/.ssh/config"
else
  fail "--all missing ~/.ssh/config"
fi
if [[ -f "$ALL_HOME/.config/opencode/opencode.json" ]]; then
  pass "--all installs opencode.json"
else
  fail "--all missing opencode.json"
fi

# 5. Invalid config and flag error exit codes
echo "==> Invalid config and flag error handling"
ERR_HOME="$TMP_ROOT/home_err"
mkdir -p "$ERR_HOME"

HOME="$ERR_HOME" bash "$REPO_DIR/install.sh" -c nonexistent_config >/dev/null 2>&1 && rc=0 || rc=$?
assert_ne 0 "$rc" "nonexistent config exits non-zero"

HOME="$ERR_HOME" bash "$REPO_DIR/install.sh" -c ../escape >/dev/null 2>&1 && rc=0 || rc=$?
assert_ne 0 "$rc" "path traversal config name exits non-zero"

HOME="$ERR_HOME" bash "$REPO_DIR/install.sh" -c "" >/dev/null 2>&1 && rc=0 || rc=$?
assert_ne 0 "$rc" "empty config name exits non-zero"

HOME="$ERR_HOME" bash "$REPO_DIR/install.sh" --unknown-flag >/dev/null 2>&1 && rc=0 || rc=$?
assert_ne 0 "$rc" "unknown flag exits non-zero"

# 6. Empty CONFIG_DIR edge cases
echo "==> Empty CONFIG_DIR edge cases"
EMPTY_REPO="$TMP_ROOT/repo_empty"
EMPTY_HOME="$TMP_ROOT/home_empty"
mkdir -p "$EMPTY_REPO/configs" "$EMPTY_REPO/apps" "$EMPTY_HOME"
cp -a "$REPO_DIR/install.sh" "$REPO_DIR/dotfiles.conf" "$REPO_DIR/lib" "$EMPTY_REPO/"

HOME="$EMPTY_HOME" bash "$EMPTY_REPO/install.sh" --list >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 0 "$rc" "empty CONFIG_DIR --list exits 0"

out="$(HOME="$EMPTY_HOME" bash "$EMPTY_REPO/install.sh" --all 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "empty CONFIG_DIR --all exits 0"
assert_contains "$out" "No configs specified" "empty CONFIG_DIR --all warns cleanly"

out="$(HOME="$EMPTY_HOME" TERM=dumb bash "$EMPTY_REPO/install.sh" -c </dev/null 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "empty CONFIG_DIR -c exits 0"
assert_contains "$out" "No configurations found" "empty CONFIG_DIR -c warns cleanly"

# 7. Dumb-terminal interactive fallback
echo "==> Dumb-terminal interactive input"
DUMB_HOME="$TMP_ROOT/home_dumb"
mkdir -p "$DUMB_HOME"

out="$(HOME="$DUMB_HOME" TERM=dumb bash "$REPO_DIR/install.sh" -c <<<"invalid_input" 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "dumb terminal invalid input exits 0 without crashing"
assert_contains "$out" "No configurations selected" "dumb terminal invalid input reports no selection"

out="$(HOME="$DUMB_HOME" TERM=dumb bash "$REPO_DIR/install.sh" -c <<<"q" 2>&1)" && rc=0 || rc=$?
assert_eq 0 "$rc" "dumb terminal cancel exits 0"
assert_contains "$out" "cancelled" "dumb terminal cancel reports cancellation"

HOME="$DUMB_HOME" TERM=dumb bash "$REPO_DIR/install.sh" -c <<<"1" >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 0 "$rc" "dumb terminal numeric selection exits 0"
assert_symlink "$DUMB_HOME/.bashrc" "dumb terminal numeric selection installs first config"

# 8. version_ge and is_app_installed nvm
echo "==> version_ge and is_app_installed nvm"
# shellcheck source=/dev/null
source "$REPO_DIR/lib/utils.sh"
APPS_DIR="$REPO_DIR/apps"
# shellcheck source=/dev/null
source "$REPO_DIR/lib/app_installer.sh"

version_ge "1.10" "1.2" && rc=0 || rc=$?
assert_eq 0 "$rc" "version_ge 1.10 >= 1.2"

version_ge "1.2" "1.10" && rc=0 || rc=$?
assert_eq 1 "$rc" "version_ge 1.2 < 1.10"

version_ge "1.2" "1.2.0" && rc=0 || rc=$?
assert_eq 0 "$rc" "version_ge 1.2 == 1.2.0"

version_ge "v1.2.3" "1.2.3" && rc=0 || rc=$?
assert_eq 0 "$rc" "version_ge handles v-prefix"

version_ge "0.08" "0.7" && rc=0 || rc=$?
assert_eq 0 "$rc" "version_ge avoids octal on leading zeros"

version_ge "" "1.0" && rc=0 || rc=$?
assert_eq 1 "$rc" "version_ge rejects empty version"

NVM_HOME="$TMP_ROOT/home_nvm"
mkdir -p "$NVM_HOME"
(
  unset NVM_DIR XDG_CONFIG_HOME
  HOME="$NVM_HOME"
  is_app_installed nvm && exit 0 || exit 1
) && rc=0 || rc=$?
assert_eq 1 "$rc" "is_app_installed nvm false when absent"

mkdir -p "$NVM_HOME/.nvm"
echo "# nvm" >"$NVM_HOME/.nvm/nvm.sh"
(
  unset NVM_DIR XDG_CONFIG_HOME
  HOME="$NVM_HOME"
  is_app_installed nvm && exit 0 || exit 1
) && rc=0 || rc=$?
assert_eq 0 "$rc" "is_app_installed nvm true with ~/.nvm/nvm.sh"

NVM_XDG="$TMP_ROOT/xdg_nvm"
mkdir -p "$NVM_XDG/nvm"
echo "# nvm" >"$NVM_XDG/nvm/nvm.sh"
(
  unset NVM_DIR
  HOME="$TMP_ROOT/home_nvm_empty"
  XDG_CONFIG_HOME="$NVM_XDG"
  is_app_installed nvm && exit 0 || exit 1
) && rc=0 || rc=$?
assert_eq 0 "$rc" "is_app_installed nvm true with XDG_CONFIG_HOME/nvm/nvm.sh"

(
  NVM_DIR="$TMP_ROOT/missing_nvm"
  HOME="$NVM_HOME"
  is_app_installed nvm && exit 0 || exit 1
) && rc=0 || rc=$?
assert_eq 1 "$rc" "is_app_installed nvm respects explicit NVM_DIR"

# 9. magic-shell.sh git prompt states and scope hygiene
echo "==> magic-shell.sh git prompt"
MAGIC_OUT="$(
  set -euo pipefail
  # shellcheck source=/dev/null
  source "$REPO_DIR/configs/bash_scripts/magic-shell.sh"
  git init -q --bare "$TMP_ROOT/magic_remote.git"
  git init -q -b main "$TMP_ROOT/magic_repo"
  cd "$TMP_ROOT/magic_repo"
  git config user.email "t@example.com"
  git config user.name "Test"
  echo "1" >f1 && echo "2" >f2 && echo "3" >f3
  git add f1 f2 f3 && git commit -q -m "init"
  git remote add origin "$TMP_ROOT/magic_remote.git"
  git push -q -u origin main

  [[ "$(LC_ALL=C parse_git_branch)" == " [main]" ]] || { echo "clean:$(parse_git_branch)"; exit 1; }
  echo "u" >untracked.txt
  [[ "$(LC_ALL=C parse_git_branch)" == " [main ?]" ]] || { echo "untracked:$(parse_git_branch)"; exit 1; }
  echo "m" >>f1
  [[ "$(LC_ALL=C parse_git_branch)" == " [main !?]" ]] || { echo "modified:$(parse_git_branch)"; exit 1; }
  echo "n" >new.txt && git add new.txt
  [[ "$(LC_ALL=C parse_git_branch)" == " [main !?+]" ]] || { echo "staged:$(parse_git_branch)"; exit 1; }
  rm f2
  [[ "$(LC_ALL=C parse_git_branch)" == " [main !x?+]" ]] || { echo "deleted:$(parse_git_branch)"; exit 1; }
  git mv f3 f3_ren
  [[ "$(LC_ALL=C parse_git_branch)" == " [main !x?+>]" ]] || { echo "renamed:$(parse_git_branch)"; exit 1; }
  rm untracked.txt && git commit -q -am "ahead"
  [[ "$(LC_ALL=C parse_git_branch)" == " [main *]" ]] || { echo "ahead:$(parse_git_branch)"; exit 1; }

  BRANCH="keep" status="keep" dirty="keep" bits="keep"
  parse_git_branch >/dev/null
  [[ "$BRANCH:$status:$dirty:$bits" == "keep:keep:keep:keep" ]] || { echo "leaked"; exit 1; }
  for v in STAT untracked ahead newfile renamed deleted line xy ch branch stat; do
    [[ ! -v "$v" ]] || { echo "leaked:$v"; exit 1; }
  done
  echo "ok"
)" && rc=0 || rc=$?
assert_eq 0 "$rc" "magic-shell.sh handles all git states without leaking globals"
assert_eq "ok" "$MAGIC_OUT" "magic-shell.sh prompt markers and scope check passed"

# 10. Interactive UI viewport scrolling on short terminals
echo "==> Interactive UI viewport scrolling"
if command -v python3 >/dev/null 2>&1; then
  ui_out="$(python3 - "$REPO_DIR" <<'PY'
import fcntl, os, pty, re, select, struct, subprocess, sys, termios, time

repo = sys.argv[1]

def run_ui(rows, keys, body=None):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, 80, 0, 0))
    if body is None:
        body = (
            'items=(); for i in $(seq -w 1 28); do items+=("$(printf "app%s\\t0\\t\\tdesc app%s" "$i" "$i")"); done; '
            'run_interactive_checklist "Apps" "${items[@]}"'
        )
    cmd = [
        "bash", "-c",
        f'set -euo pipefail; source "{repo}/lib/utils.sh"; source "{repo}/lib/ui.sh"; {body}'
    ]
    env = os.environ.copy()
    env["TERM"] = "xterm-256color"
    proc = subprocess.Popen(cmd, stdin=slave, stdout=slave, stderr=slave, env=env, close_fds=True)
    os.close(slave)
    out = bytearray()
    def drain(wait=0.25):
        end = time.time() + wait
        while time.time() < end:
            r, _, _ = select.select([master], [], [], 0.03)
            if r:
                try:
                    chunk = os.read(master, 4096)
                    if not chunk:
                        break
                    out.extend(chunk)
                except OSError:
                    break
    drain(0.35)
    for k in keys:
        os.write(master, k)
        drain(0.08)
    proc.wait(timeout=5)
    os.close(master)
    return out.decode("utf-8", errors="replace"), proc.returncode

for rows, keys, expect_range in ((10, [b"k", b" ", b"\r"], "27-28/28"), (24, [b"j"]*15 + [b"q"], "8-23/28")):
    text, rc = run_ui(rows, keys)
    clean = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text)
    ups = [int(m) for m in re.findall(r"\x1b\[(\d+)A", text)]
    assert ups and all(u < rows for u in ups), f"rows={rows} cursor-up overflow: {ups}"
    assert expect_range in clean, f"rows={rows} missing viewport {expect_range}"
    if b"\r" in keys:
        assert rc == 0 and "app28" in clean.splitlines()[-1], f"rows={rows} selection failed: rc={rc}"

badge_text, badge_rc = run_ui(
    12, [b"\r"],
    'run_interactive_checklist "Apps" "$(printf "a\\t1\\t[ok]\\tdesc a")" "b"'
)
badge_clean = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", badge_text)
assert badge_rc == 0 and "[ok]" in badge_clean and "desc a" in badge_clean
assert "Selected: 1/2" in badge_clean and badge_clean.splitlines()[-1].strip() == "a"
print("viewport ok")
PY
  )" && rc=0 || rc=$?
  assert_eq 0 "$rc" "interactive checklist scrolls cleanly at 10 and 24 rows"
  assert_contains "$ui_out" "viewport ok" "interactive checklist viewport ranges and selection verified"
else
  echo "  SKIP: python3 not installed"
fi

# 11. lib/utils.sh helpers and .target symlink verification
echo "==> Helper functions and .target symlink checks"
# shellcheck source=/dev/null
source "$REPO_DIR/lib/utils.sh"

PATH_DIR="$TMP_ROOT/bin_test"
mkdir -p "$PATH_DIR"
ORIG_PATH="$PATH"
PATH="/usr/bin"
prepend_path "$PATH_DIR"
assert_eq "$PATH_DIR:/usr/bin" "$PATH" "prepend_path adds existing directory"
prepend_path "$PATH_DIR"
assert_eq "$PATH_DIR:/usr/bin" "$PATH" "prepend_path is idempotent"
prepend_path "$TMP_ROOT/does_not_exist"
assert_eq "$PATH_DIR:/usr/bin" "$PATH" "prepend_path ignores missing directory"
PATH=""
prepend_path "$PATH_DIR"
assert_eq "$PATH_DIR" "$PATH" "prepend_path avoids trailing colon on empty PATH"
PATH="$ORIG_PATH"

# Verify get_github_latest_version with mocked curl/wget
MOCK_BIN="$TMP_ROOT/mock_bin"
mkdir -p "$MOCK_BIN"
cat >"$MOCK_BIN/curl" <<'EOF'
#!/usr/bin/env bash
case "${MOCK_CURL_MODE:-api}" in
  api) echo '{"tag_name": "v1.2.3"}' ;;
  loc) printf 'HTTP/2 302\r\nlocation: https://github.com/o/r/releases/tag/v2.4.0-rc1\r\n' ;;
  empty) ;;
esac
EOF
chmod +x "$MOCK_BIN/curl"
cat >"$MOCK_BIN/wget" <<'EOF'
#!/usr/bin/env bash
if [[ "${MOCK_WGET_MODE:-fail}" == "ok" ]]; then
  echo '{"tag_name": "v3.0.1"}'
fi
EOF
chmod +x "$MOCK_BIN/wget"

ver="$(PATH="$MOCK_BIN:$ORIG_PATH" MOCK_CURL_MODE=api get_github_latest_version "o/r" "0.0.1")"
assert_eq "1.2.3" "$ver" "get_github_latest_version parses API tag_name"
ver="$(PATH="$MOCK_BIN:$ORIG_PATH" MOCK_CURL_MODE=loc get_github_latest_version "o/r" "0.0.1")"
assert_eq "2.4.0-rc1" "$ver" "get_github_latest_version parses Location header"
ver="$(PATH="$MOCK_BIN:$ORIG_PATH" MOCK_CURL_MODE=empty MOCK_WGET_MODE=ok get_github_latest_version "o/r" "0.0.1")"
assert_eq "3.0.1" "$ver" "get_github_latest_version falls back to wget"
ver="$(PATH="$MOCK_BIN:$ORIG_PATH" MOCK_CURL_MODE=empty MOCK_WGET_MODE=fail get_github_latest_version "o/r" "9.9.9")"
assert_eq "9.9.9" "$ver" "get_github_latest_version uses fallback when offline"
ver="$(PATH="$MOCK_BIN:$ORIG_PATH" MOCK_CURL_MODE=empty MOCK_WGET_MODE=fail get_github_latest_version "o/r")"
assert_eq "" "$ver" "get_github_latest_version returns empty when fallback omitted"

# Verify configs/neovim/.target symlink target
assert_eq "$REPO_DIR/configs/neovim/nvim" "$(readlink "$DEF_HOME/.config/nvim")" ".target links ~/.config/nvim to configs/neovim/nvim"

# 12. lib/utils.sh installer primitives
echo "==> lib/utils.sh installer primitives"
UTILS_MOCK="$TMP_ROOT/utils_mock"
UTILS_HOME="$TMP_ROOT/utils_home"
UTILS_TMP="$TMP_ROOT/utils_tmp"
mkdir -p "$UTILS_MOCK" "$UTILS_HOME" "$UTILS_TMP/work"

cat >"$UTILS_MOCK/mytool" <<'EOF'
#!/usr/bin/env bash
echo "mytool version 1.5.0"
EOF
chmod +x "$UTILS_MOCK/mytool"

PATH="$UTILS_MOCK:$ORIG_PATH" is_cmd_up_to_date "mytool" "1.5.0" mytool >/dev/null && rc=0 || rc=$?
assert_eq 0 "$rc" "is_cmd_up_to_date returns 0 when up-to-date"
PATH="$UTILS_MOCK:$ORIG_PATH" is_cmd_up_to_date "mytool" "2.0.0" mytool >/dev/null && rc=0 || rc=$?
assert_eq 1 "$rc" "is_cmd_up_to_date returns 1 when outdated"
PATH="$UTILS_MOCK:$ORIG_PATH" is_cmd_up_to_date "mytool" "" --keep-if-offline mytool >/dev/null && rc=0 || rc=$?
assert_eq 0 "$rc" "is_cmd_up_to_date --keep-if-offline returns 0 when offline"
PATH="$UTILS_MOCK:$ORIG_PATH" is_cmd_up_to_date "mytool" "" mytool >/dev/null && rc=0 || rc=$?
assert_eq 1 "$rc" "is_cmd_up_to_date returns 1 when latest empty without --keep-if-offline"
PATH="$UTILS_MOCK:$ORIG_PATH" is_cmd_up_to_date "missing" "1.0.0" no_such_tool_xyz >/dev/null && rc=0 || rc=$?
assert_eq 1 "$rc" "is_cmd_up_to_date returns 1 when command missing"

cat >"$UTILS_MOCK/curl" <<'EOF'
#!/usr/bin/env bash
out="" url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
case "$url" in
  *primary*) printf 'primary-data' >"$out" ;;
  *fallback*) printf 'fallback-data' >"$out" ;;
  *empty*) : >"$out" ;;
  *tarball*) cp "$MOCK_TAR_FILE" "$out" ;;
  *key*) printf 'KEYDATA' >"$out" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$UTILS_MOCK/curl"

cat >"$UTILS_MOCK/wget" <<'EOF'
#!/usr/bin/env bash
out="" url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -qO) out="$2"; shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
case "$url" in
  *wgetok*) printf 'wget-data' >"$out" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$UTILS_MOCK/wget"

PATH="$UTILS_MOCK:$ORIG_PATH" download_file "$UTILS_TMP/dl1" "https://x/primary" && rc=0 || rc=$?
assert_eq 0 "$rc" "download_file succeeds on primary URL"
assert_eq "primary-data" "$(cat "$UTILS_TMP/dl1")" "download_file writes primary payload"

PATH="$UTILS_MOCK:$ORIG_PATH" download_file "$UTILS_TMP/dl2" "https://x/bad" "https://x/fallback" && rc=0 || rc=$?
assert_eq 0 "$rc" "download_file falls back across URLs"
assert_eq "fallback-data" "$(cat "$UTILS_TMP/dl2")" "download_file writes fallback payload"

PATH="$UTILS_MOCK:$ORIG_PATH" download_file "$UTILS_TMP/dl3" "https://x/empty" && rc=0 || rc=$?
assert_eq 1 "$rc" "download_file rejects empty download"
assert_eq 0 "$([[ -e "$UTILS_TMP/dl3" ]] && echo 1 || echo 0)" "download_file removes empty destination"

(
  export PATH="$UTILS_MOCK:$ORIG_PATH"
  has_cmd() { [[ "$1" != "curl" ]] && command -v "$1" >/dev/null 2>&1; }
  download_file "$UTILS_TMP/dl4" "https://x/wgetok"
) && rc=0 || rc=$?
assert_eq 0 "$rc" "download_file falls back to wget when curl unavailable"
assert_eq "wget-data" "$(cat "$UTILS_TMP/dl4")" "download_file wget writes payload"

cat >"$UTILS_MOCK/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
chmod +x "$UTILS_MOCK/sudo"

for mgr in apt-get dnf brew; do
  cat >"$UTILS_MOCK/$mgr" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' "$mgr" "\$*" >>"\${PKG_LOG}"
EOF
  chmod +x "$UTILS_MOCK/$mgr"
done

printf '#!/usr/bin/env bash\necho ok\n' >"$UTILS_TMP/src_bin"
install_binary "$TMP_ROOT/missing_bin" "x" "$UTILS_HOME/custom_bin" >/dev/null 2>&1 && rc=0 || rc=$?
assert_eq 1 "$rc" "install_binary fails on missing source"
install_binary "$UTILS_TMP/src_bin" "mybin" "$UTILS_HOME/custom_bin" && rc=0 || rc=$?
assert_eq 0 "$rc" "install_binary installs to custom target_dir"
assert_eq 1 "$([[ -x "$UTILS_HOME/custom_bin/mybin" ]] && echo 1 || echo 0)" "install_binary sets executable mode"

(
  export HOME="$UTILS_HOME" PATH="$UTILS_MOCK:$UTILS_HOME/.local/bin:$ORIG_PATH"
  ensure_bin_alias "mytool" "mytool_alias"
)
assert_symlink "$UTILS_HOME/.local/bin/mytool_alias" "ensure_bin_alias creates ~/.local/bin symlink"
assert_eq "$UTILS_MOCK/mytool" "$(readlink "$UTILS_HOME/.local/bin/mytool_alias")" "ensure_bin_alias targets resolved command"

mkdir -p "$UTILS_TMP/tar_src/nested"
printf '#!/usr/bin/env bash\necho spf\n' >"$UTILS_TMP/tar_src/nested/spf"
tar -czf "$UTILS_TMP/spf.tar.gz" -C "$UTILS_TMP/tar_src" nested/spf

(
  export HOME="$UTILS_HOME" TMPDIR="$UTILS_TMP/work" MOCK_TAR_FILE="$UTILS_TMP/spf.tar.gz" PATH="$UTILS_MOCK:$ORIG_PATH"
  install_tar_binary "other|spf" "superfile" "https://x/tarball" >/dev/null
) && rc=0 || rc=$?
assert_eq 0 "$rc" "install_tar_binary extracts and installs matching pattern"
assert_eq 1 "$([[ -x "$UTILS_HOME/.local/bin/superfile" ]] && echo 1 || echo 0)" "install_tar_binary installs to ~/.local/bin"
assert_eq "" "$(find "$UTILS_TMP/work" -mindepth 1 2>/dev/null)" "install_tar_binary cleans up temp dir"

(
  export HOME="$UTILS_HOME" TMPDIR="$UTILS_TMP/work" MOCK_TAR_FILE="$UTILS_TMP/spf.tar.gz" PATH="$UTILS_MOCK:$ORIG_PATH"
  install_tar_binary "missing_pat" "nope" "https://x/tarball" >/dev/null 2>&1
) && rc=0 || rc=$?
assert_eq 1 "$rc" "install_tar_binary returns 1 when binary missing"
assert_eq "" "$(find "$UTILS_TMP/work" -mindepth 1 2>/dev/null)" "install_tar_binary cleans up temp dir on failure"

PKG_LOG="$UTILS_TMP/pkg.log"
: >"$PKG_LOG"
(
  export PATH="$UTILS_MOCK:$ORIG_PATH" PKG_LOG
  has_cmd() { [[ "$1" == "apt-get" || "$1" == "sudo" ]]; }
  pkg_install "fd" "apt=fd-find" "dnf=fd-find"
) && rc=0 || rc=$?
assert_eq 0 "$rc" "pkg_install apt override exits 0"
assert_contains "$(cat "$PKG_LOG")" "apt-get install -y fd-find" "pkg_install apt uses override package"

: >"$PKG_LOG"
(
  export PATH="$UTILS_MOCK:$ORIG_PATH" PKG_LOG
  has_cmd() { [[ "$1" == "dnf" || "$1" == "sudo" ]]; }
  pkg_install "ripgrep" "apt=ripgrep"
) && rc=0 || rc=$?
assert_eq 0 "$rc" "pkg_install dnf exits 0"
assert_contains "$(cat "$PKG_LOG")" "dnf install -y ripgrep" "pkg_install dnf installs default package"

: >"$PKG_LOG"
(
  export PATH="$UTILS_MOCK:$ORIG_PATH" PKG_LOG
  has_cmd() { [[ "$1" == "brew" || "$1" == "sudo" ]]; }
  pkg_install "ripgrep"
) && rc=0 || rc=$?
assert_eq 0 "$rc" "pkg_install brew exits 0"
assert_contains "$(cat "$PKG_LOG")" "brew install ripgrep" "pkg_install brew installs package"

(
  export PATH="$UTILS_MOCK:$ORIG_PATH"
  has_cmd() { [[ "$1" == "apt-get" || "$1" == "sudo" ]]; }
  pkg_install "eza" "apt="
) && rc=0 || rc=$?
assert_eq 2 "$rc" "pkg_install empty override returns 2"

: >"$PKG_LOG"
(
  export PATH="$UTILS_MOCK:$ORIG_PATH" PKG_LOG
  has_cmd() { [[ "$1" == "curl" || "$1" == "sudo" || "$1" == "apt-get" ]]; }
  add_apt_repo "https://x/key" "$UTILS_HOME/apt/test.gpg" "deb [signed-by=$UTILS_HOME/apt/test.gpg] https://x/deb stable main" "$UTILS_HOME/apt/test.list"
) && rc=0 || rc=$?
assert_eq 0 "$rc" "add_apt_repo exits 0"
assert_eq "KEYDATA" "$(cat "$UTILS_HOME/apt/test.gpg")" "add_apt_repo writes keyring"
assert_contains "$(cat "$UTILS_HOME/apt/test.list")" "deb [signed-by=$UTILS_HOME/apt/test.gpg]" "add_apt_repo writes source list"
assert_contains "$(cat "$PKG_LOG")" "apt-get update -qq" "add_apt_repo runs apt-get update"

# 13. workspacectl.sh
echo "==> workspacectl.sh"
WS_HOME="$TMP_ROOT/ws_home"
WS_MOCK="$TMP_ROOT/ws_mock"
WS_GIT_LOG="$TMP_ROOT/ws_git.log"
mkdir -p "$WS_HOME/proj" "$WS_MOCK"
: >"$WS_GIT_LOG"

cat >"$WS_MOCK/curl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *api.github.com*) echo '{"login":"octocat","id":583231}' ;;
  *gitlab.com*) echo '[{"id":12345,"username":"gluser"}]' ;;
  *) echo '{}' ;;
esac
EOF
chmod +x "$WS_MOCK/curl"

cat >"$WS_MOCK/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${WS_GIT_LOG}"
if [[ "$1" == "config" && "$2" == "--global" && "$3" == "user.email" && $# -eq 3 ]]; then
  printf '%s' "${MOCK_GIT_EMAIL:-}"
fi
EOF
chmod +x "$WS_MOCK/git"

(
  set -euo pipefail
  export HOME="$WS_HOME"
  unset PROJECT_WORKSPACE GEMINI_API_KEY
  # shellcheck source=/dev/null
  source "$REPO_DIR/configs/bash_scripts/workspacectl.sh"

  ! wsctl get-workspace >/dev/null 2>&1
  wsctl set-workspace "$WS_HOME/proj" >/dev/null
  # shellcheck source=/dev/null
  source "$WS_HOME/.workspace"
  [[ "$(wsctl get-workspace)" == "$WS_HOME/proj" ]]

  ! wsctl set-gemini-api "" >/dev/null 2>&1
  wsctl set-gemini-api "test-api-key" >/dev/null
  mode="$(stat -c '%a' "$WS_HOME/.gemini_api" 2>/dev/null || stat -f '%Lp' "$WS_HOME/.gemini_api")"
  [[ "$mode" == "600" ]]
  grep -qF "test-api-key" "$WS_HOME/.gemini_api"

  export GEMINI_API_KEY="test-api-key"
  wsctl --reset
  [[ ! -e "$WS_HOME/.workspace" && ! -e "$WS_HOME/.gemini_api" ]]
  [[ -z "${PROJECT_WORKSPACE:-}" && -z "${GEMINI_API_KEY:-}" ]]

  [[ "$(_wsctl_extract_id '{"login":"octocat","id":583231}')" == "583231" ]]
  [[ "$(_wsctl_extract_id '[{"id":12345,"username":"gluser"}]')" == "12345" ]]
  [[ -z "$(_wsctl_extract_id '{}')" ]]

  export PATH="$WS_MOCK:$ORIG_PATH" WS_GIT_LOG
  MOCK_GIT_EMAIL="" _wsctl_configure_provider "GitHub" "github.com" "users.noreply.github.com" "+" "https://api.github.com/users/" <<<$'octocat\ny' >/dev/null
  MOCK_GIT_EMAIL="existing@example.com" _wsctl_configure_provider "Codeberg" "codeberg.org" "noreply.codeberg.org" <<<$'cbuser\ny' >/dev/null
) && rc=0 || rc=$?
assert_eq 0 "$rc" "workspacectl.sh set/get-workspace, gemini-api 0600, --reset, and _wsctl_extract_id passed"
assert_contains "$(cat "$WS_GIT_LOG")" "config --global includeIf.hasconfig:remote.*.url:**/*github.com/**.email 583231+octocat@users.noreply.github.com" "_wsctl_configure_provider sets GitHub includeIf email"
assert_contains "$(cat "$WS_GIT_LOG")" "config --global user.email 583231+octocat@users.noreply.github.com" "_wsctl_configure_provider sets fallback user.email"
assert_contains "$(cat "$WS_GIT_LOG")" "config --global includeIf.hasconfig:remote.*.url:**/*codeberg.org/**.email cbuser@noreply.codeberg.org" "_wsctl_configure_provider sets Codeberg includeIf email"
if grep -qF "config --global user.email cbuser@noreply.codeberg.org" "$WS_GIT_LOG"; then
  fail "_wsctl_configure_provider overwrote existing user.email"
else
  pass "_wsctl_configure_provider preserves existing user.email"
fi

echo ""
echo "Results: ${PASSED} passed, ${FAILED} failed"
[[ "$FAILED" -eq 0 ]]
