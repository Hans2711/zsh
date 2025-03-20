zstyle ':autocomplete:*' min-input 3
export skip_global_compinit=1
bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select
bindkey -M menuselect '^M' .accept-line
