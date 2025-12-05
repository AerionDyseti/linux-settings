# modules/eza.sh - Modern ls replacement

MODULE_NAME="eza"
MODULE_MODE="core"

module_install() {
    has eza && { info "eza already installed"; return 0; }
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

module_aliases() {
    has eza || return
    cat <<'EOF'
# Eza (ls replacement)
alias ls='eza -a --color=always --group-directories-first --icons --grid'
alias ll='eza -la --color=always --group-directories-first --icons --octal-permissions --grid'
alias llm='eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons --grid'
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons'
alias lt='eza --tree --level=2 --color=always --group-directories-first --icons'
EOF
}

module_functions() { :; }
module_env() { :; }
module_paths() { :; }
