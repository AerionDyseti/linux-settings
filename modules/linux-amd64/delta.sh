# modules/delta.sh - Git diff pager

MODULE_NAME="delta"
MODULE_DESCRIPTION="Syntax-highlighting pager for git diffs"

module_check() { has delta; }

module_install() {
    local version
    version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/latest/download/git-delta_${version}_amd64.deb"
    sudo dpkg -i /tmp/delta.deb
    rm -f /tmp/delta.deb
}

module_update() {
    # Re-run install to get latest version
    module_install
}

module_config() { return 0; }

module_aliases() { :; }
module_functions() { :; }

module_env() {
    has delta || return
    cat <<'EOF'
export DELTA_PAGER="less -R"
EOF
}

module_paths() { :; }
