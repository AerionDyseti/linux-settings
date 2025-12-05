# lib/common.sh - Shared helpers

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if command exists
has() { command -v "$1" &>/dev/null; }

# Prompt with default (respects INSTALL_ALL)
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
