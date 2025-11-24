#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track what was installed for summary
INSTALLED=()
SKIPPED=()

# Selected shell (zsh or fish)
SELECTED_SHELL=""

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Prompt user for yes/no with default
# Usage: prompt "Question?" [y/n]
prompt() {
    local question="$1"
    local default="${2:-y}"
    local yn_hint

    if [[ "$default" == "y" ]]; then
        yn_hint="[Y/n]"
    else
        yn_hint="[y/N]"
    fi

    while true; do
        echo -en "${BLUE}${BOLD}?${NC} $question ${yn_hint} "
        read -r response
        response="${response:-$default}"
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Prompt for shell choice
# Usage: prompt_shell
prompt_shell() {
    echo -e "${BLUE}${BOLD}?${NC} Which shell would you like to use?"
    echo "  1) zsh"
    echo "  2) fish"
    while true; do
        echo -en "Enter choice [1/2]: "
        read -r choice
        case "$choice" in
            1|zsh) SELECTED_SHELL="zsh"; return ;;
            2|fish) SELECTED_SHELL="fish"; return ;;
            *) echo "Please enter 1 or 2." ;;
        esac
    done
}

# =============================================================================
# Install zsh
# =============================================================================
install_zsh() {
    if command_exists zsh; then
        info "zsh is already installed"
        return 0
    fi
    info "Installing zsh..."
    sudo apt update
    sudo apt install -y zsh
}

# =============================================================================
# Install fish
# =============================================================================
install_fish() {
    if command_exists fish; then
        info "fish is already installed"
        return 0
    fi
    info "Installing fish..."
    sudo apt update
    sudo apt-add-repository -y ppa:fish-shell/release-3
    sudo apt update
    sudo apt install -y fish
}

# =============================================================================
# Install starship prompt
# =============================================================================
install_starship() {
    if command_exists starship; then
        info "starship is already installed"
    else
        info "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Copy starship config
    info "Copying starship configuration..."
    mkdir -p "$HOME/.config"
    cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
}

# =============================================================================
# Install bun
# =============================================================================
install_bun() {
    if command_exists bun; then
        info "bun is already installed"
        return 0
    fi
    info "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
}

