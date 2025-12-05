# modules/gemini.sh - Gemini CLI

MODULE_NAME="gemini"
MODULE_MODE="dev"

module_install() {
    has gemini && { info "gemini already installed"; return 0; }
    prompt "Install Gemini CLI?" || return 0
    
    # Install via npm - adjust package name as needed
    # TODO: Update package name for your gemini CLI
    if has npm; then
        npm install -g @anthropic-ai/gemini-cli
    elif has bun; then
        bun install -g @anthropic-ai/gemini-cli
    else
        warn "Node or Bun required for Gemini CLI"
        return 1
    fi
    INSTALLED+=("gemini")
    
    # Copy settings if config exists
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
