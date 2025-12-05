# modules/fd.sh - Fast find replacement

MODULE_NAME="fd"
MODULE_DESCRIPTION="Fast find alternative"

module_check() { has fd || has fdfind; }

module_install() {
    sudo apt install -y fd-find
    # Ubuntu names it fdfind, symlink to fd
    mkdir -p "$HOME/.local/bin"
    [ ! -L "$HOME/.local/bin/fd" ] && ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
}

module_update() {
    sudo apt update && sudo apt upgrade -y fd-find
}

module_config() { return 0; }

module_aliases() {
    has fd || return
    cat <<'EOF'
# fd (find replacement)
alias f='fd'
alias ff='fd --type f'
alias fh='fd --hidden'
EOF
}

module_functions() { :; }

module_env() {
    # Only set FZF_DEFAULT_COMMAND if fzf is also installed
    has fd && has fzf || return
    cat <<'EOF'
# fd as fzf default
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
EOF
}

module_paths() { :; }
