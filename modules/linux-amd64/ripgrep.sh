# modules/ripgrep.sh - Fast grep replacement

MODULE_NAME="ripgrep"
MODULE_DESCRIPTION="Fast grep alternative"

module_check() { has rg; }

module_install() {
    sudo apt install -y ripgrep
}

module_update() {
    sudo apt update && sudo apt upgrade -y ripgrep
}

module_config() { return 0; }

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
