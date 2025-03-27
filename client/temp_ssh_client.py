#!/usr/bin/env python3

import base64
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime
import paramiko
import getpass

class TempSSHAccess:
    def __init__(self, encrypted_token, decrypt_key):
        self.encrypted_token = encrypted_token
        self.decrypt_key = decrypt_key
        self.access_details = None

    def decrypt_token(self):
        try:
            # Decrypt the token using OpenSSL
            decryption_command = [
                'openssl', 'enc', '-d', '-base64',
                '-aes-256-cbc', '-k', self.decrypt_key,
                '-pbkdf2', '-iter', '10000'
            ]

            # Use subprocess to handle decryption
            process = subprocess.Popen(
                decryption_command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Send encrypted token and get decrypted output
            stdout, stderr = process.communicate(input=self.encrypted_token)

            # Check for errors
            if process.returncode != 0:
                raise ValueError(f"Decryption failed: {stderr}")

            # Parse decrypted JSON
            self.access_details = json.loads(stdout.strip())
            return self.access_details
        except Exception as e:
            print(f"Error decrypting token: {e}")
            sys.exit(1)

    def validate_access(self):
        # Check if token has expired
        expires = datetime.strptime(
            self.access_details['expires'],
            "%Y-%m-%d %H:%M:%S"
        )
        if datetime.now() > expires:
            print("Error: Access token has expired.")
            sys.exit(1)

    def connect_ssh(self):
        try:
            # Create SSH client
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            # Connect using decrypted credentials
            client.connect(
                hostname=self.access_details['host'],
                port=int(self.access_details['port']),
                username=self.access_details['username'],
                password=self.access_details['password']
            )

            # Start interactive shell
            channel = client.invoke_shell()

            # Use paramiko's interactive session
            self._interactive_shell(channel)

            client.close()
        except Exception as e:
            print(f"SSH Connection Error: {e}")
            sys.exit(1)

    def _interactive_shell(self, channel):
        # Set up an interactive SSH session
        import select

        while True:
            # Wait for data from server or user input
            r, w, e = select.select([channel, sys.stdin], [], [])

            if channel in r:
                # Receive data from server
                output = channel.recv(1024).decode('utf-8')
                if output:
                    sys.stdout.write(output)
                    sys.stdout.flush()

            if sys.stdin in r:
                # Send user input to server
                x = sys.stdin.read(1)
                if len(x) > 0:
                    channel.send(x)

def main():
    # Check for correct number of arguments
    if len(sys.argv) != 3:
        print("Usage: temp-ssh-access <encrypted_token> <decrypt_key>")
        sys.exit(1)

    # Get token and key from command line
    encrypted_token = sys.argv[1]
    decrypt_key = sys.argv[2]

    # Create TempSSHAccess instance
    ssh_access = TempSSHAccess(encrypted_token, decrypt_key)

    # Decrypt and validate token
    access_details = ssh_access.decrypt_token()
    ssh_access.validate_access()

    # Establish SSH connection
    ssh_access.connect_ssh()

if __name__ == "__main__":
    main()
