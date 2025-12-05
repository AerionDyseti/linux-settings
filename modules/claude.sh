# modules/claude.sh - Claude Code CLI

MODULE_NAME="claude"
MODULE_MODE="dev"

module_install() {
    has claude && { info "claude already installed"; return 0; }
    prompt "Install Claude CLI?" || return 0
    if has bun; then
        bun install -g @anthropic-ai/claude-code
    elif has npm; then
        npm install -g @anthropic-ai/claude-code
    else
        warn "Node or Bun required for Claude CLI"
        return 1
    fi
    INSTALLED+=("claude")
    
    # Copy settings if config exists
    if [ -f "$SCRIPT_DIR/config/claude.json" ]; then
        mkdir -p "$HOME/.claude"
        cp "$SCRIPT_DIR/config/claude.json" "$HOME/.claude/settings.json"
        info "Copied claude settings.json"
    fi
}

module_aliases() {
    has claude || return
    cat <<'EOF'
# Claude
alias c='claude'
alias cc='claude --continue'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
