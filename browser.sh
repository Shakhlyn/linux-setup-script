#!/bin/bash

# install_brave.sh
# Script to install Brave Browser on Fedora 43

set -e  # Exit immediately if a command fails

echo "Updating system packages..."
sudo dnf update -y

echo "Installing DNF plugins..."
sudo dnf install -y dnf-plugins-core

echo "Adding Brave Browser repository..."
sudo dnf config-manager --add-repo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

echo "Importing Brave GPG key..."
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

echo "Installing Brave Browser..."
sudo dnf install -y brave-browser

echo "Brave Browser installation completed!"
echo "You can launch it with: brave-browser"
