# modules/lazydocker.sh - Docker TUI

MODULE_NAME="lazydocker"
MODULE_MODE="dev"

module_install() {
    has lazydocker && { info "lazydocker already installed"; return 0; }
    prompt "Install lazydocker?" || return 0
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    INSTALLED+=("lazydocker")
}

module_aliases() {
    has lazydocker || return
    cat <<'EOF'
alias lzd='lazydocker'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
