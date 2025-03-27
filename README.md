# Temporary SSH Access Management System

## Overview
A secure, temporary SSH access management system with server-side token generation and client-side access.

## Prerequisites
- Bash 4.x+
- Python 3.7+
- OpenSSL
- jq
- paramiko

## Installation
```bash
sudo ./install.sh
```

## Server-Side Usage
### Create Temporary Access
```bash
# Generate token for localhost, port 22, 2-hour access
sudo temp-ssh-access create localhost 22 2
```

### List Temporary Users
```bash
sudo temp-ssh-access list
```

### Remove Temporary User
```bash
sudo temp-ssh-access remove dev_temp_username
```

## Client-Side Usage
```bash
# Connect using generated token
temp-ssh-access-client "<encrypted_token>" "<decrypt_key>"
```

## Security Features
- Temporary user creation
- Time-limited access
- Encrypted access tokens
- Restricted shell access
- Logging of user creation/removal

## Configuration
Edit `/etc/temp-ssh-access/temp_ssh.conf` to customize:
- User prefix
- Maximum temp users
- Default expiry time
- SSH restrictions

## Troubleshooting
- Check `/var/log/temp_ssh_access.log` for access logs
- Ensure OpenSSL and Python dependencies are installed
