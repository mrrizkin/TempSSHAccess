#!/bin/bash
# /usr/local/lib/temp-ssh-access/user_management.sh

# Source configuration
source /etc/temp-ssh-access/temp_ssh.conf

# Generate a secure random username
generate_username() {
    local timestamp=$(date +%s)
    local random_suffix=$(openssl rand -hex 4)
    echo "${TEMP_USER_PREFIX}${timestamp}_${random_suffix}"
}

# Generate a strong random password
generate_password() {
    openssl rand -base64 24
}

# Create a temporary user
create_temp_user() {
    local username=$1
    local password=$2
    local expiry_hours=${3:-$DEFAULT_EXPIRY_HOURS}

    # Validate input
    if [[ -z "$username" || -z "$password" ]]; then
        echo "Error: Username and password are required"
        return 1
    }

    # Check maximum temp users
    local current_temp_users=$(get_temp_users | wc -l)
    if [[ $current_temp_users -ge $MAX_TEMP_USERS ]]; then
        echo "Error: Maximum temporary users limit reached"
        return 1
    }

    # Ensure group exists
    sudo groupadd -f "$TEMP_USER_GROUP"

    # Create user with restricted shell
    sudo useradd -m \
        -g "$TEMP_USER_GROUP" \
        -s "$SSH_ALLOWED_SHELL" \
        "$username"

    # Set password
    echo "$username:$password" | sudo chpasswd

    # Set account expiration
    local expiry_date=$(date -d "+$expiry_hours hours" +"%Y-%m-%d %H:%M:%S")
    sudo chage -E "$expiry_date" -M 1 -m 0 -W 1 "$username"

    # Log the creation
    log_temp_user_creation "$username" "$expiry_date"
}

# Log temporary user creation
log_temp_user_creation() {
    local username=$1
    local expiry_date=$2

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created temp user: $username (Expires: $expiry_date)" | \
        sudo tee -a "$LOG_FILE" > /dev/null
}

# List current temporary users
get_temp_users() {
    getent group "$TEMP_USER_GROUP" | cut -d: -f4 | tr ',' '\n'
}

# Remove a temporary user
remove_temp_user() {
    local username=$1

    # Validate username is a temp user
    if [[ "$username" != ${TEMP_USER_PREFIX}* ]]; then
        echo "Error: Not a temporary user"
        return 1
    }

    # Remove user and associated files
    sudo userdel -r "$username"
    sudo rm -f "/etc/sudoers.d/$username"

    # Log removal
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Removed temp user: $username" | \
        sudo tee -a "$LOG_FILE" > /dev/null
}
