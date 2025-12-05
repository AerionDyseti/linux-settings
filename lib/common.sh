# lib/common.sh - Shared helpers

# =============================================================================
# COLORS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# =============================================================================
# CONSOLE OUTPUT
# =============================================================================

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { $DEBUG && echo -e "${DIM}[DEBUG] $1${NC}" || true; }

# =============================================================================
# PLATFORM/ARCHITECTURE DETECTION
# =============================================================================

# Detect platform and architecture combination
# Returns: linux-amd64, linux-arm64, or darwin
detect_platform_arch() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$os" in
        darwin)
            echo "darwin"
            ;;
        linux)
            case "$arch" in
                x86_64|amd64)
                    echo "linux-amd64"
                    ;;
                aarch64|arm64)
                    echo "linux-arm64"
                    ;;
                *)
                    error "Unsupported architecture: $arch"
                    exit 1
                    ;;
            esac
            ;;
        *)
            error "Unsupported OS: $os"
            exit 1
            ;;
    esac
}

is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# =============================================================================
# UTILITIES
# =============================================================================

# Check if command exists
has() { command -v "$1" &>/dev/null; }

# Prompt with default (respects INSTALL_ALL for non-interactive mode)
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

# Prompt with numbered choices
# Usage: prompt_choice "Question" "Option1" "Option2" "Option3"
# Returns: 1, 2, or 3 (stored in REPLY)
prompt_choice() {
    local question="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    echo -e "${BLUE}${BOLD}?${NC} $question"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    while true; do
        echo -n "Choice [1-$count]: "
        read -r REPLY
        if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= count )); then
            return 0
        fi
        echo "Please enter a number between 1 and $count"
    done
}

# =============================================================================
# FILE LOGGING
# =============================================================================

LOG_FILE="${LOG_FILE:-$HOME/.config/kdub.settings.log}"
DEBUG="${DEBUG:-false}"

# Initialize log file
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Setup run: $(date -Iseconds) ===" >> "$LOG_FILE"
    echo "Platform: $(detect_platform_arch)" >> "$LOG_FILE"
}

# Write to log file with timestamp
log() {
    local level="$1"
    shift
    echo "[$(date -Iseconds)] [$level] $*" >> "$LOG_FILE"
}

log_install() { log "INSTALL" "$1"; info "Installed: $1"; }
log_skip()    { log "SKIP" "$1 (already installed)"; info "Skipped: $1 (already installed)"; }
log_update()  { log "UPDATE" "$1"; info "Updated: $1"; }
log_config()  { log "CONFIG" "$1: $2"; }
log_error()   { log "ERROR" "$1"; error "$1"; }

# =============================================================================
# CONFIG FILE HANDLING
# =============================================================================

# Prompt for config file action when file exists
# Usage: prompt_config_action "/path/to/file" "$new_content" "type"
# Returns: 1=merge, 2=replace, 3=skip (stored in REPLY)
prompt_config_action() {
    local file="$1"

    echo ""
    echo -e "${CYAN}Config file exists:${NC} $file"
    prompt_choice "How should we handle this file?" \
        "Review and merge new entries interactively" \
        "Replace entirely" \
        "Skip (keep existing)"
}

# Interactive merge for config files
# Parses content into chunks and prompts for each new chunk
interactive_merge() {
    local file="$1"
    local new_content="$2"
    local type="$3"
    local chunks=()
    local current_chunk=""
    local in_function=false
    local brace_count=0
    local added=0
    local skipped=0

    # Parse content into chunks based on type
    case "$type" in
        aliases|env)
            # Each line is a chunk
            while IFS= read -r line; do
                [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]] && chunks+=("$line")
            done <<< "$new_content"
            ;;
        functions)
            # Parse function blocks (funcname() { ... })
            while IFS= read -r line; do
                if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\(\) ]]; then
                    # Start of function
                    in_function=true
                    current_chunk="$line"
                    brace_count=0
                elif $in_function; then
                    current_chunk+=$'\n'"$line"
                    # Count braces
                    brace_count=$((brace_count + $(echo "$line" | tr -cd '{' | wc -c)))
                    brace_count=$((brace_count - $(echo "$line" | tr -cd '}' | wc -c)))
                    if (( brace_count <= 0 )) && [[ "$line" == *"}"* ]]; then
                        chunks+=("$current_chunk")
                        in_function=false
                        current_chunk=""
                    fi
                fi
            done <<< "$new_content"
            ;;
    esac

    # Check each chunk against existing file
    local existing_content
    existing_content=$(cat "$file" 2>/dev/null || echo "")

    for chunk in "${chunks[@]}"; do
        # Get identifier (alias name, function name, or var name)
        local identifier
        case "$type" in
            aliases)
                identifier=$(echo "$chunk" | sed -n "s/^alias \([^=]*\)=.*/\1/p")
                ;;
            functions)
                identifier=$(echo "$chunk" | head -1 | sed -n "s/^\([a-zA-Z_][a-zA-Z0-9_]*\)().*/\1/p")
                ;;
            env)
                identifier=$(echo "$chunk" | sed -n "s/^export \([^=]*\)=.*/\1/p")
                ;;
        esac

        # Skip if already exists
        if [[ -n "$identifier" ]] && grep -q "^alias $identifier=" "$file" 2>/dev/null || \
           grep -q "^$identifier()" "$file" 2>/dev/null || \
           grep -q "^export $identifier=" "$file" 2>/dev/null; then
            continue
        fi

        # Show chunk and ask
        echo ""
        echo -e "${CYAN}New ${type%s}:${NC}"
        echo -e "${DIM}$chunk${NC}"
        echo ""

        while true; do
            echo -n "[a]dd / [s]kip / [q]uit merge? "
            read -r response
            case "$response" in
                a|A)
                    echo "" >> "$file"
                    echo "$chunk" >> "$file"
                    ((added++))
                    break
                    ;;
                s|S)
                    ((skipped++))
                    break
                    ;;
                q|Q)
                    info "Merge stopped. Added $added, skipped $skipped entries."
                    return
                    ;;
                *)
                    echo "Please enter a, s, or q"
                    ;;
            esac
        done
    done

    info "Merge complete. Added $added, skipped $skipped entries."
    log_config "merged" "$file (added: $added, skipped: $skipped)"
}

# =============================================================================
# DRY-RUN SUPPORT
# =============================================================================

DRY_RUN="${DRY_RUN:-false}"

# Print what would happen in dry-run mode
would_do() {
    if $DRY_RUN; then
        echo -e "${DIM}[DRY-RUN] Would: $1${NC}"
        return 0
    fi
    return 1
}
