# get current branch in git repo
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=`parse_git_dirty`
		echo " [${BRANCH}${STAT}]"
	else
		echo ""
	fi
}

# get current status of git repo
function parse_git_dirty {
	status=`git status 2>&1 | tee`
	dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}

function test_container() {
	[ -f "/.dockerenv" ] && echo "[$USER@$HOSTNAME]"
}

function get_short_path() {
	local path=$(pwd)
	# Replace home directory with ~
	if [[ "$path" == "$HOME"* ]]; then
		path="~${path#$HOME}"
	fi
	local depth=$(echo "$path" | tr '/' '\n' | wc -l)
	if [ $depth -le 2 ]; then
		echo "$path"
	else
		echo "$path" | sed -E 's|.*/([^/]+/[^/]+)$|\1|'
	fi
}

export PS1="\[\e[36m\]\`test_container\`\[\e[m\] \[\e[34m\]\`get_short_path\`\[\e[m\]\[\e[32m\]\`parse_git_branch\` \[\e[m\]\[\e[32m\]➜\[\e[m\] "
