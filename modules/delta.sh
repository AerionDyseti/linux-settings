# modules/delta.sh - Git diff pager

MODULE_NAME="delta"
MODULE_MODE="dev"

module_install() {
    has delta && { info "delta already installed"; return 0; }
    prompt "Install delta (git diff pager)?" || return 0
    local version
    version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/latest/download/git-delta_${version}_amd64.deb"
    sudo dpkg -i /tmp/delta.deb
    rm -f /tmp/delta.deb
    INSTALLED+=("delta")
}

module_aliases() { :; }
module_functions() { :; }

module_env() {
    has delta || return
    cat <<'EOF'
export DELTA_PAGER="less -R"
EOF
}

module_paths() { :; }
