# modules/bat.sh - Cat with syntax highlighting

MODULE_NAME="bat"
MODULE_DESCRIPTION="Cat clone with syntax highlighting"

module_check() { has bat || has batcat; }

module_install() {
    sudo apt install -y bat
    # Ubuntu names it batcat, symlink to bat
    mkdir -p "$HOME/.local/bin"
    [ ! -L "$HOME/.local/bin/bat" ] && ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
}

module_update() {
    sudo apt update && sudo apt upgrade -y bat
}

module_config() { return 0; }

module_aliases() {
    has bat || return
    cat <<'EOF'
# Bat (cat replacement)
alias cat='bat --paging=never'
alias catp='bat'
EOF
}

module_functions() {
    has bat || return
    cat <<'EOF'
# Man pages with bat
bman() {
    man "$1" | bat --language=man --plain
}
EOF
}

module_env() {
    has bat || return
    cat <<'EOF'
# Bat
export BAT_THEME="Dracula"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
EOF
}

module_paths() { :; }
