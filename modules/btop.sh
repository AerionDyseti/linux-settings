# modules/btop.sh - System monitor

MODULE_NAME="btop"
MODULE_MODE="dev"

module_install() {
    has btop && { info "btop already installed"; return 0; }
    prompt "Install btop?" || return 0
    sudo apt install -y btop
    INSTALLED+=("btop")
}

module_aliases() {
    has btop || return
    cat <<'EOF'
alias top='btop'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
