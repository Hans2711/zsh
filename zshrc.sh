export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="amuse"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"
plugins=(copyfile copypath sudo dirhistory docker laravel npm nvm zsh-autosuggestions history)
source $ZSH/oh-my-zsh.sh
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

source ~/.config/zsh/aliases.sh
source ~/.config/zsh/options.sh
source ~/.config/zsh/env.sh
source ~/.config/zsh/platform.sh
source ~/.config/zsh/fzf.sh
bindkey -v
source ~/.config/zsh/pastefix.sh
source ~/.config/zsh/nvm.sh
source ~/.config/zsh/keychain.sh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/diesi/.bun/_bun" ] && source "/home/diesi/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
