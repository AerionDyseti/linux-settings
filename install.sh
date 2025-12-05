#!/bin/bash
set -e

# =============================================================================
# Castle.lan Shell Environment Setup
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="# >>> castle.lan >>>"
MARKER_END="# <<< castle.lan <<<"

# State
INSTALLED=()
SELECTED_SHELL=""
INSTALL_ALL=false

# =============================================================================
# HELPERS
# =============================================================================

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
command_exists() { command -v "$1" &>/dev/null; }

prompt() {
    $INSTALL_ALL && return 0
    local question="$1" default="${2:-y}"
    local hint=$([[ "$default" == "y" ]] && echo "[Y/n]" || echo "[y/N]")
    while true; do
        echo -en "${BLUE}${BOLD}?${NC} $question $hint "
        read -r response
        response="${response:-$default}"
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Answer y or n." ;;
        esac
    done
}

prompt_shell() {
    echo -e "${BLUE}${BOLD}?${NC} Which shell to configure?"
    echo "  1) zsh"
    echo "  2) bash"
    while true; do
        echo -en "Choice [1/2]: "
        read -r choice
        case "$choice" in
            1|zsh)  SELECTED_SHELL="zsh"; return ;;
            2|bash) SELECTED_SHELL="bash"; return ;;
            *) echo "Enter 1 or 2." ;;
        esac
    done
}

# Remove existing managed block from a file
remove_managed_block() {
    local file="$1"
    [ -f "$file" ] || return 0
    if grep -q "$MARKER_START" "$file"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$file"
    fi
}

# Append managed block to a file
append_managed_block() {
    local file="$1"
    local content="$2"
    {
        echo ""
        echo "$MARKER_START"
        echo "$content"
        echo "$MARKER_END"
    } >> "$file"
}

# =============================================================================
# INSTALLERS
# =============================================================================

install_zsh() {
    command_exists zsh && { info "zsh already installed"; return 0; }
    info "Installing zsh..."
    sudo apt update && sudo apt install -y zsh
    INSTALLED+=("zsh")
}

