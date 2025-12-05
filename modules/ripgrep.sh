# modules/ripgrep.sh - Fast grep replacement

MODULE_NAME="ripgrep"
MODULE_MODE="core"

module_install() {
    has rg && { info "ripgrep already installed"; return 0; }
    prompt "Install ripgrep?" || return 0
    sudo apt install -y ripgrep
    INSTALLED+=("ripgrep")
}

module_aliases() {
    has rg || return
    cat <<'EOF'
# Ripgrep
alias rg='rg --smart-case'
alias rgi='rg --no-ignore'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
