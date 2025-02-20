#!/bin/bash
# install-apps.sh
# Installation script for OpenSUSE Tumbleweed: flatpak & flathub apps, system packages from Factory repos, and Packman via opi.
# This script runs in non-interactive mode and skips any part that is already installed or fails.

# Function to echo error messages without stopping the script
error_msg() {
    echo "Error: $1"
}

echo "=== OpenSUSE Tumbleweed Installation Script ==="

# 1. Ensure flatpak is installed (system-wide)
echo "Checking for flatpak..."
if ! command -v flatpak &> /dev/null; then
    echo "flatpak not found. Installing flatpak using zypper..."
    sudo zypper --non-interactive install flatpak || error_msg "Failed to install flatpak"
else
    echo "flatpak is already installed."
fi

# 2. Add Flathub repository (for current user) if not already added
echo "Checking for Flathub remote..."
if flatpak remote-list | grep -qi flathub; then
    echo "Flathub remote already exists."
else
    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || error_msg "Failed to add Flathub repository"
fi

# 3. Install Flatpak applications (for the current user)
declare -A flatpak_apps=(
    [org.kde.kdenlive]="Kdenlive"
    [com.onlyoffice.desktopeditors]="Only Office"
    [org.kde.kigo]="KDE Kigo"
    [org.kde.kcalc]="KCalc"
    [org.blender.Blender]="Blender"
    [org.gimp.GIMP]="GIMP"
    [com.github.pulsar-edit]="Pulsar (Community Text Editor)"
    [com.logseq.Logseq]="Logseq"
    [io.github.shiftey.Desktop]="GitHub Desktop (Unofficial)"
)

for app_id in "${!flatpak_apps[@]}"; do
    echo "Installing ${flatpak_apps[$app_id]} (Flatpak ID: $app_id)..."
    # The install command is run with --user and -y for non-interactive mode.
    flatpak install --user -y flathub "$app_id" || error_msg "Failed to install ${flatpak_apps[$app_id]}"
done

# 4. Check for Factory repository and add it if missing
# (Assuming the Factory repo alias should be "openSUSE-Tumbleweed-Factory". Adjust the URL if needed.)
echo "Checking for Factory repository..."
if zypper lr | grep -qi "Factory"; then
    echo "Factory repository already exists."
else
    echo "Factory repository not found. Adding Factory repository..."
    sudo zypper addrepo --check --refresh --non-interactive "http://download.opensuse.org/tumbleweed/factory/repo/oss/" openSUSE-Tumbleweed-Factory || error_msg "Failed to add Factory repository"
fi

# 5. Install system packages from the Factory repos using zypper
declare -a system_packages=(opi vlc lutris steam fastfetch)

for pkg in "${system_packages[@]}"; do
    echo "Checking for system package: $pkg..."
    if rpm -q "$pkg" &> /dev/null; then
        echo "$pkg is already installed."
    else
        echo "Installing $pkg..."
        sudo zypper --non-interactive install "$pkg" || error_msg "Failed to install $pkg"
    fi
done

# 6. Use opi to install Packman (if not already configured)
echo "Checking Packman configuration via opi..."
# This example assumes that 'opi list' will show 'packman' if it is already configured.
if opi list 2>/dev/null | grep -qi packman; then
    echo "Packman is already configured."
else
    echo "Installing Packman via opi..."
    opi install packman || error_msg "Failed to install Packman via opi"
fi

echo "=== Installation script completed. ==="
