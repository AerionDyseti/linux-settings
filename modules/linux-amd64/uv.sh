# modules/uv.sh - Python package manager

MODULE_NAME="uv"
MODULE_DESCRIPTION="Fast Python package manager"

module_check() { has uv; }

module_install() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

module_update() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

module_config() { return 0; }

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
