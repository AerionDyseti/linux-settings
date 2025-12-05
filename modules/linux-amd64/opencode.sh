# modules/opencode.sh - OpenCode CLI

MODULE_NAME="opencode"
MODULE_DESCRIPTION="OpenAI coding assistant CLI"

module_check() { has opencode; }

module_install() {
    # TODO: Update install command for opencode
    if has bun; then
        bun install -g opencode
    elif has npm; then
        npm install -g opencode
    else
        warn "Node or Bun required for OpenCode CLI"
        return 1
    fi
}

module_update() {
    if has bun; then
        bun update -g opencode
    elif has npm; then
        npm update -g opencode
    fi
}


module_uninstall() {
    if has bun; then
        bun remove -g opencode
    elif has npm; then
        npm uninstall -g opencode
    fi
}

module_config() { return 0; }

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
