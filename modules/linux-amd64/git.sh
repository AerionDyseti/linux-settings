# modules/git.sh - Git aliases and configuration

MODULE_NAME="git"
MODULE_DESCRIPTION="Git aliases and workflow functions"

# Git is assumed installed (required to clone this repo)
module_check() { has git; }
module_install() { return 0; }  # Git assumed present
module_update() { return 0; }
module_config() { return 0; }

module_aliases() {
    has git || return
    cat <<'EOF'
# Git
alias ga='git add'
alias gcm='git commit'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -n 20'
EOF
}

module_functions() {
    has git || return
    cat <<'EOF'
# Reset branch to origin, stashing local changes
gitclean() {
    local branch="${1:-$(git branch --show-current)}"
    local stash_msg="WIP: $(date +%Y-%m-%d_%H:%M:%S) on $branch"
    
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not in a git repository"
        return 1
    fi
    
    # Stash if there are changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Stashing changes: $stash_msg"
        git stash push -m "$stash_msg"
    fi
    
    # Reset to origin
    if git rev-parse --verify "origin/$branch" &>/dev/null; then
        echo "Resetting $branch to origin/$branch"
        git fetch origin "$branch"
        git reset --hard "origin/$branch"
    else
        echo "No upstream branch origin/$branch found"
        return 1
    fi
}

# Commit with conventional commit prefix
gcom() {
    local type="$1"
    shift
    git commit -m "$type: $*"
}

# Quick amend without editing message
gamend() {
    git add -A && git commit --amend --no-edit
}

# Delete local branches that have been merged
gcleanup() {
    git branch --merged | grep -v '\*\|main\|master' | xargs -r git branch -d
}
EOF
}

module_env() { :; }
module_paths() { :; }
