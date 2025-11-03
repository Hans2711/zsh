###############################################
# Zsh Options (grouped, no behavior change)
###############################################

## History: recording behavior
setopt append_history          # Append to history file instead of overwriting
setopt hist_reduce_blanks      # Strip superfluous blanks before saving
setopt hist_no_store           # Do not record 'history'/'fc' commands themselves

## History: formatting and search
setopt extended_history        # Use ':start:elapsed;command' format with timestamps
setopt hist_find_no_dups       # Skip already-found event during history search
setopt hist_verify             # After '!' expansion, show line instead of executing
unsetopt hist_beep             # No beep on invalid history reference

## History: duplicates and filtering
setopt hist_ignore_space       # Ignore commands that start with a space
setopt hist_ignore_dups        # Ignore immediately repeated commands
setopt hist_ignore_all_dups    # Remove older duplicate when a new duplicate is saved
setopt hist_save_no_dups       # Do not write duplicates to the history file
setopt hist_expire_dups_first  # When trimming, drop oldest duplicates first

## History: synchronization & locking
unsetopt inc_append_history    # Do not write history incrementally; write on exit
unsetopt share_history         # Do not share/import history across sessions live
setopt hist_fcntl_lock         # Lock history file during writes to avoid interleaving
