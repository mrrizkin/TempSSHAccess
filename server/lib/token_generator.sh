#!/bin/bash
# /usr/local/lib/temp-ssh-access/token_generator.sh

# Source configuration and user management
source /etc/temp-ssh-access/temp_ssh.conf
source /usr/local/lib/temp-ssh-access/user_management.sh

# Generate an access token with server details
generate_access_token() {
    local host=${1:-localhost}
    local port=${2:-22}
    local expiry_hours=${3:-$DEFAULT_EXPIRY_HOURS}

    # Generate unique credentials
    local username=$(generate_username)
    local password=$(generate_password)

    # Create temporary user
    create_temp_user "$username" "$password" "$expiry_hours"

    # Prepare access details as JSON
    local access_details=$(jq -n \
        --arg host "$host" \
        --arg port "$port" \
        --arg username "$username" \
        --arg password "$password" \
        --arg expires "$(date -d "+$expiry_hours hours" +"%Y-%m-%d %H:%M:%S")" \
        '{
            host: $host,
            port: $port,
            username: $username,
            password: $password,
            expires: $expires
        }')

    # Generate encryption key
    local encrypt_key=$(openssl rand -base64 32)

    # Encrypt the access details
    local encrypted_token=$(echo "$access_details" | \
        openssl enc -base64 -aes-256-cbc -k "$encrypt_key" -pbkdf2 -iter "$ENCRYPTION_ITERATIONS")

    # Output token and key
    echo "Encrypted Token: $encrypted_token"
    echo "Decryption Key: $encrypt_key"
}
