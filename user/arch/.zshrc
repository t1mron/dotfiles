[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null


###########
# PLUGINS #
###########

source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/git-prompt/git-prompt.zsh

autoload -U colors && colors


#########
# BASIC #
#########

export ZSH=$HOME/.zsh
export PATH="$PATH:/usr/sbin:/usr/bin:/sbin:/bin"


#########
# ALIAS #
#########

alias ls='ls --color=auto' # colorize the ls output


##########
# CUSTOM #
##########

# command history
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

unsetopt PROMPT_SP  # disable % buffer sybmol
setopt PROMPT_SUBST # use $ variables

# prompt theme
local ret_status="%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )"
PROMPT=$'%{$fg[cyan]%}%~%{$reset_color%} $(gitprompt)\n${ret_status}'
