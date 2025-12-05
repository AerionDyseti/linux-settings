# modules/starship.sh - Cross-shell prompt

MODULE_NAME="starship"
MODULE_MODE="dev"

module_install() {
    has starship && { info "starship already installed"; return 0; }
    prompt "Install Starship?" || return 0
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    INSTALLED+=("starship")
    
    # Copy config if it exists
    if [ -f "$SCRIPT_DIR/config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
        info "Copied starship.toml"
    fi
}

module_aliases() { :; }
module_functions() { :; }
module_env() { :; }

module_paths() {
    has starship || return
    echo "# Starship prompt"
    echo "eval \"\$(starship init $SELECTED_SHELL)\""
}
