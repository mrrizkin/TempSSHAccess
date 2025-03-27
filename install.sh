#!/bin/bash

set -euo pipefail  # Strict error handling

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Validate root permissions
validate_root() {
    if [[ $EUID -ne 0 ]]; then
        log "Error: This script must be run as root" >&2
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    local dirs=(
        "/etc/temp-ssh-access"
        "/usr/local/lib/temp-ssh-access"
        "/usr/local/bin"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log "Created directory: $dir"
    done
}

# Install server-side components
install_server_components() {
    local components=(
        "server/config/temp_ssh.conf:/etc/temp-ssh-access/"
        "server/lib/user_management.sh:/usr/local/lib/temp-ssh-access/"
        "server/lib/token_generator.sh:/usr/local/lib/temp-ssh-access/"
        "server/bin/temp-ssh-access:/usr/local/bin/"
    )

    for component in "${components[@]}"; do
        source="${component%:*}"
        destination="${component#*:}"
        cp "$source" "$destination"
        log "Installed: $source -> $destination"
    done
}

# Install client-side script
install_client_script() {
    cp client/temp_ssh_client.py /usr/local/bin/temp-ssh-access-client
    log "Installed client script: temp-ssh-access-client"
}

# Set correct permissions
set_permissions() {
    local executables=(
        "/usr/local/bin/temp-ssh-access"
        "/usr/local/bin/temp-ssh-access-client"
        "/usr/local/lib/temp-ssh-access/*.sh"
    )

    for executable in "${executables[@]}"; do
        chmod +x "$executable"
        log "Set executable permissions: $executable"
    done
}

# Install dependencies
install_dependencies() {
    apt-get update
    apt-get install -y \
        openssl \
        jq \
        python3-pip \
        python3-paramiko

    pip3 install --no-cache-dir paramiko
    log "Installed system and Python dependencies"
}

# Main installation process
main() {
    validate_root
    create_directories
    install_server_components
    install_client_script
    set_permissions
    install_dependencies

    log "Temporary SSH Access system installation completed successfully!"
}

main "$@"