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

echo ""
echo "Results: ${PASSED} passed, ${FAILED} failed"
[[ "$FAILED" -eq 0 ]]
