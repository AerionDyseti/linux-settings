# modules/jq.sh - JSON processor

MODULE_NAME="jq"
MODULE_MODE="core"

module_install() {
    has jq && { info "jq already installed"; return 0; }
    prompt "Install jq?" || return 0
    sudo apt install -y jq
    INSTALLED+=("jq")
}

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
