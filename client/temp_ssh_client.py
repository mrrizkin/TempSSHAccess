#!/usr/bin/env python3

import base64
import json
import os
import subprocess
import sys
import select
from datetime import datetime

import paramiko

class TemporarySSHAccessError(Exception):
    """Custom exception for SSH access-related errors."""
    pass

class TempSSHAccessClient:
    """A secure, temporary SSH access client."""

    def __init__(self, encrypted_token: str, decrypt_key: str):
        """
        Initialize the SSH access client.

        Args:
            encrypted_token (str): Base64 encrypted token
            decrypt_key (str): Decryption key
        """
        self.encrypted_token = encrypted_token
        self.decrypt_key = decrypt_key
        self.access_details = None

    def decrypt_token(self) -> dict:
        """
        Decrypt the access token using OpenSSL.

        Returns:
            dict: Decrypted access details
        """
        try:
            decryption_command = [
                'openssl', 'enc', '-d', '-base64',
                '-aes-256-cbc', '-k', self.decrypt_key,
                '-pbkdf2', '-iter', '10000'
            ]

            process = subprocess.run(
                decryption_command,
                input=self.encrypted_token.encode(),
                capture_output=True,
                text=True,
                check=True
            )

            self.access_details = json.loads(process.stdout.strip())
            return self.access_details
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            raise TemporarySSHAccessError(f"Token decryption failed: {e}")

    def validate_access(self):
        """
        Validate the access token's expiration.

        Raises:
            TemporarySSHAccessError: If token has expired
        """
        expires = datetime.strptime(
            self.access_details['expires'],
            "%Y-%m-%d %H:%M:%S"
        )
        if datetime.now() > expires:
            raise TemporarySSHAccessError("Access token has expired.")

    def connect_ssh(self):
        """
        Establish an interactive SSH connection.

        Raises:
            TemporarySSHAccessError: If SSH connection fails
        """
        try:
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            client.connect(
                hostname=self.access_details['host'],
                port=int(self.access_details['port']),
                username=self.access_details['username'],
                password=self.access_details['password']
            )

            channel = client.invoke_shell()
            self._interactive_shell(channel)
            client.close()
        except Exception as e:
            raise TemporarySSHAccessError(f"SSH Connection Error: {e}")

    def _interactive_shell(self, channel):
        """
        Handle interactive SSH shell session.

        Args:
            channel (paramiko.Channel): SSH channel
        """
        while True:
            r, _, _ = select.select([channel, sys.stdin], [], [], 0.1)

            if channel in r:
                output = channel.recv(1024).decode('utf-8')
                if output:
                    sys.stdout.write(output)
                    sys.stdout.flush()

            if sys.stdin in r:
                x = sys.stdin.read(1)
                if x:
                    channel.send(x)

def main():
    if len(sys.argv) != 3:
        print("Usage: temp-ssh-access-client <encrypted_token> <decrypt_key>")
        sys.exit(1)

    try:
        ssh_access = TempSSHAccessClient(sys.argv[1], sys.argv[2])
        ssh_access.decrypt_token()
        ssh_access.validate_access()
        ssh_access.connect_ssh()
    except TemporarySSHAccessError as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()