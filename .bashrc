# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Environment Variables
if [ -f ~/.env ]; then
    . ~/.env
fi

# Bash Functions
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi