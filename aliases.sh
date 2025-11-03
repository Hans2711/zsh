###############################################
# Aliases and Sourced Helpers (no behavior change)
###############################################

# Navigation & listing
alias cd='z'               # Jump with z/zoxide using cd alias
alias l='ls -lahF'         # Long, all, human, classify

# Docker
alias docker-compose='docker compose'  # Use new `docker compose` subcommand

# Git helpers
source ~/.config/zsh/git.sh            # Load git shortcuts and functions

# PHP tooling
# PHP CS Fixer command
# Runs the php-cs-fixer binary stored in this repo's binaries folder
alias php-cs-fixer="php $HOME/.config/zsh/binaries/php-cs-fixer"
