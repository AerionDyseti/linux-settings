#!/bin/bash
set -e

# =============================================================================
# kdub.settings - Reset Script
# =============================================================================
#
# Uninstalls non-system modules, removes configs, and cleans shell rc files.
#
# Usage:
#   ./reset.sh                    Interactive mode (confirm each step)
#   ./reset.sh --yes              Non-interactive, do everything
#   ./reset.sh --dry-run          Show what would be removed
#   ./reset.sh --configs-only     Only remove config files, don't uninstall
#   ./reset.sh --restore-backup   Restore original shell rc from backup
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common helpers
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# STATE
# =============================================================================

CONFIRM_ALL=false
CONFIGS_ONLY=false
RESTORE_BACKUP=false

# Managed block markers (must match setup.sh)
MARKER_START="# >>> kdub.settings >>>"
MARKER_END="# <<< kdub.settings <<<"

# Track results
declare -a UNINSTALLED_MODULES
declare -a FAILED_MODULES
declare -a SKIPPED_MODULES

# =============================================================================
# MODULE UNINSTALL
# =============================================================================

# Uninstall a single module
uninstall_module() {
    local file="$1"

    # Source the module
    source "$file"

    local name="$MODULE_NAME"
    local desc="${MODULE_DESCRIPTION:-No description}"

    # Check if installed
    if ! module_check 2>/dev/null; then
        debug "$name: not installed, skipping"
        SKIPPED_MODULES+=("$name")
        unset -f module_check module_install module_update module_config module_uninstall 2>/dev/null || true
        unset -f module_aliases module_functions module_env module_paths 2>/dev/null || true
        unset MODULE_NAME MODULE_DESCRIPTION 2>/dev/null || true
        return 0
    fi

    # Check if module has uninstall function
    if ! declare -f module_uninstall &>/dev/null; then
        warn "$name: no uninstall function, skipping"
        SKIPPED_MODULES+=("$name")
        unset -f module_check module_install module_update module_config 2>/dev/null || true
        unset -f module_aliases module_functions module_env module_paths 2>/dev/null || true
        unset MODULE_NAME MODULE_DESCRIPTION 2>/dev/null || true
        return 0
    fi

    if would_do "uninstall $name"; then
        UNINSTALLED_MODULES+=("$name")
    elif module_uninstall; then
        UNINSTALLED_MODULES+=("$name")
        log_info "Uninstalled: $name"
        info "Uninstalled: $name"
    else
        log_error "Failed to uninstall $name"
        FAILED_MODULES+=("$name")
    fi

    # Clean up
    unset -f module_check module_install module_update module_config module_uninstall 2>/dev/null || true
    unset -f module_aliases module_functions module_env module_paths 2>/dev/null || true
    unset MODULE_NAME MODULE_DESCRIPTION 2>/dev/null || true
}

# =============================================================================
# CONFIG CLEANUP
# =============================================================================

remove_config_files() {
    local shell="$1"
    local config_dir="$HOME/.config/$shell"
    local ext="$shell"

    local files=(
        "$config_dir/aliases.$ext"
        "$config_dir/functions.$ext"
        "$config_dir/env.$ext"
    )

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if would_do "remove $file"; then
                :
            else
                rm -f "$file"
                info "Removed: $file"
            fi
        fi
    done
}

remove_managed_block() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    if grep -q "$MARKER_START" "$file"; then
        if would_do "remove managed block from $file"; then
            return 0
        fi
        sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$file"
        rm -f "$file.bak"
        info "Removed managed block from: $file"
    else
        debug "No managed block in $file"
    fi
}

restore_backup() {
    local shell="$1"
    local rc
    [[ "$shell" == "zsh" ]] && rc="$HOME/.zshrc" || rc="$HOME/.bashrc"
    local backup="$rc.pre-kdub"

    if [[ -f "$backup" ]]; then
        if would_do "restore $backup to $rc"; then
            return 0
        fi
        cp "$backup" "$rc"
        info "Restored: $rc from backup"
    else
        warn "No backup found: $backup"
    fi
}

# =============================================================================
# DRY-RUN OUTPUT
# =============================================================================

