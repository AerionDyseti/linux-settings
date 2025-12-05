# modules/lazygit.sh - Git TUI

MODULE_NAME="lazygit"
MODULE_MODE="dev"

module_install() {
    has lazygit && { info "lazygit already installed"; return 0; }
    prompt "Install lazygit?" || return 0
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    INSTALLED+=("lazygit")
}

module_aliases() {
    has lazygit || return
    cat <<'EOF'
alias lg='lazygit'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
