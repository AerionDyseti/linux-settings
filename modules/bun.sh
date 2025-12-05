# modules/bun.sh - JavaScript runtime and package manager

MODULE_NAME="bun"
MODULE_MODE="dev"

module_install() {
    has bun && { info "bun already installed"; return 0; }
    prompt "Install bun?" || return 0
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    INSTALLED+=("bun")
}

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
