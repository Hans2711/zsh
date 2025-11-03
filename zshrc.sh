###############################################
# Oh My Zsh Core (no behavior change)
###############################################

export ZSH="$HOME/.oh-my-zsh"           # Oh My Zsh installation path
ZSH_THEME="amuse"                        # Theme
HYPHEN_INSENSITIVE="true"               # Treat hyphens and underscores as equal in completion
zstyle ':omz:update' mode auto           # Auto-update oh-my-zsh
ENABLE_CORRECTION="true"                # Enable command auto-correction

# Plugins loaded by Oh My Zsh (order preserved)
plugins=(copyfile copypath sudo dirhistory docker laravel npm nvm zsh-autosuggestions history jsontools bun zsh-syntax-highlighting)

# Initialize Oh My Zsh
source $ZSH/oh-my-zsh.sh

###############################################
# Environment & Locale
###############################################
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

###############################################
# Editor Preference (SSH vs local)
###############################################
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

###############################################
# User Config Modules
###############################################
source ~/.config/zsh/aliases.sh
source ~/.config/zsh/options.sh
source ~/.config/zsh/env.sh
source ~/.config/zsh/platform.sh
source ~/.config/zsh/fzf.sh

###############################################
# Key Bindings & Paste Handling
###############################################
bindkey -v                               # Vi key bindings
source ~/.config/zsh/pastefix.sh         # Bracketed paste handling

###############################################
# Node Version Manager (NVM)
###############################################
source ~/.config/zsh/nvm.sh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash_completion if present

###############################################
# SSH Agent / Keychain
###############################################
source ~/.config/zsh/keychain.sh

###############################################
# Bun Runtime & Completions
###############################################
# bun completions
[ -s "/home/diesi/.bun/_bun" ] && source "/home/diesi/.bun/_bun"
# bun path
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

###############################################
# Zoxide (smart cd)
###############################################
eval "$(zoxide init zsh)"