show_dry_run() {
    local platform="$1"
    local module_dir="$SCRIPT_DIR/modules/$platform"

    echo ""
    echo -e "${BOLD}=== DRY RUN ===${NC}"
    echo ""
    echo -e "${CYAN}Platform:${NC} $platform"
    echo ""

    # List modules that would be uninstalled
    echo -e "${BOLD}Modules to uninstall:${NC}"
    for module_file in "$module_dir/"*.sh; do
        [[ -f "$module_file" ]] || continue
        source "$module_file"
        local name="$MODULE_NAME"

        if module_check 2>/dev/null; then
            if declare -f module_uninstall &>/dev/null; then
                echo -e "  ${RED}[uninstall]${NC} $name"
            else
                echo -e "  ${YELLOW}[no uninstall]${NC} $name - manual removal needed"
            fi
        else
            echo -e "  ${DIM}[skip]${NC} $name (not installed)"
        fi

        unset -f module_check module_install module_update module_config module_uninstall 2>/dev/null || true
        unset -f module_aliases module_functions module_env module_paths 2>/dev/null || true
        unset MODULE_NAME MODULE_DESCRIPTION 2>/dev/null || true
    done
    echo ""

    # Config files
    echo -e "${BOLD}Config files to remove:${NC}"
    for shell in zsh bash; do
        local config_dir="$HOME/.config/$shell"
        for type in aliases functions env; do
            local file="$config_dir/$type.$shell"
            if [[ -f "$file" ]]; then
                echo -e "  ${RED}[remove]${NC} $file"
            fi
        done
    done
    echo ""

    # Shell rc files
    echo -e "${BOLD}Shell rc modifications:${NC}"
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$rc" ]] && grep -q "$MARKER_START" "$rc"; then
            echo -e "  ${RED}[clean]${NC} $rc - remove managed block"
        fi
    done
    echo ""

    # Backups
    echo -e "${BOLD}Available backups:${NC}"
    for backup in "$HOME/.zshrc.pre-kdub" "$HOME/.bashrc.pre-kdub"; do
        if [[ -f "$backup" ]]; then
            echo -e "  ${GREEN}[available]${NC} $backup"
        fi
    done
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Parse flags
    for arg in "$@"; do
        case "$arg" in
            --yes|-y)
                CONFIRM_ALL=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --configs-only)
                CONFIGS_ONLY=true
                ;;
            --restore-backup)
                RESTORE_BACKUP=true
                ;;
            --debug)
                DEBUG=true
                ;;
            --help|-h)
                head -16 "$0" | tail -13
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

    local module_dir="$SCRIPT_DIR/modules/$PLATFORM"
    if [[ ! -d "$module_dir" ]]; then
        error "No modules found for platform: $PLATFORM"
        exit 1
    fi

    # Initialize logging (unless dry-run)
    $DRY_RUN || init_log

    # Dry-run: show what would happen and exit
    if $DRY_RUN; then
        show_dry_run "$PLATFORM"
        exit 0
    fi

    # Confirm before proceeding
    if ! $CONFIRM_ALL; then
        echo ""
        warn "This will uninstall modules and remove all kdub.settings configurations."
        if ! prompt "Are you sure you want to continue?"; then
            info "Aborted."
            exit 0
        fi
    fi

    # Uninstall modules (unless configs-only)
    if ! $CONFIGS_ONLY; then
        echo ""
        info "Uninstalling modules..."
        for module_file in "$module_dir/"*.sh; do
            [[ -f "$module_file" ]] || continue
            uninstall_module "$module_file"
        done
    fi

    # Remove config files
    echo ""
    info "Removing config files..."
    remove_config_files "zsh"
    remove_config_files "bash"

    # Clean shell rc files
    echo ""
    info "Cleaning shell rc files..."
    remove_managed_block "$HOME/.zshrc"
    remove_managed_block "$HOME/.bashrc"

    # Restore backup if requested
    if $RESTORE_BACKUP; then
        echo ""
        info "Restoring backups..."
        restore_backup "zsh"
        restore_backup "bash"
    fi

    # Summary
    echo ""
    if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}Completed with errors${NC}"
    else
        echo -e "${GREEN}${BOLD}Reset complete!${NC}"
    fi

    if [[ ${#UNINSTALLED_MODULES[@]} -gt 0 ]]; then
        echo -e "${GREEN}Uninstalled:${NC} ${UNINSTALLED_MODULES[*]}"
    fi
    if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
        echo -e "${RED}Failed:${NC} ${FAILED_MODULES[*]}"
    fi
    if [[ ${#SKIPPED_MODULES[@]} -gt 0 ]]; then
        echo -e "${DIM}Skipped:${NC} ${SKIPPED_MODULES[*]}"
    fi

    echo ""
    echo "Restart your shell to apply changes."
    echo "Log file: $LOG_FILE"
}

main "$@"
