# profiles/server.sh - Headless homelab server

PROFILE_NAME="server"
PROFILE_DESCRIPTION="Headless server with essential CLI tools"

PROFILE_MODULES=(
    base
    bat
    eza
    fd
    git
    jq
    ripgrep
)
