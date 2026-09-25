#!/bin/bash

# Make it executable: Give the script execution permissions by running:
chmod +x setup_dev_redhat.sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Development Environment Setup for Red Hat / Fedora / RHEL ==="

# 1. Update system packages
echo "Updating system packages..."
sudo dnf upgrade -y

# 2. Install basic utilities and Git
echo "Installing Git and basic tools..."
sudo dnf install -y git curl wget

# 3. Install Node.js (using the official Fedora/RHEL AppStream repository)
echo "Installing Node.js and npm..."
sudo dnf install -y nodejs

# 4. Install Java 21 (OpenJDK)
echo "Installing Java 21 OpenJDK..."
sudo dnf install -y java-21-openjdk-devel

# 5. Setup Visual Studio Code Repository and Install
echo "Adding Microsoft repository for Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

echo "Installing Visual Studio Code..."
sudo dnf check-update
sudo dnf install -y code

# 6. Setup Docker and Install
echo "Remove pre-install container to prevent conflicts..."
# Red Hat-based systems often include pre-installed container tools like Podman or older Docker remnants. Remove them to prevent conflicts
sudo dnf remove -y podman runc docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

echo "Adding the Official Docker Repository..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

echo "Installing Docker Engine..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Start and Enable the Docker Service..."
sudo systemctl --now enable docker

echo "Add your user to the Docker group"
sudo usermod -aG docker $USER

echo "Activate the group changes"
newgrp docker

# 7. Verification
echo "=== Installation Completed Successfully! Verifying versions ==="
echo "Git version:" && git --version
echo "Node version:" && node -v
echo "NPM version:" && npm -v
echo "Java version:" && java -version
echo "VS Code status: Installed"
echo "Docker version:" && docker --version

echo "All tools have been installed successfully!"
