# modules/base.sh - General aliases and functions (no dependencies)

MODULE_NAME="base"
MODULE_MODE="core"

module_install() { :; }  # Nothing to install

module_aliases() {
    cat <<'EOF'
# General
alias sc='systemctl'
alias ssc='sudo systemctl'
alias cls='clear'

# Safety nets
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Networking
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | awk "{print \$1}"'

# Misc
alias weather='curl wttr.in'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
EOF
}

module_functions() {
    cat <<'EOF'
# Quick directory creation and cd
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.tar.xz)  tar xJf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.7z)      7z x "$1" ;;
            *.rar)     unrar x "$1" ;;
            *)         echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psg() {
    ps aux | grep -v grep | grep -i "$1"
}

# Backup file with timestamp
bak() {
    cp "$1" "$1.$(date +%Y%m%d_%H%M%S).bak"
}

# Create temp directory and cd into it
tmpd() {
    local dir
    dir=$(mktemp -d)
    echo "Created $dir"
    cd "$dir"
}

# Quick scratch/ephemeral note
scratch() {
    local file
    file=$(mktemp --suffix=.md)
    if [ -n "$1" ]; then
        echo "$*" > "$file"
        echo "Wrote to: $file"
    else
        $EDITOR "$file"
    fi
    echo "$file"
}

# Cat the last scratch file
lscratch() {
    local last
    last=$(ls -t /tmp/tmp.*.md 2>/dev/null | head -1)
    if [ -n "$last" ]; then
        cat "$last"
        echo -e "\n---\n$last"
    else
        echo "No scratch files found"
    fi
}

# Check what's on a port
port() {
    ss -tulnp | grep ":$1"
}

# Kill process on a port
killport() {
    local pid
    pid=$(ss -tulnp | grep ":$1" | awk '{print $7}' | grep -oP 'pid=\K[0-9]+' | head -1)
    if [ -n "$pid" ]; then
        kill -9 "$pid" && echo "Killed PID $pid on port $1"
    else
        echo "No process found on port $1"
    fi
}

# Quick serve current directory (python)
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}
EOF
}

module_env() {
    cat <<'EOF'
# Local binaries
export PATH="$HOME/.local/bin:$PATH"
EOF
}

module_paths() { :; }
