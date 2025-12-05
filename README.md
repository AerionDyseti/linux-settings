# Castle.lan

Shell environment setup with a modular architecture.

## Quick Start

```bash
# Interactive PC mode
./setup.sh

# Unattended PC mode
./setup.sh --yes

# Server mode (core tools only, nano editor)
./setup.sh --server

# Use bash instead of zsh
./setup.sh --bash
```

## Modes

| Mode | Tools | Editor | Prompts |
|------|-------|--------|---------|
| `pc` | Core + Dev | `code` | Interactive |
| `server` | Core only | `nano` | None |

## Structure

```
castle.lan/
├── setup.sh          # Entry point
├── lib/
│   └── common.sh     # Shared helpers
├── modules/          # One file per tool
│   ├── base.sh
│   ├── eza.sh
│   ├── docker.sh
│   └── ...
└── config/           # Settings to copy
    ├── claude.json   # → ~/.claude/settings.json
    ├── gemini.json   # → ~/.gemini/settings.json
    └── starship.toml # → ~/.config/starship.toml
```

## Creating a New Module

Copy any existing module and modify:

```bash
# modules/mytool.sh

MODULE_NAME="mytool"
MODULE_MODE="dev"  # or "core"

module_install() {
    has mytool && { info "mytool already installed"; return 0; }
    prompt "Install mytool?" || return 0
    # installation commands here
    INSTALLED+=("mytool")
}

module_aliases() {
    has mytool || return
    cat <<'EOF'
alias mt='mytool'
EOF
}

module_functions() {
    has mytool || return
    cat <<'EOF'
mtfunc() {
    mytool --do-thing "$@"
}
EOF
}

module_env() {
    has mytool || return
    cat <<'EOF'
export MYTOOL_CONFIG="$HOME/.config/mytool"
EOF
}

module_paths() {
    has mytool || return
    cat <<'EOF'
eval "$(mytool init $SELECTED_SHELL)"
EOF
}
```

### Module Functions

| Function | Purpose |
|----------|---------|
| `module_install` | Install the tool |
| `module_aliases` | Output aliases |
| `module_functions` | Output functions |
| `module_env` | Output env vars |
| `module_paths` | Output PATH/init (added to rc) |

### Variables Available

- `$SELECTED_SHELL` - `zsh` or `bash`
- `$MODE` - `pc` or `server`
- `$SCRIPT_DIR` - Path to castle.lan directory
- `has <cmd>` - Check if command exists
- `prompt "question?"` - Ask y/n (respects `--yes`)

## Core vs Dev Modules

| Core (both modes) | Dev (pc only) |
|-------------------|---------------|
| base, eza, ripgrep, fd, bat, jq | git, docker, lazydocker, bun, uv, fzf, zoxide, btop, lazygit, delta, claude, gemini, opencode, starship |

## Config Files

Edit these before running setup:

| File | Copied To |
|------|-----------|
| `config/claude.json` | `~/.claude/settings.json` |
| `config/gemini.json` | `~/.gemini/settings.json` |
| `config/starship.toml` | `~/.config/starship.toml` |
