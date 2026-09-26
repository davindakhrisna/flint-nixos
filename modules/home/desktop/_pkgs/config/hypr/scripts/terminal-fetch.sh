#!/usr/bin/env zsh
# shellcheck disable=SC1071

# Start an interactive shell immediately when the user types. If the terminal
# remains untouched for five seconds, show fetch before starting the shell.
if [[ ! -t 0 ]]; then
  exec zsh
fi

tty_state=$(stty -g) || exec zsh
restore_tty() {
  stty "$tty_state" 2>/dev/null || true
  printf '\033[?25h\r\033[2K'
}
trap restore_tty EXIT HUP INT TERM

# Make each keypress visible to zselect without consuming it. The queued input
# is preserved for ZLE after exec, so the user's first character is not lost.
stty -icanon -echo min 1 time 0
zmodload zsh/zselect

input_detected=0
for i in 5 4 3 2 1; do
  printf '\r\033[2mfetch in %ds... (type any key to skip)\033[0m' "$i"
  if zselect -r 0 -t 100; then
    input_detected=1
    break
  fi
done

restore_tty
trap - EXIT HUP INT TERM

if [[ $input_detected -eq 0 ]]; then
  fetch || true
fi

exec zsh
