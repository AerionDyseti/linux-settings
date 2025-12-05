#!/bin/bash
set -e

# =============================================================================
# kdub.settings - Cross-Platform Shell Environment Setup
# =============================================================================
#
# Usage:
#   ./setup.sh                    Interactive mode (prompt for each module)
#   ./setup.sh --profile=desktop  Non-interactive, install desktop profile
#   ./setup.sh --profile=server   Non-interactive, install server profile
#   ./setup.sh --dry-run          Show what would be installed
#   ./setup.sh --update           Update already-installed tools
#   ./setup.sh --zsh              Use zsh (default)
#   ./setup.sh --bash             Use bash
#
# Platforms: linux-amd64, linux-arm64, darwin (macOS)
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common helpers
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# STATE & CONFIG
# =============================================================================

SELECTED_SHELL=""
INSTALL_ALL=false
PROFILE_NAME=""
UPDATE_MODE=false

# Managed block markers for shell rc files
MARKER_START="# >>> kdub.settings >>>"
MARKER_END="# <<< kdub.settings <<<"

# Module storage (associative arrays require bash 4+)
declare -A MODULE_FILES
declare -A MODULE_DESCRIPTIONS
declare -A MODULE_INSTALLED       # 0=installed, 1=not installed
declare -A MODULE_ALIASES
declare -A MODULE_FUNCTIONS
declare -A MODULE_ENV
declare -A MODULE_PATHS
declare -a MODULE_ORDER           # Preserve load order
declare -a SYSTEM_MODULE_ORDER    # System modules (loaded first)
declare -a NEWLY_INSTALLED        # Track what we installed this run

# Profile modules (loaded from profile file)
declare -a PROFILE_MODULES

# =============================================================================
# MODULE LOADING
# =============================================================================

# Load a single module, storing its metadata and outputs
load_module() {
    local file="$1"
    local is_system="${2:-false}"

    # Source the module to get its definitions
    source "$file"

    # Store file path for later install/update calls
    MODULE_FILES[$MODULE_NAME]="$file"
    MODULE_DESCRIPTIONS[$MODULE_NAME]="${MODULE_DESCRIPTION:-No description}"

    # Track order
    if $is_system; then
        SYSTEM_MODULE_ORDER+=("$MODULE_NAME")
    else
        MODULE_ORDER+=("$MODULE_NAME")
    fi

    # Check if already installed
    if module_check 2>/dev/null; then
        MODULE_INSTALLED[$MODULE_NAME]=0
    else
        MODULE_INSTALLED[$MODULE_NAME]=1
    fi

    # Capture config outputs once (only if installed, for performance)
    if [[ ${MODULE_INSTALLED[$MODULE_NAME]} -eq 0 ]]; then
        MODULE_ALIASES[$MODULE_NAME]="$(module_aliases 2>/dev/null || true)"
        MODULE_FUNCTIONS[$MODULE_NAME]="$(module_functions 2>/dev/null || true)"
        MODULE_ENV[$MODULE_NAME]="$(module_env 2>/dev/null || true)"
        MODULE_PATHS[$MODULE_NAME]="$(module_paths 2>/dev/null || true)"
    fi

    # Unset module functions to prevent conflicts with next module
    unset -f module_check module_install module_update module_config 2>/dev/null || true
    unset -f module_aliases module_functions module_env module_paths 2>/dev/null || true
    unset MODULE_NAME MODULE_DESCRIPTION 2>/dev/null || true
}

# Re-source and run module_install
run_module_install() {
    local name="$1"
    local file="${MODULE_FILES[$name]}"

    if would_do "install $name"; then
        return 0
    fi

    source "$file"
    if module_install; then
        NEWLY_INSTALLED+=("$name")
        MODULE_INSTALLED[$name]=0
        log_install "$name"

        # Now capture config outputs
        MODULE_ALIASES[$name]="$(module_aliases 2>/dev/null || true)"
        MODULE_FUNCTIONS[$name]="$(module_functions 2>/dev/null || true)"
        MODULE_ENV[$name]="$(module_env 2>/dev/null || true)"
        MODULE_PATHS[$name]="$(module_paths 2>/dev/null || true)"
    else
        log_error "Failed to install $name"
        return 1
    fi
}

# Re-source and run module_update
run_module_update() {
    local name="$1"
    local file="${MODULE_FILES[$name]}"

    if would_do "update $name"; then
        return 0
    fi

    source "$file"
    if module_update 2>/dev/null; then
        log_update "$name"
    else
        warn "Update not available for $name"
    fi
}

# Re-source and run module_config
run_module_config() {
    local name="$1"
    local file="${MODULE_FILES[$name]}"

    source "$file"
    module_config 2>/dev/null || true
}

