#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Create necessary directories
mkdir -p /etc/temp-ssh-access
mkdir -p /usr/local/lib/temp-ssh-access
mkdir -p /usr/local/bin

# Install server-side scripts
cp server/config/temp_ssh.conf /etc/temp-ssh-access/
cp server/lib/user_management.sh /usr/local/lib/temp-ssh-access/
cp server/lib/token_generator.sh /usr/local/lib/temp-ssh-access/
cp server/bin/temp-ssh-access /usr/local/bin/

# Install client-side script
cp client/temp_ssh_client.py /usr/local/bin/temp-ssh-access-client

# Set correct permissions
chmod +x /usr/local/bin/temp-ssh-access
chmod +x /usr/local/bin/temp-ssh-access-client
chmod +x /usr/local/lib/temp-ssh-access/*.sh

# Install dependencies
apt-get update
apt-get install -y \
    openssl \
    jq \
    python3-pip \
    python3-paramiko

# Install Python dependencies
pip3 install paramiko

echo "Temporary SSH Access system installed successfully!"
