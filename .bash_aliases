# use exa instead of ls
alias ls='exa -a --icons'
alias ll='exa -lha --icons'
alias la='exa -lbhHigUmuSa@'
alias tree='exa --tree'

# common aliases
alias gitlog='git log --pretty=format:"%h %s" --graph'
alias localtap='env $(cat ./env/local.env) -- tap --no-coverage -R specy'
alias localnode='env $(cat ./env/local.env) -- node --inspect-brk'
alias dockerclear='docker system prune -af && docker image prune -f && docker volume prune -f'

alias dcl='dockerclear'
alias cls='clear'
alias tf='terraform'
alias k='kubectl'
alias lzd='lazydocker'