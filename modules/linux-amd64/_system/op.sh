# modules/_system/op.sh - 1Password CLI (system requirement)

MODULE_NAME="op"
MODULE_DESCRIPTION="1Password CLI for secrets management"

module_check() { has op; }

module_install() {
    # Add 1Password apt repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list

    sudo apt update && sudo apt install -y 1password-cli
}

module_update() {
    sudo apt update && sudo apt upgrade -y 1password-cli
}

module_config() {
    # Check if already signed in
    if ! op account list &>/dev/null; then
        info "1Password CLI installed. Run 'op signin' to authenticate."
    fi
}

module_aliases() { :; }
module_functions() { :; }
module_env() { :; }
module_paths() { :; }
