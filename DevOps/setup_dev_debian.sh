#!/bin/bash

# 0. Give the script execution permissions then run the script
# 0.1 chmod +x setup_dev_debian.sh
# 0.2 ./setup_dev_debian.sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Development Environment Setup for Debian / Ubuntu ==="

# 1. Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install basic utilities and Git
echo "Installing Git and basic tools..."
sudo apt install -y git curl wget apt-transport-https ca-certificates gnupg lsb-release

# 3. Install Node.js (Latest LTS via NodeSource repository for modern version)
echo "Installing Node.js and npm..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

# 4. Install Java 21 (OpenJDK)
echo "Installing Java 21 OpenJDK..."
sudo apt install -y openjdk-21-jdk

# 5. Setup Visual Studio Code Repository and Install
echo "Adding Microsoft repository for Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /packages.microsoft.gpg
sudo install -D -o root -g root -m 644 /packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f /packages.microsoft.gpg
sudo apt update

echo "Installing Visual Studio Code..."
sudo apt install -y code

# 6. Setup Docker and Install
echo "Removing pre-installed container packages to prevent conflicts..."
sudo apt remove -y podman docker docker-engine docker.io containerd runc || true

echo "Adding the Official Docker Repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Start and Enable the Docker Service..."
sudo systemctl --now enable docker

# Optional: Add current user to the docker group so you don't need sudo for docker
if [ -n "$USER" ]; then
  echo "Adding user $USER to the docker group..."
  sudo usermod -aG docker "$USER"
fi

# 7. Verification
echo "=== Installation Completed Successfully! Verifying versions ==="
echo "Git version:" && git --version
echo "Node version:" && node -v
echo "NPM version:" && npm -v
echo "Java version:" && java -version
echo "VS Code status: Installed"
echo "Docker version:" && docker --version

echo "All tools have been installed successfully! Please log out and back in if you want Docker permissions to apply."