# Load all modules from platform directory
load_all_modules() {
    local platform="$1"
    local module_dir="$SCRIPT_DIR/modules/$platform"

    if [[ ! -d "$module_dir" ]]; then
        error "No modules found for platform: $platform"
        error "Expected directory: $module_dir"
        exit 1
    fi

    # Load system modules first (from _system/ subdirectory)
    if [[ -d "$module_dir/_system" ]]; then
        for module_file in "$module_dir/_system/"*.sh; do
            [[ -f "$module_file" ]] || continue
            debug "Loading system module: $module_file"
            load_module "$module_file" true
        done
    fi

    # Load regular modules
    for module_file in "$module_dir/"*.sh; do
        [[ -f "$module_file" ]] || continue
        debug "Loading module: $module_file"
        load_module "$module_file" false
    done

    info "Loaded ${#SYSTEM_MODULE_ORDER[@]} system modules, ${#MODULE_ORDER[@]} regular modules"
}

# =============================================================================
# PROFILE LOADING
# =============================================================================

load_profile() {
    local profile_name="$1"
    local profile_file="$SCRIPT_DIR/profiles/$profile_name.sh"

    if [[ ! -f "$profile_file" ]]; then
        error "Profile not found: $profile_file"
        exit 1
    fi

    source "$profile_file"
    info "Loaded profile: $PROFILE_NAME - ${PROFILE_DESCRIPTION:-No description}"
}

# Check if module is in current profile
module_in_profile() {
    local name="$1"

    # If no profile, all modules are candidates
    [[ -z "$PROFILE_NAME" ]] && return 0

    for mod in "${PROFILE_MODULES[@]}"; do
        [[ "$mod" == "$name" ]] && return 0
    done
    return 1
}

# =============================================================================
# CONFIG GENERATION
# =============================================================================

generate_aliases() {
    echo "# Aliases - Generated by kdub.settings"
    echo "# Platform: $PLATFORM"
    echo ""

    # Collect from all installed modules
    for name in "${SYSTEM_MODULE_ORDER[@]}" "${MODULE_ORDER[@]}"; do
        [[ ${MODULE_INSTALLED[$name]} -eq 0 ]] || continue
        [[ -n "${MODULE_ALIASES[$name]}" ]] || continue
        echo "# $name"
        echo "${MODULE_ALIASES[$name]}"
        echo ""
    done

    # Shell quick edits
    local ext="$SELECTED_SHELL"
    local rc=".$SELECTED_SHELL"rc
    [[ "$SELECTED_SHELL" == "bash" ]] && rc=".bashrc"

    cat <<EOF
# Shell quick edits
alias shrc='\$EDITOR ~/$rc'
alias shaliases='\$EDITOR ~/.config/$ext/aliases.$ext'
alias shfuncs='\$EDITOR ~/.config/$ext/functions.$ext'
alias shenv='\$EDITOR ~/.config/$ext/env.$ext'
alias reload='source ~/$rc'
EOF
}

generate_functions() {
    echo "# Functions - Generated by kdub.settings"
    echo "# Platform: $PLATFORM"
    echo ""

    for name in "${SYSTEM_MODULE_ORDER[@]}" "${MODULE_ORDER[@]}"; do
        [[ ${MODULE_INSTALLED[$name]} -eq 0 ]] || continue
        [[ -n "${MODULE_FUNCTIONS[$name]}" ]] || continue
        echo "# $name"
        echo "${MODULE_FUNCTIONS[$name]}"
        echo ""
    done
}

generate_env() {
    echo "# Environment - Generated by kdub.settings"
    echo "# Platform: $PLATFORM"
    echo ""

    # Default editor based on platform
    if is_macos; then
        echo "export EDITOR=\${EDITOR:-code}"
        echo "export BROWSER=open"
    else
        echo "export EDITOR=\${EDITOR:-code}"
        echo "export BROWSER=\${BROWSER:-xdg-open}"
    fi
    echo ""

    for name in "${SYSTEM_MODULE_ORDER[@]}" "${MODULE_ORDER[@]}"; do
        [[ ${MODULE_INSTALLED[$name]} -eq 0 ]] || continue
        [[ -n "${MODULE_ENV[$name]}" ]] || continue
        echo "# $name"
        echo "${MODULE_ENV[$name]}"
        echo ""
    done
}

generate_paths() {
    for name in "${SYSTEM_MODULE_ORDER[@]}" "${MODULE_ORDER[@]}"; do
        [[ ${MODULE_INSTALLED[$name]} -eq 0 ]] || continue
        [[ -n "${MODULE_PATHS[$name]}" ]] || continue
        echo "# $name"
        echo "${MODULE_PATHS[$name]}"
        echo ""
    done
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

remove_managed_block() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    if grep -q "$MARKER_START" "$file"; then
        sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$file"
        rm -f "$file.bak"
    fi
}

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

