#!/bin/bash
# 
# Arch Linux WSL Workshop Setup Script
#
# Usage:
#   curl -fsSL https://Shanu-Kumawat.github.io/class/setup.sh | bash
#

set -e

# Formatting helpers
fmt_info() { printf "\033[0;34m[INFO]\033[0m %s\n" "$1"; }
fmt_ok()   { printf "\033[0;32m[OK]\033[0m %s\n" "$1"; }
fmt_warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
fmt_err()  { printf "\033[0;31m[ERROR]\033[0m %s\n" "$1"; }

# Ensure script is running in WSL
grep -qi microsoft /proc/version 2>/dev/null || { fmt_err "This script is intended for WSL only. Exiting."; exit 1; }

# Trap for cleanup
cleanup() {
    # Only remove temporary build files if they still exist
    [ -d /tmp/paru ] && rm -rf /tmp/paru
    [ -d /tmp/builduser ] && rm -rf /tmp/builduser
    
    # Ensure sudoers file is cleaned up even on failure
    [ -f /etc/sudoers.d/builduser ] && rm -f /etc/sudoers.d/builduser
    
    # Remove temporary build user if it was created
    if id builduser >/dev/null 2>&1; then
        sudo userdel -r builduser 2>/dev/null || true
    fi
}
trap cleanup EXIT

# 1. Optimize Pacman Mirrors for India
fmt_info "Optimizing pacman mirrors for India..."
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
MIRRORS=$(curl -fsSL "https://archlinux.org/mirrorlist/?country=IN&protocol=https&use_mirror_status=on" 2>/dev/null || true)
if [ -n "$MIRRORS" ]; then
    echo "$MIRRORS" | sed -e 's/^#Server/Server/' | sudo tee /etc/pacman.d/mirrorlist > /dev/null
    fmt_ok "Mirrorlist updated."
else
    fmt_warn "Failed to fetch mirrors. Using default mirrorlist."
fi

# 2. Update and install base packages
fmt_info "Updating system and installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm zsh git curl wget neovim nano eza bat zoxide fzf ripgrep \
  base-devel unzip zip bzip2 tar xsel github-cli \
  python nodejs npm gcc cmake make btop htop tmux tree jq

# 3. Install JetBrainsMono Nerd Font for Windows (via WSL)
fmt_info "Installing JetBrainsMono Nerd Font for Windows Terminal..."
mkdir -p /tmp/fonts
cd /tmp/fonts
curl -fLo "JetBrainsMono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
unzip -q -o JetBrainsMono.zip -d JetBrainsMono
# Identify Windows Font Directory from WSL
WIN_USER=$(powershell.exe '$env:UserName' | tr -d '\r')
WIN_FONT_DIR_WSL="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Windows/Fonts"
WIN_FONT_DIR_WIN="C:\\Users\\$WIN_USER\\AppData\\Local\\Microsoft\\Windows\\Fonts"