install_starship() {
    if command_exists starship; then
        info "starship already installed"
    else
        info "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        INSTALLED+=("starship")
    fi
    
    if [ -f "$SCRIPT_DIR/config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
        info "Copied starship.toml"
    fi
}

install_bun() {
    command_exists bun && { info "bun already installed"; return 0; }
    prompt "Install bun?" || return 0
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    INSTALLED+=("bun")
}

install_uv() {
    command_exists uv && { info "uv already installed"; return 0; }
    prompt "Install uv?" || return 0
    curl -LsSf https://astral.sh/uv/install.sh | sh
    INSTALLED+=("uv")
}

install_docker() {
    command_exists docker && { info "docker already installed"; return 0; }
    prompt "Install Docker?" || return 0
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    INSTALLED+=("docker")
}

install_lazydocker() {
    command_exists lazydocker && { info "lazydocker already installed"; return 0; }
    prompt "Install lazydocker?" || return 0
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    INSTALLED+=("lazydocker")
}

install_eza() {
    command_exists eza && { info "eza already installed"; return 0; }
    prompt "Install eza?" || return 0
    sudo apt update && sudo apt install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install -y eza
    INSTALLED+=("eza")
}

install_fdupes() {
    command_exists fdupes && return 0
    sudo apt install -y fdupes
}

install_claude() {
    command_exists claude && { info "claude already installed"; return 0; }
    prompt "Install Claude CLI?" || return 0
    if command_exists bun; then
        bun install -g @anthropic-ai/claude-code
    elif command_exists npm; then
        npm install -g @anthropic-ai/claude-code
    else
        warn "Node or Bun required for Claude CLI"
        return 1
    fi
    INSTALLED+=("claude")
}

install_tools() {
    install_bun
    install_uv
    install_docker
    install_lazydocker
    install_eza
    install_fdupes
    install_claude
}

# =============================================================================
# CONFIG GENERATION
# =============================================================================

# Filter content by [requires: tool] blocks
# Usage: filter_by_requirements < input_file
filter_by_requirements() {
    local in_block=false
    local tool_available=false
    local current_tool=""
    
    while IFS= read -r line; do
        # Check for block start
        if [[ "$line" =~ ^#[[:space:]]*\[requires:[[:space:]]*([a-zA-Z0-9_-]+)\] ]]; then
            in_block=true
            current_tool="${BASH_REMATCH[1]}"
            if command_exists "$current_tool"; then
                tool_available=true
                echo "$line"  # Keep the marker as documentation
            else
                tool_available=false
            fi
            continue
        fi
        
        # Check for block end
        if [[ "$line" =~ ^#[[:space:]]*\[end\] ]]; then
            if $tool_available; then
                echo "$line"
            fi
            in_block=false
            tool_available=false
            current_tool=""
            continue
        fi
        
        # Handle content
        if $in_block; then
            $tool_available && echo "$line"
        else
            echo "$line"
        fi
    done
}

# Generate the aliases content
generate_aliases() {
    if [ -f "$SCRIPT_DIR/config/aliases" ]; then
        filter_by_requirements < "$SCRIPT_DIR/config/aliases"
    fi
}

# Generate the functions content
generate_functions() {
    if [ -f "$SCRIPT_DIR/config/functions" ]; then
        filter_by_requirements < "$SCRIPT_DIR/config/functions"
    fi
}

# Generate user environment variables
generate_env_file() {
    if [ -f "$SCRIPT_DIR/config/env" ]; then
        filter_by_requirements < "$SCRIPT_DIR/config/env"
    fi
}

# Generate PATH/tool initialization (separate from user env)
generate_paths() {
    local content=""
    
    # Bun
    if [ -d "$HOME/.bun" ]; then
        content+='# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
'
    fi

    # Cargo/UV
    if [ -f "$HOME/.cargo/env" ]; then
        content+='
# Cargo/UV
. "$HOME/.cargo/env"
'
    fi

    # Starship
    if command_exists starship; then
        content+="
# Starship
eval \"\$(starship init $SELECTED_SHELL)\"
"
    fi

    echo "$content"
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

configure_bash() {
    local rc="$HOME/.bashrc"
    local config_dir="$HOME/.config/bash"
    
    mkdir -p "$config_dir"
    
    # Backup original if no backup exists
    [ ! -f "$rc.pre-castle" ] && [ -f "$rc" ] && cp "$rc" "$rc.pre-castle"
    
    # Write config files
    generate_aliases > "$config_dir/aliases.bash"
    generate_functions > "$config_dir/functions.bash"
    generate_env_file > "$config_dir/env.bash"
    info "Generated $config_dir/{aliases,functions,env}.bash"
    
    # Remove old managed block
    remove_managed_block "$rc"
    
    # Build managed block
    local block
    block=$(cat <<'EOF'
# Source castle.lan config
[ -f ~/.config/bash/env.bash ] && source ~/.config/bash/env.bash
[ -f ~/.config/bash/aliases.bash ] && source ~/.config/bash/aliases.bash
[ -f ~/.config/bash/functions.bash ] && source ~/.config/bash/functions.bash

EOF
)
    block+="$(generate_paths)"
    
    append_managed_block "$rc" "$block"
    info "Configured ~/.bashrc"
}

configure_zsh() {
    local rc="$HOME/.zshrc"
    local config_dir="$HOME/.config/zsh"
    
    mkdir -p "$config_dir"
    
    # Write config files
    generate_aliases > "$config_dir/aliases.zsh"
    generate_functions > "$config_dir/functions.zsh"
    generate_env_file > "$config_dir/env.zsh"
    info "Generated $config_dir/{aliases,functions,env}.zsh"
    
    # Create .zshrc if missing
    if [ ! -f "$rc" ]; then
        cat <<'EOF' > "$rc"
# Zsh Configuration

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS

# Completion
autoload -Uz compinit && compinit
EOF
        info "Created new ~/.zshrc"
    else
        [ ! -f "$rc.pre-castle" ] && cp "$rc" "$rc.pre-castle"
    fi
    
    # Remove old managed block
    remove_managed_block "$rc"
    
    # Build managed block
    local block
    block=$(cat <<'EOF'
# Source castle.lan config
[ -f ~/.config/zsh/env.zsh ] && source ~/.config/zsh/env.zsh
[ -f ~/.config/zsh/aliases.zsh ] && source ~/.config/zsh/aliases.zsh
[ -f ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh

EOF
)
    block+="$(generate_paths)"
    
    append_managed_block "$rc" "$block"
    info "Configured ~/.zshrc"
}

configure_shell() {
    case "$SELECTED_SHELL" in
        bash) configure_bash ;;
        zsh)  configure_zsh ;;
    esac
}

set_default_shell() {
    local target
    target=$(which "$SELECTED_SHELL")
    if [ "$SHELL" != "$target" ]; then
        info "Setting $SELECTED_SHELL as default shell..."
        chsh -s "$target"
        INSTALLED+=("default-shell:$SELECTED_SHELL")
    else
        info "$SELECTED_SHELL is already default"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Parse flags
    for arg in "$@"; do
        case "$arg" in
            --yes|-y) INSTALL_ALL=true ;;
            --zsh)    SELECTED_SHELL="zsh" ;;
            --bash)   SELECTED_SHELL="bash" ;;
        esac
    done

    # Default to zsh for unattended install
    $INSTALL_ALL && [ -z "$SELECTED_SHELL" ] && SELECTED_SHELL="zsh"
    
    # Interactive shell selection
    [ -z "$SELECTED_SHELL" ] && prompt_shell
    info "Target shell: $SELECTED_SHELL"

    # Install zsh if selected
    [[ "$SELECTED_SHELL" == "zsh" ]] && prompt "Install zsh?" && install_zsh

    # Starship
    prompt "Install Starship?" && install_starship

    # Tools
    install_tools

    # Configure
    prompt "Configure $SELECTED_SHELL?" && configure_shell

    # Set default
    prompt "Set $SELECTED_SHELL as default?" && set_default_shell

    # Summary
    echo ""
    echo -e "${GREEN}${BOLD}Done!${NC}"
    if [ ${#INSTALLED[@]} -gt 0 ]; then
        echo "Installed/configured: ${INSTALLED[*]}"
    fi
    echo "Restart your shell or run: source ~/.$SELECTED_SHELL""rc"
}

main "$@"
