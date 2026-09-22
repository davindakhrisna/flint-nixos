#!/usr/bin/env zsh
# shellcheck disable=SC1071

# Start an interactive shell immediately when the user types. If the terminal
# remains untouched for five seconds, show fetch before starting the shell.
if [[ ! -t 0 ]]; then
  exec zsh
fi

tty_state=$(stty -g) || exec zsh
restore_tty() {
  stty "$tty_state"
}
trap restore_tty EXIT HUP INT TERM

# Make each keypress visible to zselect without consuming it. The queued input
# is preserved for ZLE after exec, so the user's first character is not lost.
stty -icanon -echo min 1 time 0
zmodload zsh/zselect

if zselect -r 0 -t 500; then
  restore_tty
  trap - EXIT HUP INT TERM
  exec zsh
fi

restore_tty
trap - EXIT HUP INT TERM
fetch || true
exec zsh
