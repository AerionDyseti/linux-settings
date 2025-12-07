# modules/vscode.sh - Visual Studio Code

MODULE_NAME="vscode"
MODULE_DESCRIPTION="Visual Studio Code editor integration"

# Helper to detect WSL
is_wsl() {
    grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

module_check() {
    if is_wsl; then
        # On WSL, check if Windows VSCode is accessible
        [ -x "/mnt/c/Program Files/Microsoft VS Code/bin/code" ]
    else
        has code
    fi
}

module_install() {
    if is_wsl; then
        # On WSL, VSCode should be installed on Windows side
        if [ ! -x "/mnt/c/Program Files/Microsoft VS Code/bin/code" ]; then
            warn "VSCode not found on Windows. Install VSCode on Windows first."
            warn "Download from: https://code.visualstudio.com/"
            return 1
        fi
        info "VSCode detected on Windows host"
    else
        # On native Linux, install via apt
        sudo apt update
        sudo apt install -y wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        sudo apt update
        sudo apt install -y code
    fi
}

module_update() {
    if is_wsl; then
        info "VSCode updates managed by Windows"
    else
        sudo apt update && sudo apt upgrade -y code
    fi
}

module_uninstall() {
    if is_wsl; then
        info "VSCode is installed on Windows - uninstall from Windows"
    else
        sudo apt remove -y code
    fi
}

module_config() { return 0; }
module_aliases() { :; }
module_functions() { :; }

module_env() {
    if is_wsl; then
        cat <<'EOF'
# VSCode (Windows) - WSL integration
export PATH="$PATH:/mnt/c/Program Files/Microsoft VS Code/bin"
EOF
    fi
}

module_paths() { :; }
