# use exa instead of ls
alias ls='exa -a --icons'
alias ll='exa -lha --icons'
alias la='exa -lbhHigUmuSa@'
alias tree='exa --tree'

# common aliases
alias gitlog='git log --pretty=format:"%h %s" --graph'
alias nodeinspect='node --inspect-brk'
alias nodei='node --inspect-brk'
alias dockerclear='docker system prune -af && docker image prune -f && docker volume prune -f'
alias cls='clear'
alias tf='terraform'
alias lzd='lazydocker'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias k='kubectl'
alias kc='kubectl config current-context'