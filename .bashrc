export PATH="$PATH:$HOME/.local/bin"
export EDITOR=vim

#########
# ALIAS #
#########

alias sudo='doas'
alias ls='ls --color=auto'
alias grep='grep --color=auto'


##########
# CUSTOM #
##########

# prompt
normal="\[\e[0m\]"
blue="\[\e[0;34m\]"

PS1="$blue\w $normal\n ➜ "

# spawn new terminal in the current cwd
_urlencode() {
	local length="${#1}"
	for (( i = 0; i < length; i++ )); do
		local c="${1:$i:1}"
		case $c in
			%) printf '%%%02X' "'$c" ;;
			*) printf "%s" "$c" ;;
		esac
	done
}

osc7_cwd() {
	printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$(_urlencode "$PWD")"
  echo -en "\033]0;$(dirs)\a"
}

PROMPT_COMMAND="osc7_cwd"
