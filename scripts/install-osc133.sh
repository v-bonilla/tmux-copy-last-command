#!/bin/sh
# Append OSC 133 semantic prompt markers to ~/.zshrc so tmux's
# previous-prompt / next-prompt (and the `prefix y` / `prefix Y`
# copy-last-command-or-output binds) can locate prompt/output boundaries
# regardless of the active zsh theme.
#
# Idempotent: if the block is already present, does nothing.
# Writes a .bak next to the target file before modifying it.
set -eu

ZSHRC="${1:-$HOME/.zshrc}"
MARKER='_osc133_decorate_prompt'

if [ ! -f "$ZSHRC" ]; then
    echo "error: $ZSHRC does not exist" >&2
    exit 1
fi

if grep -q "$MARKER" "$ZSHRC"; then
    echo "OSC 133 block already present in $ZSHRC — nothing to do"
    exit 0
fi

cp -p "$ZSHRC" "$ZSHRC.bak"
echo "backup: $ZSHRC.bak"

# Ensure the file ends with a newline before appending
[ -z "$(tail -c1 "$ZSHRC")" ] || printf '\n' >>"$ZSHRC"

cat >>"$ZSHRC" <<'EOF'

# OSC 133 semantic prompt markers — let tmux locate prompt/output boundaries
# regardless of the active Oh My Zsh theme. Kept at the end of .zshrc so any
# plugin sourced later that registers its own precmd still runs BEFORE ours.
#
# C (command output start) is emitted from preexec.
#
# A (prompt start) is embedded in PROMPT via %{...%} rather than printed from
# precmd, because ZLE emits \r\e[K before every prompt redraw after the first
# one; that hits tmux's grid_empty_line which memsets GRID_LINE_START_PROMPT
# back to zero, wiping any A flag set from precmd. Emitting A from inside
# PROMPT runs AFTER the clear and lands on a row that won't be re-cleared
# until the next prompt cycle. Re-applied each precmd so themes that rebuild
# PROMPT dynamically (e.g. powerlevel10k) can't lose the marker.
autoload -Uz add-zsh-hook
_osc133_preexec() { printf '\e]133;C\a' }
_osc133_decorate_prompt() {
  [[ "$PS1" == *$'\e]133;A'* ]] && return
  PS1="%{"$'\e]133;A\a'"%}$PS1"
}
add-zsh-hook preexec _osc133_preexec
add-zsh-hook precmd  _osc133_decorate_prompt
EOF

echo "appended OSC 133 block to $ZSHRC"
echo "reload: open a new shell or run: exec zsh"
