# modules/lazygit.sh - Git TUI

MODULE_NAME="lazygit"
MODULE_DESCRIPTION="Terminal UI for git"

module_check() { has lazygit; }

module_install() {
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
}

module_update() {
    module_install
}

module_config() { return 0; }

module_aliases() {
    has lazygit || return
    cat <<'EOF'
alias lg='lazygit'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
