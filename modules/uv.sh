# modules/uv.sh - Python package manager

MODULE_NAME="uv"
MODULE_MODE="dev"

module_install() {
    has uv && { info "uv already installed"; return 0; }
    prompt "Install uv?" || return 0
    curl -LsSf https://astral.sh/uv/install.sh | sh
    INSTALLED+=("uv")
}

module_aliases() {
    has uv || return
    cat <<'EOF'
# UV
alias uvr='uv run'
alias uvs='uv sync'
alias uva='uv add'
alias uvad='uv add --dev'
alias uvp='uv pip'
EOF
}

module_functions() { :; }

module_env() {
    cat <<'EOF'
# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
EOF
}

module_paths() {
    [ -f "$HOME/.cargo/env" ] || return
    cat <<'EOF'
# Cargo/UV
. "$HOME/.cargo/env"
EOF
}
