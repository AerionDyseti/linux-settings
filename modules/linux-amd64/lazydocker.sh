# modules/lazydocker.sh - Docker TUI

MODULE_NAME="lazydocker"
MODULE_DESCRIPTION="Terminal UI for Docker"

module_check() { has lazydocker; }

module_install() {
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

module_update() {
    module_install
}


module_uninstall() {
    sudo apt remove -y docker.io docker-compose
    sudo gpasswd -d "$USER" docker 2>/dev/null || true
}

module_config() { return 0; }

module_aliases() {
    has lazydocker || return
    cat <<'EOF'
alias lzd='lazydocker'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
