# modules/zoxide.sh - Smarter cd command

MODULE_NAME="zoxide"
MODULE_DESCRIPTION="Smarter cd command that learns"

module_check() { has zoxide; }

module_install() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

module_update() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}


module_uninstall() {
    rm -f "$HOME/.local/bin/zoxide"
}

module_config() { return 0; }

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
