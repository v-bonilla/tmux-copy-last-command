# tmux-copy-last-command

Two tmux keybinds that copy your last shell command (and/or its
output) to the system clipboard, semantically — not via scrollback
regexes. Zero mouse. Portable across zsh themes and across terminals.

- `prefix + y` → last command line **and** its output
- `prefix + Y` → last command's output only

## Why

Your AI agent doesn't use a mouse. If the slow step in your iteration
loop is *you* dragging across a terminal to copy an error into the
chat, you're the bottleneck in your own stack.

The binds locate command / output boundaries via OSC 133 prompt
markers that zsh emits around every command, so they keep working
across theme changes and don't care what glyphs your prompt uses. The
selection is forwarded to the outer terminal via OSC 52
(`load-buffer -w`), which works out of the box with Ghostty, iTerm2,
WezTerm, kitty, recent xterm, and anything else that honors OSC 52 —
no `wl-copy` / `pbcopy` / `xclip` required. Inside alternate-screen
apps (vim, less, man, htop) both binds refuse with a status-line
message instead of scraping unrelated scrollback.

## Requirements

- tmux ≥ 3.5 (needs `previous-prompt`, `next-prompt`, `#{alternate_on}`,
  `load-buffer -w`)
- zsh
- A terminal emulator that honors OSC 52 (most modern ones do)

## Install

One command after cloning:

```sh
./install.sh
```

The installer:

1. Appends an OSC 133 hook block to `~/.zshrc` (via `scripts/install-osc133.sh`).
2. Appends the tmux binds to `~/.tmux.conf`, fenced by
   `# >>> copy-last-command >>>` markers for clean removal.

Both steps are idempotent and leave `.bak` files next to anything they
touch. To activate without opening new shells:

```sh
tmux source-file ~/.tmux.conf
exec zsh
```

### Let an agent install it

Paste this into your Claude Code / Cursor / Aider / Codex session:

```
Clone https://github.com/v-bonilla/tmux-copy-last-command.git and run `./install.sh`. Then instruct to restart the terminal emulator and tmux
```

## Usage

Run a command. Press `prefix + y` (command + output) or
`prefix + Y` (output only). Paste.

## Caveat — multi-line prompts

`next-prompt` lands *past* the next prompt's leading blank rows, so
multi-line prompt themes (oh-my-zsh's `refined`, `steeef`, and similar)
bleed one or two extra prompt rows into the clipboard. If you see
trailing prompt glyphs in your paste, insert a `head -n -<N>` trim
before `load-buffer` in `tmux.conf`:

```
run-shell -b 'tmux save-buffer - | head -n -2 | tmux load-buffer -w -'
```

`-2` matches a two-row prompt like `refined`; pick the trim to match
your prompt height.

## How it works

- zsh emits OSC 133 C from `preexec` and embeds OSC 133 A inside
  `PROMPT` (not `precmd` — ZLE's pre-redraw `\r\e[K` hits tmux's
  `grid_empty_line`, which `memset`s `GRID_LINE_START_PROMPT` back to
  zero and silently wipes any A flag set from `precmd`). Embedding A
  inside `PROMPT` re-emits it after every redraw.
- The bind enters copy-mode, jumps back to the previous prompt / output
  start, selects forward to the next prompt's A marker, backs up one
  row to sit at end-of-last-output-line, copies to the tmux paste
  buffer, then forwards that buffer to your outer terminal via
  `load-buffer -w` → OSC 52 → system clipboard.

## Uninstall

Remove the fenced block between `# >>> copy-last-command >>>` and
`# <<< copy-last-command <<<` from `~/.tmux.conf`, and the
`_osc133_decorate_prompt` block from `~/.zshrc`. `.bak` files from
the installer sit next to the originals.
