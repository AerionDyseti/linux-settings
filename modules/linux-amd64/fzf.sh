# modules/fzf.sh - Fuzzy finder

MODULE_NAME="fzf"
MODULE_DESCRIPTION="Command-line fuzzy finder"

module_check() { has fzf; }

module_install() {
    sudo apt install -y fzf
}

module_update() {
    sudo apt update && sudo apt upgrade -y fzf
}

module_config() { return 0; }

module_aliases() { :; }

module_functions() {
    has fzf || return
    cat <<'EOF'
# Fuzzy cd into subdirectories
fcd() {
    local dir
    dir=$(fd --type d --hidden --exclude .git 2>/dev/null | fzf --preview 'eza --tree --level=1 {} 2>/dev/null || ls -la {}') && cd "$dir"
}

# Fuzzy open file in editor
fe() {
    local file
    file=$(fzf --preview 'bat --color=always --line-range=:500 {} 2>/dev/null || head -100 {}') && $EDITOR "$file"
}

# Fuzzy git branch checkout
fbr() {
    local branch
    branch=$(git branch --all | grep -v HEAD | sed 's/^..//' | fzf --preview 'git log --oneline -20 {}') || return
    branch=$(echo "$branch" | sed 's#remotes/origin/##')
    git checkout "$branch"
}

# Fuzzy kill process
fkill() {
    local pid
    pid=$(ps aux | fzf --header-lines=1 --preview 'echo {}' | awk '{print $2}')
    [ -n "$pid" ] && kill -9 "$pid" && echo "Killed $pid"
}

# Fuzzy search git log
flog() {
    git log --oneline --color=always | fzf --ansi --preview 'git show --color=always {1}' | awk '{print $1}' | xargs -r git show
}
EOF
}

module_env() {
    has fzf || return
    cat <<'EOF'
# FZF
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
EOF
}

module_paths() {
    has fzf || return
    # Output shell-specific keybindings
    if [ "$SELECTED_SHELL" = "zsh" ]; then
        cat <<'EOF'
# FZF keybindings
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
EOF
    else
        cat <<'EOF'
# FZF keybindings
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/bash-completion/completions/fzf ] && source /usr/share/bash-completion/completions/fzf
EOF
    fi
}
