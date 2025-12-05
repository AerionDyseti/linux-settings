# modules/bun.sh - JavaScript runtime and package manager

MODULE_NAME="bun"
MODULE_DESCRIPTION="Fast JavaScript runtime and package manager"

module_check() { has bun; }

module_install() {
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
}

module_update() {
    bun upgrade
}


module_uninstall() {
    rm -rf "$HOME/.bun"
}

module_config() { return 0; }

module_aliases() {
    has bun || return
    cat <<'EOF'
# Bun
alias b='bun'
alias br='bun run'
alias bx='bunx'
alias bi='bun install'
alias ba='bun add'
alias bad='bun add -d'
EOF
}

module_functions() { :; }
module_env() { :; }

module_paths() {
    [ -d "$HOME/.bun" ] || return
    cat <<'EOF'
# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
EOF
}
