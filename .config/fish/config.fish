# Initialize starship prompt
starship init fish | source

# Source environment variables
if test -f "$HOME/.config/environment.fish"
    source "$HOME/.config/environment.fish"
end

# bun
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path "$BUN_INSTALL/bin"

# bun completions
if test -s "$HOME/.bun/_bun"
    source "$HOME/.bun/_bun"
end

# uv (Python package manager)
fish_add_path "$HOME/.local/bin"
uv generate-shell-completion fish | source

# ============================================
# Aliases
# ============================================

# My personal favorites
alias sc 'systemctl'
alias ssc 'sudo systemctl'
alias cls 'clear'
alias lzd 'lazydocker'
alias d 'docker'

# Use 'eza' to replace 'ls'
alias ls 'eza -a --color=always --group-directories-first --icons --grid'
alias ll 'eza -la --color=always --group-directories-first --icons --octal-permissions --grid'
alias llm 'eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons --grid'
alias lx 'eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons'
alias lt 'eza --tree --level=2 --color=always --group-directories-first --icons'

# AI CLIs
alias c 'claude'
alias cc 'claude --continue'
alias oc 'opencode'
alias occ 'opencode --continue'
