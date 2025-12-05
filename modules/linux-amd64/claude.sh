# modules/claude.sh - Claude Code CLI

MODULE_NAME="claude"
MODULE_DESCRIPTION="Claude Code AI assistant CLI"

module_check() { has claude; }

module_install() {
    if has bun; then
        bun install -g @anthropic-ai/claude-code
    elif has npm; then
        npm install -g @anthropic-ai/claude-code
    else
        warn "Node or Bun required for Claude CLI"
        return 1
    fi
}

module_update() {
    if has bun; then
        bun update -g @anthropic-ai/claude-code
    elif has npm; then
        npm update -g @anthropic-ai/claude-code
    fi
}

module_config() {
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
