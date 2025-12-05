# modules/gemini.sh - Gemini CLI

MODULE_NAME="gemini"
MODULE_DESCRIPTION="Google Gemini AI CLI"

module_check() { has gemini; }

module_install() {
    # TODO: Update package name for your gemini CLI
    if has bun; then
        bun install -g @anthropic-ai/gemini-cli
    elif has npm; then
        npm install -g @anthropic-ai/gemini-cli
    else
        warn "Node or Bun required for Gemini CLI"
        return 1
    fi
}

module_update() {
    if has bun; then
        bun update -g @anthropic-ai/gemini-cli
    elif has npm; then
        npm update -g @anthropic-ai/gemini-cli
    fi
}

module_config() {
    if [ -f "$SCRIPT_DIR/config/gemini.json" ]; then
        mkdir -p "$HOME/.gemini"
        cp "$SCRIPT_DIR/config/gemini.json" "$HOME/.gemini/settings.json"
        info "Copied gemini settings.json"
    fi
}
    

module_aliases() {
    has gemini || return
    cat <<'EOF'
# Gemini
alias g='gemini'
alias gc='gemini --continue'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
