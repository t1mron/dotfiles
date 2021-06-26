[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx &> /dev/null

source $HOME/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Plugins
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle git

# Load the theme.
antigen theme spaceship-prompt/spaceship-prompt

# Tell Antigen that you're done.
antigen apply

# User configuration
alias ls='lsd'

spaceship_prompt() {
  RETVAL=$?

  [[ $UID == 0 ]] && SPACESHIP_PROMPT_NEED_NEWLINE=true
  [[ $SPACESHIP_PROMPT_ADD_NEWLINE == true && $SPACESHIP_PROMPT_NEED_NEWLINE == true ]] && echo -n "$NEWLINE"
  SPACESHIP_PROMPT_NEED_NEWLINE=true
  spaceship::compose_prompt $SPACESHIP_PROMPT_ORDER
}
