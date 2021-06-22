[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null

# Path
export ZSH="/home/user/.oh-my-zsh"
export TERM=xterm-256color

ZSH_THEME="spaceship"
DEFAULT_USER=$USER

plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration
spaceship_prompt() {
  RETVAL=$?

  [[ $UID == 0 ]] && SPACESHIP_PROMPT_NEED_NEWLINE=true
  [[ $SPACESHIP_PROMPT_ADD_NEWLINE == true && $SPACESHIP_PROMPT_NEED_NEWLINE == true ]] && echo -n "$NEWLINE"
  SPACESHIP_PROMPT_NEED_NEWLINE=true
  spaceship::compose_prompt $SPACESHIP_PROMPT_ORDER
}

# aliases
alias ls='lsd'
