# fzf defaults (applied to all fzf invocations)
# Keybindings:
# - Ctrl-j / Ctrl-k: move selection (outside tmux)
# - Alt-j / Alt-k: move selection (tmux-friendly)
# - Alt-d / Alt-u: scroll preview down/up
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--bind=ctrl-j:down,ctrl-k:up,alt-j:down,alt-k:up,alt-d:preview-down,alt-u:preview-up"

# fcd: fuzzy-cd into a subdirectory of the current directory
# - Uses `fd` if available for speed; falls back to `find`.
# - Requires `fzf`.
fcd() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found; install fzf to use fcd" >&2
    return 1
  fi

  local dir
  if command -v fd >/dev/null 2>&1; then
    dir=$(fd . . \
      --hidden --follow --type d \
      --exclude .git --exclude node_modules --exclude .venv --exclude .direnv \
      --exclude dist --exclude build --exclude target \
      | fzf --prompt="fcd > " --height=40% --reverse)
  else
    dir=$(find . \
      -path '*/.git' -prune -o \
      -path '*/node_modules' -prune -o \
      -path '*/.venv' -prune -o \
      -path '*/.direnv' -prune -o \
      -path '*/dist' -prune -o \
      -path '*/build' -prune -o \
      -path '*/target' -prune -o \
      -type d -print \
      | sed '1d' \
      | fzf --prompt="fcd > " --height=40% --reverse)
  fi

  [[ -n "$dir" ]] || return 1
  cd -- "$dir"
}

# wcd: fuzzy-cd into a directory under /var/www (depth 1)
wcd() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found; install fzf to use wcd" >&2
    return 1
  fi

  local root="/var/www"
  if [ ! -d "$root" ]; then
    echo "Directory not found: $root" >&2
    return 1
  fi

  local dir
  dir=$(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | sort \
    | fzf --prompt="wcd > " --height=40% --reverse)

  [[ -n "$dir" ]] || return 1
  cd -- "$dir"
}
