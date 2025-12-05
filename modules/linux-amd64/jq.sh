# modules/jq.sh - JSON processor

MODULE_NAME="jq"
MODULE_DESCRIPTION="Command-line JSON processor"

module_check() { has jq; }

module_install() {
    sudo apt install -y jq
}

module_update() {
    sudo apt update && sudo apt upgrade -y jq
}


module_uninstall() {
    sudo apt remove -y jq
}

module_config() { return 0; }

module_aliases() { :; }

module_functions() {
    has jq || return
    cat <<'EOF'
# Pretty print JSON from argument or stdin
jqp() {
    if [ -n "$1" ]; then
        echo "$1" | jq .
    else
        jq .
    fi
}

# Curl and pretty print JSON
jcurl() {
    curl -s "$@" | jq .
}
EOF
}

module_env() { :; }
module_paths() { :; }
