[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null

export ZSH="/home/user/.oh-my-zsh"
export PATH=$PATH:/sbin:/usr/sbin

ZSH_THEME="robbyrussell"
DEFAULT_USER=$USER

unsetopt PROMPT_SP

plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

local ret_status="%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )"
PROMPT=$'%{$fg[cyanhttps://www.youtube.com/watch?v=HoCPBrEB3SM]%}%~%{$reset_color%} $(git_prompt_info)\n${ret_status}'
