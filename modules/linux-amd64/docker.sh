# modules/docker.sh - Container runtime

MODULE_NAME="docker"
MODULE_DESCRIPTION="Container runtime and compose"

module_check() { has docker; }

module_install() {
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
}

module_update() {
    sudo apt update && sudo apt upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}


module_uninstall() {
    sudo apt remove -y docker.io docker-compose
    sudo gpasswd -d "$USER" docker 2>/dev/null || true
}

module_config() { return 0; }

module_aliases() {
    has docker || return
    cat <<'EOF'
# Docker
alias d='docker'
alias dps='docker ps'
alias dls='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"'
alias dlsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"'
alias di='docker images'
alias dv='docker volume ls'
alias dn='docker network ls'

# Docker Compose
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'
alias dcb='docker compose build'
alias dce='docker compose exec'
EOF
}

module_functions() {
    has docker || return
    cat <<'EOF'
# Shell into container (sh)
dsh() {
    docker exec -it "$1" /bin/sh
}

# Shell into container (bash)
dbash() {
    docker exec -it "$1" /bin/bash
}

# Tail container logs
dlogs() {
    docker logs -f --tail 100 "$1"
}

# Stop all running containers
dstop() {
    docker stop $(docker ps -q) 2>/dev/null || echo "No running containers"
}

# Clean up stopped containers and dangling images
dclean() {
    docker container prune -f
    docker image prune -f
}

# Full docker cleanup
dnuke() {
    echo "This will remove all stopped containers, unused images, volumes, and networks."
    read -p "Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || return 1
    docker system prune -af --volumes
}
EOF
}

module_env() { :; }
module_paths() { :; }
