eval "$(starship init zsh)"

# Source configuration from $HOME/.config
[ -f "$HOME/.config/zsh/aliases" ] && . "$HOME/.config/zsh/aliases"
[ -f "$HOME/.config/zsh/functions" ] && . "$HOME/.config/zsh/functions"
[ -f "$HOME/.config/environment" ] && . "$HOME/.config/environment"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# uv (Python package manager)
export PATH="$HOME/.local/bin:$PATH"
eval "$(uv generate-shell-completion zsh)"
