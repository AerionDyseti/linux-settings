# modules/btop.sh - System monitor

MODULE_NAME="btop"
MODULE_DESCRIPTION="Modern system monitor"

module_check() { has btop; }

module_install() {
    sudo apt install -y btop
}

module_update() {
    sudo apt update && sudo apt upgrade -y btop
}

module_config() { return 0; }

module_aliases() {
    has btop || return
    cat <<'EOF'
alias top='btop'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
