#!/bin/sh
# One-shot installer for the copy-last-command / copy-last-output feature.
# - Appends OSC 133 prompt markers to ~/.zshrc (via scripts/install-osc133.sh)
# - Appends the tmux keybind block to ~/.tmux.conf
# Idempotent: safe to re-run. Leaves .bak files next to anything it touches.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_CONF="${TMUX_CONF:-$HOME/.tmux.conf}"
MARKER='# >>> copy-last-command >>>'
END_MARKER='# <<< copy-last-command <<<'

# 1. zsh half: OSC 133 prompt markers
sh "$REPO_DIR/scripts/install-osc133.sh"

# 2. tmux half: append the keybind block, fenced with markers for easy removal
if [ -f "$TMUX_CONF" ] && grep -qF "$MARKER" "$TMUX_CONF"; then
    echo "tmux binds already present in $TMUX_CONF — nothing to do"
else
    if [ -f "$TMUX_CONF" ]; then
        cp -p "$TMUX_CONF" "$TMUX_CONF.bak"
        echo "backup: $TMUX_CONF.bak"
        [ -z "$(tail -c1 "$TMUX_CONF")" ] || printf '\n' >>"$TMUX_CONF"
    fi
    {
        printf '\n%s\n' "$MARKER"
        cat "$REPO_DIR/tmux.conf"
        printf '%s\n' "$END_MARKER"
    } >>"$TMUX_CONF"
    echo "appended tmux binds to $TMUX_CONF"
fi

echo
echo "Reload tmux: tmux source-file $TMUX_CONF   (or detach/attach)"
echo "Reload zsh:  exec zsh"
echo
echo "Test: run 'echo hello', press prefix+y, paste — clipboard should be 'echo hello' + 'hello'."