configure_shell() {
    local rc config_dir ext

    if [[ "$SELECTED_SHELL" == "zsh" ]]; then
        rc="$HOME/.zshrc"
        config_dir="$HOME/.config/zsh"
        ext="zsh"
    else
        rc="$HOME/.bashrc"
        config_dir="$HOME/.config/bash"
        ext="bash"
    fi

    mkdir -p "$config_dir"

    # Backup original rc file
    [[ ! -f "$rc.pre-kdub" ]] && [[ -f "$rc" ]] && cp "$rc" "$rc.pre-kdub"

    # Generate and write config files (with prompts if files exist)
    local config_types=("aliases" "functions" "env")

    for type in "${config_types[@]}"; do
        local file="$config_dir/$type.$ext"
        local content
        content=$("generate_$type")

        if [[ -f "$file" ]] && ! $INSTALL_ALL; then
            prompt_config_action "$file"
            case $REPLY in
                1) interactive_merge "$file" "$content" "$type" ;;
                2)
                    echo "$content" > "$file"
                    log_config "replaced" "$file"
                    info "Replaced: $file"
                    ;;
                3)
                    log_config "skipped" "$file"
                    info "Skipped: $file"
                    ;;
            esac
        else
            echo "$content" > "$file"
            log_config "created" "$file"
            info "Created: $file"
        fi
    done

    # Create rc file if missing (zsh only)
    if [[ "$SELECTED_SHELL" == "zsh" ]] && [[ ! -f "$rc" ]]; then
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
    fi

    # Remove old managed block and add new one
    remove_managed_block "$rc"

    local block
    block=$(cat <<EOF
# Source kdub.settings config
[ -f ~/.config/$ext/env.$ext ] && source ~/.config/$ext/env.$ext
[ -f ~/.config/$ext/aliases.$ext ] && source ~/.config/$ext/aliases.$ext
[ -f ~/.config/$ext/functions.$ext ] && source ~/.config/$ext/functions.$ext

EOF
)
    block+="$(generate_paths)"

    append_managed_block "$rc" "$block"
    info "Configured ~/.$ext""rc"
}

# =============================================================================
# SHELL SETUP
# =============================================================================

install_zsh() {
    has zsh && { info "zsh already installed"; return 0; }

    if would_do "install zsh"; then
        return 0
    fi

    info "Installing zsh..."
    if is_macos; then
        brew install zsh
    else
        sudo apt update && sudo apt install -y zsh
    fi
    NEWLY_INSTALLED+=("zsh")
}

set_default_shell() {
    local target
    target=$(which "$SELECTED_SHELL")

    if [[ "$SHELL" != "$target" ]]; then
        if would_do "set $SELECTED_SHELL as default shell"; then
            return 0
        fi
        info "Setting $SELECTED_SHELL as default shell..."
        chsh -s "$target"
    else
        info "$SELECTED_SHELL is already default"
    fi
}

prompt_shell() {
    prompt_choice "Which shell to configure?" "zsh" "bash"
    case $REPLY in
        1) SELECTED_SHELL="zsh" ;;
        2) SELECTED_SHELL="bash" ;;
    esac
}

# =============================================================================
# DRY-RUN OUTPUT
# =============================================================================

