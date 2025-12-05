# modules/opencode.sh - OpenCode CLI

MODULE_NAME="opencode"
MODULE_MODE="dev"

module_install() {
    has opencode && { info "opencode already installed"; return 0; }
    prompt "Install OpenCode CLI?" || return 0
    
    # TODO: Update install command for opencode
    if has npm; then
        npm install -g opencode
    elif has bun; then
        bun install -g opencode
    else
        warn "Node or Bun required for OpenCode CLI"
        return 1
    fi
    INSTALLED+=("opencode")
}

module_aliases() {
    has opencode || return
    cat <<'EOF'
# OpenCode
alias oc='opencode'
alias occ='opencode --continue'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
