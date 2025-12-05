# modules/_system/node.sh - Node.js runtime (system requirement)

MODULE_NAME="node"
MODULE_DESCRIPTION="Node.js runtime for JavaScript tools"

module_check() { has node && has npm; }

module_install() {
    # Install Node.js LTS via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
}

module_update() {
    sudo apt update && sudo apt upgrade -y nodejs
}

module_config() { :; }
module_aliases() { :; }
module_functions() { :; }
module_env() { :; }
module_paths() { :; }