show_dry_run() {
    echo ""
    echo -e "${BOLD}=== DRY RUN ===${NC}"
    echo ""
    echo -e "${CYAN}Platform:${NC} $PLATFORM"
    echo -e "${CYAN}Shell:${NC} $SELECTED_SHELL"
    [[ -n "$PROFILE_NAME" ]] && echo -e "${CYAN}Profile:${NC} $PROFILE_NAME"
    echo ""

    # System modules
    echo -e "${BOLD}System modules:${NC}"
    for name in "${SYSTEM_MODULE_ORDER[@]}"; do
        if [[ ${MODULE_INSTALLED[$name]} -eq 0 ]]; then
            echo -e "  ${DIM}[skip]${NC} $name (already installed)"
        else
            echo -e "  ${GREEN}[install]${NC} $name - ${MODULE_DESCRIPTIONS[$name]}"
        fi
    done
    echo ""

    # Regular modules
    echo -e "${BOLD}Modules:${NC}"
    for name in "${MODULE_ORDER[@]}"; do
        if ! module_in_profile "$name"; then
            echo -e "  ${DIM}[skip]${NC} $name (not in profile)"
            continue
        fi

        if [[ ${MODULE_INSTALLED[$name]} -eq 0 ]]; then
            echo -e "  ${DIM}[skip]${NC} $name (already installed)"
        else
            echo -e "  ${GREEN}[install]${NC} $name - ${MODULE_DESCRIPTIONS[$name]}"
        fi
    done
    echo ""

    # Config files
    echo -e "${BOLD}Config files to generate:${NC}"
    local ext="$SELECTED_SHELL"
    echo "  ~/.config/$ext/aliases.$ext"
    echo "  ~/.config/$ext/functions.$ext"
    echo "  ~/.config/$ext/env.$ext"
    echo ""

    # Preview aliases
    echo -e "${BOLD}Aliases preview (first 20 lines):${NC}"
    generate_aliases | head -20
    echo "..."
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Parse flags
    for arg in "$@"; do
        case "$arg" in
            --yes|-y)
                INSTALL_ALL=true
                ;;
            --profile=*)
                PROFILE_NAME="${arg#*=}"
                INSTALL_ALL=true  # Profiles run non-interactively
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --update)
                UPDATE_MODE=true
                ;;
            --zsh)
                SELECTED_SHELL="zsh"
                ;;
            --bash)
                SELECTED_SHELL="bash"
                ;;
            --debug)
                DEBUG=true
                ;;
            --help|-h)
                head -18 "$0" | tail -15
                exit 0
                ;;
            *)
                warn "Unknown option: $arg"
                ;;
        esac
    done

    # Detect platform
    PLATFORM=$(detect_platform_arch)
    info "Platform: $PLATFORM"

    # Initialize logging (unless dry-run)
    $DRY_RUN || init_log

    # Default to zsh for unattended install
    $INSTALL_ALL && [[ -z "$SELECTED_SHELL" ]] && SELECTED_SHELL="zsh"

    # Interactive shell selection
    [[ -z "$SELECTED_SHELL" ]] && prompt_shell
    info "Target shell: $SELECTED_SHELL"

    # Load profile if specified
    [[ -n "$PROFILE_NAME" ]] && load_profile "$PROFILE_NAME"

    # Load all modules for this platform
    load_all_modules "$PLATFORM"

    # Dry-run: show what would happen and exit
    if $DRY_RUN; then
        show_dry_run
        exit 0
    fi

    # Install system modules (always, required)
    echo ""
    info "Installing system modules..."
    for name in "${SYSTEM_MODULE_ORDER[@]}"; do
        if [[ ${MODULE_INSTALLED[$name]} -eq 0 ]]; then
            log_skip "$name"
        else
            run_module_install "$name"
        fi
    done

    # Install or update regular modules
    echo ""
    if $UPDATE_MODE; then
        info "Updating installed modules..."
        for name in "${MODULE_ORDER[@]}"; do
            [[ ${MODULE_INSTALLED[$name]} -eq 0 ]] || continue
            run_module_update "$name"
        done
    else
        info "Installing modules..."
        for name in "${MODULE_ORDER[@]}"; do
            # Check profile filter
            if ! module_in_profile "$name"; then
                debug "Skipping $name (not in profile)"
                continue
            fi

            # Already installed?
            if [[ ${MODULE_INSTALLED[$name]} -eq 0 ]]; then
                log_skip "$name"
                continue
            fi

            # Prompt or auto-install
            if $INSTALL_ALL; then
                run_module_install "$name"
            else
                if prompt "Install $name? (${MODULE_DESCRIPTIONS[$name]})"; then
                    run_module_install "$name"
                fi
            fi
        done
    fi

    # Run module_config for newly installed modules
    for name in "${NEWLY_INSTALLED[@]}"; do
        run_module_config "$name"
    done

    # Install zsh if selected
    if [[ "$SELECTED_SHELL" == "zsh" ]]; then
        if $INSTALL_ALL || prompt "Install zsh?"; then
            install_zsh
        fi
    fi

    # Configure shell
    if $INSTALL_ALL || prompt "Configure $SELECTED_SHELL?"; then
        configure_shell
    fi

    # Set default shell
    if $INSTALL_ALL || prompt "Set $SELECTED_SHELL as default?"; then
        set_default_shell
    fi

    # Summary
    echo ""
    echo -e "${GREEN}${BOLD}Done!${NC}"
    echo -e "Platform: $PLATFORM"
    [[ -n "$PROFILE_NAME" ]] && echo -e "Profile: $PROFILE_NAME"
    if [[ ${#NEWLY_INSTALLED[@]} -gt 0 ]]; then
        echo "Installed: ${NEWLY_INSTALLED[*]}"
    fi
    echo ""
    echo "Restart your shell or run: source ~/.$SELECTED_SHELL""rc"
    echo "Log file: $LOG_FILE"
}

main "$@"
