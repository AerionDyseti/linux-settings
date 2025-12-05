# modules/bat.sh - Cat with syntax highlighting

MODULE_NAME="bat"
MODULE_MODE="core"

module_install() {
    has bat && { info "bat already installed"; return 0; }
    prompt "Install bat?" || return 0
    sudo apt install -y bat
    # Ubuntu names it batcat, symlink to bat
    mkdir -p "$HOME/.local/bin"
    [ ! -L "$HOME/.local/bin/bat" ] && ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    INSTALLED+=("bat")
}

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
