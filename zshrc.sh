export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="amuse"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"
plugins=(copyfile copypath sudo dirhistory docker laravel npm)
source $ZSH/oh-my-zsh.sh
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

source ~/.config/zsh/aliases.sh
source ~/.config/zsh/env.sh
source ~/.config/zsh/platform.sh
source ~/.config/zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source ~/.config/zsh/pastefix.sh
source ~/.config/zsh/nvm.sh