if [ -d "/mnt/c/Users/$WIN_USER" ]; then
    mkdir -p "$WIN_FONT_DIR_WSL"
    cp JetBrainsMono/*.ttf "$WIN_FONT_DIR_WSL/"
    # Register fonts in Windows Registry via PowerShell using the Windows path
    powershell.exe -Command "
    \$fonts = Get-ChildItem -Path '${WIN_FONT_DIR_WIN}' -Filter 'JetBrainsMonoNerd*';
    foreach (\$font in \$fonts) {
        New-ItemProperty -Name \$font.Name -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -PropertyType string -Value \$font.FullName -Force | Out-Null
    }
    "
    fmt_ok "JetBrainsMono Nerd Font installed in Windows."
    fmt_warn "ACTION REQUIRED: Open Windows Terminal Settings -> Defaults -> Appearance, and set 'Font Face' to 'JetBrainsMono Nerd Font'."
    # Safe to clean up fonts now that they are copied
    rm -rf /tmp/fonts
else
    fmt_warn "Could not determine Windows User path. Please manually install the font from the zip downloaded to /tmp/fonts."
fi
cd - > /dev/null || true

# 4. Install Paru (AUR Helper)
if ! command -v paru >/dev/null 2>&1; then
    fmt_info "Installing Paru (AUR Helper)..."
    # Ensure base-devel is installed before makepkg (already in pacman line, but good practice)
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    # makepkg cannot be run as root. Create a temporary unprivileged user if we are root.
    if [ "$EUID" -eq 0 ]; then
        fmt_info "Running as root. Creating temporary 'builduser' to compile Paru..."
        if ! id builduser >/dev/null 2>&1; then
            useradd -m -d /tmp/builduser builduser
            echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser
        fi
        chown -R builduser:builduser /tmp/paru
        sudo -u builduser makepkg -si --noconfirm
        rm -f /etc/sudoers.d/builduser
    else
        makepkg -si --noconfirm
    fi
    cd - > /dev/null || true
    fmt_ok "Paru installed."
else
    fmt_info "Paru is already installed."
fi

# 5. Change default shell to zsh
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    fmt_info "Changing default shell to zsh..."
    sudo chsh -s /usr/bin/zsh "$USER"
    fmt_ok "Shell changed to zsh."
fi

# 6. Install uv (Python Package Manager)
fmt_info "Installing 'uv' Python package manager..."
if ! command -v uv >/dev/null 2>&1; then
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        fmt_ok "uv installed."
    else
        fmt_warn "Failed to install uv. Install manually later: https://docs.astral.sh/uv"
    fi
else
    fmt_info "uv is already installed."
fi

# 7. Download custom configurations
fmt_info "Downloading workshop dotfiles..."
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
    fmt_info "Backed up existing .zshrc to .zshrc.bak"
fi
if [ -f ~/.p10k.zsh ]; then
    cp ~/.p10k.zsh ~/.p10k.zsh.bak
    fmt_info "Backed up existing .p10k.zsh to .p10k.zsh.bak"
fi

curl -fLo ~/.zshrc https://Shanu-Kumawat.github.io/class/.zshrc
curl -fLo ~/.p10k.zsh https://Shanu-Kumawat.github.io/class/.p10k.zsh

# 8. Install Neovim Config
fmt_info "Setting up Neovim..."
if [ -t 0 ]; then
    curl -fsSL https://Shanu-Kumawat.github.io/nvim | bash || fmt_warn "Neovim config setup encountered an issue."
else
    fmt_warn "Skipping interactive Neovim setup in non-TTY pipe. You can run curl -fsSL https://Shanu-Kumawat.github.io/nvim | bash manually later."
fi

# 9. Git and GitHub Setup
fmt_info "Configuring Git and GitHub..."

# Safe, non-sensitive default that benefits everyone universally
git config --global init.defaultBranch main

# Ensure we are connected to a TTY before asking for interactive input
if [ -t 0 ]; then
    echo ""
    read -p "Enter your full name for Git commits (e.g., John Doe): " git_name
    read -p "Enter your GitHub email address: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"

    fmt_ok "Git name and email configured."
    echo ""
    read -p "Do you want to authenticate with GitHub CLI now? (Skip if you already have SSH keys you don't want to overwrite) [Y/n]: " auth_choice
    
    auth_choice="${auth_choice:-y}"
    if [[ "${auth_choice,,}" == "y" ]]; then
        fmt_info "Now connecting to GitHub using the GitHub CLI..."
        fmt_info "Select 'HTTPS' or 'SSH'. If you choose SSH and already have a key, be careful not to overwrite it!"
        echo ""
        gh auth login || fmt_warn "GitHub CLI authentication exited with an error."
    else
        fmt_info "Skipped GitHub CLI authentication."
    fi
else
    fmt_warn "Script is running non-interactively (e.g., curled via pipe). Skipping interactive Git and gh setup."
    fmt_warn "Please run 'git config --global user.name' and 'gh auth login' manually later."
fi

fmt_ok "Setup complete! Please explicitly log out of your WSL session or fully restart Windows Terminal for all changes (like the default shell) to fully apply."
