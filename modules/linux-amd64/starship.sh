# modules/starship.sh - Cross-shell prompt

MODULE_NAME="starship"
MODULE_DESCRIPTION="Cross-shell customizable prompt"

module_check() { has starship; }

module_install() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

module_update() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}


module_uninstall() {
    sudo rm -f /usr/local/bin/starship
}

module_config() {
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
