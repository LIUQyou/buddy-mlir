#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting setup for CI environment on Ubuntu 22.04..."

# Update and upgrade the system
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install essential build tools and utilities
echo "Installing essential build tools..."
sudo apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

sudo apt-get install -y \
    build-essential \
    clang \
    cmake \
    ninja-build \
    git \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv

# Install Node.js and npm (optional, only if needed)
sudo apt-get install -y nodejs npm

# Install Docker
echo "Installing Docker..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Add current user to Docker group
echo "Configuring Docker permissions..."
sudo usermod -aG docker $USER

# Install development tools
echo "Installing development tools..."
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    git \
    nodejs \
    npm

# Install GitHub Actions runner dependencies
echo "Installing GitHub Actions runner dependencies..."
sudo apt-get install -y \
    libicu-dev \
    libkrb5-dev \
    zlib1g-dev

# Install Nix package manager
echo "Installing Nix package manager..."
curl -L https://nixos.org/nix/install | sh -s -- --daemon
sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
. /home/$USER/.nix-profile/etc/profile.d/nix.sh

# Install pre-commit and related tools
echo "Installing pre-commit and linters..."
pip3 install --user pre-commit black flake8 isort
sudo apt-get install -y clang-format clang-tidy shellcheck

# Optional: Add ~/.local/bin to PATH for pre-commit
echo "Adding ~/.local/bin to PATH..."
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Adjust Docker socket permissions (if necessary)
echo "Setting Docker socket permissions..."
sudo chmod 666 /var/run/docker.sock || true

echo "Setup completed successfully! Please log out and log back in to apply changes."
