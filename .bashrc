[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null

#########
# BASIC #
#########

export EDITOR="nvim"
export PF_INFO="ascii title host kernel shell pkgs wm editor memory"


#########
# ALIAS #
#########

alias ls='ls --color=auto' # colorize the ls output
alias vim='nvim'
alias pfetch='$HOME/.config/pfetch/pfetch'


##########
# CUSTOM #
##########

CLR_GREEN="\[\033[0;32m\]"
CLR_CYAN="\[\033[0;36m\]"
CLR_MAGENTA="\[\033[0;35m\]"
CLR_RED="\[\033[0;31m\]"
CLR_CLEAR="\[\033[0m\]"

###---PS---###
function we_are_in_git_work_tree {
  printf "%s" $(git rev-parse --is-inside-work-tree 2>/dev/null) 
}

function git_branch {
  if [[ "true" == $(we_are_in_git_work_tree) ]]; then
    local BR=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
    if [ "$BR" == HEAD ]; then
      local NM=$(git name-rev --name-only HEAD 2> /dev/null)
      if [ "$NM" != undefined ]; then 
        printf $NM
      else 
        git rev-parse --short HEAD 2> /dev/null
      fi
    else
      printf $BR
    fi
  fi
  if [[ "$?" != 0 ]]; then
    return 127
  fi
}

function git_status {
  if [[ "true" == $(we_are_in_git_work_tree) ]]; then
    local ST=$(git status --short 2> /dev/null)
    if [[ -n "$ST" ]]; then 
      printf "+"
    fi
  fi
  if [[ "$?" != 0 ]]; then
    return 127
  fi 
}

function ret_status {
  if [[ "$?" == 0 ]]; then
    printf ${CLR_GREEN:2:10} 
  else 
    printf ${CLR_RED:2:10}
    return 127
  fi
}

function command_not_found_handle {
  tput setaf 1;
  printf "command not found\n"
  tput sgr0;
  return 127
}

PS1="$CLR_CYAN\w $CLR_MAGENTA\$(git_branch) $CLR_GREEN\$(git_status)\n\[\$(ret_status)\]➜$CLR_CLEAR "

###---HSTR---###
alias hh=hstr                    # hh to be alias for hstr
shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL=ignorespace   # leading space hides commands from history
export HISTFILESIZE=10000        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)
# ensure synchronization between bash memory and history file
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"
export HSTR_CONFIG=hide-basic-help,hicolor
export HSTR_PROMPT="  "
# if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi
# if this is interactive shell, then bind 'kill last command' to Ctrl-x k
if [[ $- =~ .*i.* ]]; then bind '"\C-xk": "\C-a hstr -k \C-j"'; fi

# bash suggestions !<command> + space
bind Space:magic-space
