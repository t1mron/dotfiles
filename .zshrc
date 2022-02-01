if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec dbus-run-session sway
fi

###########
# PLUGINS #
###########

source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/git-prompt/git-prompt.zsh

autoload -U colors && colors add-zsh-hook
add-zsh-hook -Uz chpwd osc7_cwd

#########
# BASIC #
#########

export ZSH=$HOME/.zsh
export PATH="$PATH:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/git/void-packages"

#########
# ALIAS #
#########

alias ls='ls --color=auto' # colorize the ls output
alias sudo='doas'


##########
# CUSTOM #
##########


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
}

# command history
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

unsetopt PROMPT_SP  # disable % buffer sybmol
setopt PROMPT_SUBST # use $ variables

# prompt theme
myprompt(){
  ret_status="%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )"
  PS1=$'%{$fg[cyan]%}%~%{$reset_color%} $(gitprompt)\n${ret_status}'
  print -Pn "\e]0;%~\a"
}

precmd () { myprompt;}
