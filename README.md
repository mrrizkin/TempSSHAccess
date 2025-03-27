# Temporary SSH Access Management System

## Overview

A secure, time-limited SSH access management system providing controlled, temporary remote access with robust security features.

## 🛠 Prerequisites

- Bash 4.x+
- Python 3.7+
- OpenSSL
- jq
- paramiko Python library

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/mrrizkin/TempSSHAccess
cd TempSSHAccess

# Install the system
sudo ./install.sh
```

## 🔐 Server-Side Management

### Create Temporary Access

```bash
# Generate token for a specific host and duration
sudo temp-ssh-access create <hostname> <port> <expiry_hours>

# Example: Generate 2-hour access for localhost
sudo temp-ssh-access create localhost 22 2
```

### User Management

```bash
# List current temporary users
sudo temp-ssh-access list

# Remove a specific temporary user
sudo temp-ssh-access remove <username>
```

## 🌐 Client-Side Connection

```bash
# Connect using generated token
temp-ssh-access-client "<encrypted_token>" "<decrypt_key>"
```

## ✨ Security Features

- 🕒 Time-limited access tokens
- 🔒 Encrypted credential transmission
- 👤 Restricted user shell
- 📝 Comprehensive activity logging
- 🚫 Maximum concurrent temporary users limit

## 🔧 Configuration

Edit `/etc/temp-ssh-access/temp_ssh.conf` to customize:

- Temporary user naming conventions
- Access duration limits
- SSH access restrictions

## 🛡 Security Best Practices

- Regularly rotate access tokens
- Monitor `/var/log/temp_ssh_access.log`
- Restrict token generation to authorized personnel

## 🐛 Troubleshooting

- Verify OpenSSL and Python dependencies
- Check system logs for detailed error information
- Ensure correct permissions on installation directories

## 📄 License

[LICENSE](LICENSE)

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines before submitting a pull request.
