# modules/zoxide.sh - Smarter cd command

MODULE_NAME="zoxide"
MODULE_MODE="dev"

module_install() {
    has zoxide && { info "zoxide already installed"; return 0; }
    prompt "Install zoxide?" || return 0
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    INSTALLED+=("zoxide")
}

module_aliases() {
    has zoxide || return
    cat <<'EOF'
# Zoxide (after init, 'z' is available)
alias cd='z'
alias cdi='zi'
EOF
}

module_functions() { :; }
module_env() { :; }

module_paths() {
    has zoxide || return
    echo "# Zoxide"
    echo "eval \"\$(zoxide init $SELECTED_SHELL)\""
}
