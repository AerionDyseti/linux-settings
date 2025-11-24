eval "$(starship init zsh)"

# Alias definitions.
if [ -f ~/.sh_aliases ]; then
    . ~/.sh_aliases
fi

# Add custom bash functions and stuff.
if [ -f ~/.sh_functions ]; then
    . ~/.sh_functions
fi


# NVM (Node Version Manager)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# bun completions
[ -s "/home/aerion/.bun/_bun" ] && source "/home/aerion/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
