[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null

#########
# BASIC #
#########

export PF_INFO="ascii title host kernel shell pkgs wm memory"
export EDITOR="/usr/bin/vim"

#########
# ALIAS #
#########

alias ls='ls --color=auto' # colorize the ls output
alias pfetch='$HOME/.config/pfetch/pfetch'


##########
# CUSTOM #
##########

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

###---PS---###
export PS1='$(EXIT=${PIPESTATUS[-1]};prompt)'   

function prompt() {
  local L="\001\033"
  local R="\002"

  local RCol="$L[0m$R"  # Text Reset

  # Regular          
  local Bla="$L[0;30m$R"
  local Red="$L[0;31m$R"
  local Gre="$L[0;32m$R"
  local Yel="$L[0;33m$R"
  local Blu="$L[0;34m$R"
  local Pur="$L[0;35m$R"
  local Cya="$L[0;36m$R"
  local Whi="$L[0;37m$R"

  function we_are_in_git_work_tree() {
    printf "%s" $(git rev-parse --is-inside-work-tree 2>/dev/null) 
  }

  function git_branch() {
    if [[ "true" == $(we_are_in_git_work_tree) ]]; then
      local BR=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
      if [[ "$BR" == HEAD ]]; then
       local NM=$(git name-rev --name-only HEAD 2> /dev/null)
        if [[ "$NM" != undefined ]]; then 
          printf "%s" $Pur $NM
        else 
          git rev-parse --short HEAD 2> /dev/null
        fi
      else
        printf "%s" $Pur $BR
      fi
    fi
  }

  function git_status() {
    if [[ "true" == $(we_are_in_git_work_tree) ]]; then
      local ST=$(git status --short 2> /dev/null)
      if [[ -n "$ST" ]]; then 
        printf "%s+" $Gre 
      fi
    fi
  }

  function ret_status() {
    case "$EXIT" in
      0)
        printf "%s➜" $Gre ;;
      *)
        printf "%s➜" $Red ;;
    esac
  }

  local PWD="$Cya~${PWD/$HOME}"
  local CMD="$PWD $(git_branch) $(git_status)\n$(ret_status)$RCol"

  printf "%b " $CMD
}

function command_not_found_handle() {
  tput setaf 1;
  printf "command not found\n"
  tput sgr0;
  return 127
}