# =============================================================================
# Install uv (Python package manager)
# =============================================================================
install_uv() {
    if command_exists uv; then
        info "uv is already installed"
        return 0
    fi
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

# =============================================================================
# Install Docker
# =============================================================================
install_docker() {
    if command_exists docker; then
        info "docker is already installed"
        return 0
    fi
    info "Installing docker..."
    # Install prerequisites
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to apt sources
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker "$USER"
    warn "You may need to log out and back in for docker group changes to take effect"
}

# =============================================================================
# Install lazydocker
# =============================================================================
install_lazydocker() {
    if command_exists lazydocker; then
        info "lazydocker is already installed"
        return 0
    fi
    info "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

# =============================================================================
# Install eza (modern ls replacement)
# =============================================================================
install_eza() {
    if command_exists eza; then
        info "eza is already installed"
        return 0
    fi
    info "Installing eza..."
    sudo apt update
    sudo apt install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
}

# =============================================================================
# Install GitHub CLI (gh)
# =============================================================================
install_gh() {
    if command_exists gh; then
        info "gh is already installed"
        return 0
    fi
    info "Installing GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
}

# =============================================================================
# Install Claude CLI
# =============================================================================
install_claude() {
    if command_exists claude; then
        info "claude is already installed"
        return 0
    fi
    info "Installing Claude CLI..."
    if command_exists npm; then
        npm install -g @anthropic-ai/claude-code
    elif command_exists bun; then
        bun install -g @anthropic-ai/claude-code
    else
        warn "Neither npm nor bun available. Skipping Claude CLI installation."
        warn "Install it manually: npm install -g @anthropic-ai/claude-code"
        return 1
    fi
}

# =============================================================================
# Install OpenCode CLI
# =============================================================================
install_opencode() {
    if command_exists opencode; then
        info "opencode is already installed"
        return 0
    fi
    info "Installing OpenCode CLI..."
    if command_exists go; then
        go install github.com/opencode-ai/opencode@latest
    else
        warn "Go is not installed. Skipping OpenCode installation."
        warn "Install Go first, then run: go install github.com/opencode-ai/opencode@latest"
        return 1
    fi
}

# =============================================================================
# Copy zsh config files
# =============================================================================
copy_zsh_config() {
    info "Copying zsh configuration..."
    mkdir -p "$HOME/.config/zsh"

    cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    cp "$SCRIPT_DIR/.config/zsh/aliases" "$HOME/.config/zsh/aliases"
    cp "$SCRIPT_DIR/.config/zsh/functions" "$HOME/.config/zsh/functions"

    if [ -f "$SCRIPT_DIR/.config/environment" ]; then
        cp "$SCRIPT_DIR/.config/environment" "$HOME/.config/environment"
    fi

    info "zsh configuration copied"
}

# =============================================================================
# Copy fish config files
# =============================================================================
copy_fish_config() {
    info "Copying fish configuration..."
    mkdir -p "$HOME/.config/fish/functions"

    cp "$SCRIPT_DIR/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
    cp "$SCRIPT_DIR/.config/fish/functions/"*.fish "$HOME/.config/fish/functions/"

    if [ -f "$SCRIPT_DIR/.config/environment.fish" ]; then
        cp "$SCRIPT_DIR/.config/environment.fish" "$HOME/.config/environment.fish"
    fi

    info "fish configuration copied"
}

# =============================================================================
# Copy shell config files (based on selection)
# =============================================================================
copy_shell_config() {
    if [[ "$SELECTED_SHELL" == "fish" ]]; then
        copy_fish_config
    else
        copy_zsh_config
    fi
}

# =============================================================================
# Copy git config
# =============================================================================
copy_git_config() {
    info "Copying git configuration..."
    mkdir -p "$HOME/.config/git"
    cp "$SCRIPT_DIR/.config/git/config" "$HOME/.config/git/config"
    info "Git configuration copied"
}

# =============================================================================
# Copy Claude Code config
# =============================================================================
copy_claude_config() {
    info "Copying Claude Code configuration..."
    mkdir -p "$HOME/.claude/commands"

    if [ ! -f "$HOME/.claude/settings.json" ]; then
        cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
        info "Claude Code settings installed"
    else
        warn "Claude Code settings.json already exists, skipping"
    fi

    cp "$SCRIPT_DIR/.claude/commands/"*.md "$HOME/.claude/commands/"
    info "Claude Code custom commands installed"
}

# =============================================================================
# Set default shell (based on selection)
# =============================================================================
set_default_shell() {
    local target_shell
    if [[ "$SELECTED_SHELL" == "fish" ]]; then
        target_shell="$(which fish)"
    else
        target_shell="$(which zsh)"
    fi

    if [ "$SHELL" = "$target_shell" ]; then
        info "$SELECTED_SHELL is already the default shell"
    else
        info "Setting $SELECTED_SHELL as default shell..."
        chsh -s "$target_shell"
        warn "Please log out and back in for the shell change to take effect"
    fi
}

# =============================================================================
# Print summary
# =============================================================================
print_summary() {
    echo ""
    echo "========================================"
    echo "  Installation Summary"
    echo "========================================"

    if [ -n "$SELECTED_SHELL" ]; then
        echo -e "${BLUE}Shell:${NC} $SELECTED_SHELL"
    fi

    if [ ${#INSTALLED[@]} -gt 0 ]; then
        echo -e "${GREEN}Installed:${NC}"
        for item in "${INSTALLED[@]}"; do
            echo "  ✓ $item"
        done
    fi

    if [ ${#SKIPPED[@]} -gt 0 ]; then
        echo -e "${YELLOW}Skipped:${NC}"
        for item in "${SKIPPED[@]}"; do
            echo "  - $item"
        done
    fi

    echo ""
    if [[ "$SELECTED_SHELL" == "fish" ]]; then
        warn "Please restart your terminal or run 'exec fish' to apply changes"
    else
        warn "Please restart your terminal or run 'exec zsh' to apply changes"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "========================================"
    echo "  Linux Settings Installation Script"
    echo "========================================"
    echo ""
    echo "This script will guide you through installing"
    echo "various tools and configurations."
    echo ""

    # Check for flags
    INSTALL_ALL=false
    for arg in "$@"; do
        case "$arg" in
            --yes|-y) INSTALL_ALL=true ;;
            --zsh) SELECTED_SHELL="zsh" ;;
            --fish) SELECTED_SHELL="fish" ;;
        esac
    done

    if $INSTALL_ALL; then
        info "Running in non-interactive mode (--yes)"
        # Default to zsh if no shell specified in non-interactive mode
        if [ -z "$SELECTED_SHELL" ]; then
            SELECTED_SHELL="zsh"
        fi
        echo ""
    fi

    # ===================
    # Shell Selection
    # ===================
    if [ -z "$SELECTED_SHELL" ]; then
        echo -e "${BOLD}── Shell Selection ──${NC}"
        prompt_shell
        echo ""
    fi
    info "Selected shell: $SELECTED_SHELL"
    echo ""

    # ===================
    # Core Shell Setup
    # ===================
    echo -e "${BOLD}── Core Shell Setup ──${NC}"

    if [[ "$SELECTED_SHELL" == "fish" ]]; then
        if $INSTALL_ALL || prompt "Install fish (shell)?"; then
            install_fish && INSTALLED+=("fish") || SKIPPED+=("fish")
        else
            SKIPPED+=("fish")
        fi
    else
        if $INSTALL_ALL || prompt "Install zsh (shell)?"; then
            install_zsh && INSTALLED+=("zsh") || SKIPPED+=("zsh")
        else
            SKIPPED+=("zsh")
        fi
    fi

    if $INSTALL_ALL || prompt "Install starship (prompt theme)?"; then
        install_starship && INSTALLED+=("starship") || SKIPPED+=("starship")
    else
        SKIPPED+=("starship")
    fi

    echo ""

    # ===================
    # Development Tools
    # ===================
    echo -e "${BOLD}── Development Tools ──${NC}"

    if $INSTALL_ALL || prompt "Install bun (JavaScript runtime)?"; then
        install_bun && INSTALLED+=("bun") || SKIPPED+=("bun")
    else
        SKIPPED+=("bun")
    fi

    if $INSTALL_ALL || prompt "Install uv (Python package manager)?"; then
        install_uv && INSTALLED+=("uv") || SKIPPED+=("uv")
    else
        SKIPPED+=("uv")
    fi

    if $INSTALL_ALL || prompt "Install gh (GitHub CLI)?"; then
        install_gh && INSTALLED+=("gh") || SKIPPED+=("gh")
    else
        SKIPPED+=("gh")
    fi

    echo ""

    # ===================
    # Container Tools
    # ===================
    echo -e "${BOLD}── Container Tools ──${NC}"

    if $INSTALL_ALL || prompt "Install docker (container platform)?"; then
        install_docker && INSTALLED+=("docker") || SKIPPED+=("docker")
    else
        SKIPPED+=("docker")
    fi

    if $INSTALL_ALL || prompt "Install lazydocker (Docker TUI)?"; then
        install_lazydocker && INSTALLED+=("lazydocker") || SKIPPED+=("lazydocker")
    else
        SKIPPED+=("lazydocker")
    fi

    echo ""

    # ===================
    # CLI Utilities
    # ===================
    echo -e "${BOLD}── CLI Utilities ──${NC}"

    if $INSTALL_ALL || prompt "Install eza (modern ls replacement)?"; then
        install_eza && INSTALLED+=("eza") || SKIPPED+=("eza")
    else
        SKIPPED+=("eza")
    fi

    echo ""

    # ===================
    # AI Tools
    # ===================
    echo -e "${BOLD}── AI Tools ──${NC}"

    if $INSTALL_ALL || prompt "Install Claude Code CLI?"; then
        install_claude && INSTALLED+=("claude") || SKIPPED+=("claude")
    else
        SKIPPED+=("claude")
    fi

    if $INSTALL_ALL || prompt "Install OpenCode CLI?" "n"; then
        install_opencode && INSTALLED+=("opencode") || SKIPPED+=("opencode")
    else
        SKIPPED+=("opencode")
    fi

    echo ""

    # ===================
    # Configuration Files
    # ===================
    echo -e "${BOLD}── Configuration Files ──${NC}"

    if $INSTALL_ALL || prompt "Copy $SELECTED_SHELL configuration?"; then
        copy_shell_config && INSTALLED+=("$SELECTED_SHELL config") || SKIPPED+=("$SELECTED_SHELL config")
    else
        SKIPPED+=("$SELECTED_SHELL config")
    fi

    if $INSTALL_ALL || prompt "Copy git configuration?"; then
        copy_git_config && INSTALLED+=("git config") || SKIPPED+=("git config")
    else
        SKIPPED+=("git config")
    fi

    if $INSTALL_ALL || prompt "Copy Claude Code configuration (settings, commands)?"; then
        copy_claude_config && INSTALLED+=("claude config") || SKIPPED+=("claude config")
    else
        SKIPPED+=("claude config")
    fi

    echo ""

    # ===================
    # Final Setup
    # ===================
    echo -e "${BOLD}── Final Setup ──${NC}"

    if $INSTALL_ALL || prompt "Set $SELECTED_SHELL as default shell?"; then
        set_default_shell && INSTALLED+=("$SELECTED_SHELL as default") || SKIPPED+=("$SELECTED_SHELL as default")
    else
        SKIPPED+=("$SELECTED_SHELL as default")
    fi

    # Print summary
    print_summary
}

main "$@"
