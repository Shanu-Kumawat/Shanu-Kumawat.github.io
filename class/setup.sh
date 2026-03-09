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

# Detect OS
OS="$(uname -s)"
if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
    fmt_err "Unsupported OS: $OS"
    exit 1
fi

if [ "$OS" = "Linux" ]; then
    # Ensure script is running in WSL if on Linux
    grep -qi microsoft /proc/version 2>/dev/null || { fmt_err "This script is intended for WSL only. Exiting."; exit 1; }
fi

# Trap for cleanup
cleanup() {
    [ -d /tmp/paru ] && rm -rf /tmp/paru
    [ -d /tmp/builduser ] && rm -rf /tmp/builduser
    [ -f /etc/sudoers.d/builduser ] && sudo rm -f /etc/sudoers.d/builduser
    if id builduser >/dev/null 2>&1; then
        sudo userdel -r builduser 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ---------- Fix WSL interop ----------
fix_wsl_interop() {
    if [ "$OS" != "Linux" ]; then return; fi
    if powershell.exe -NoProfile -Command 'echo ok' 2>/dev/null | grep -q ok; then
        fmt_ok "WSL interop already working."
        return
    fi
    fmt_warn "Fixing WSL interop..."
    echo ':WSLInterop:M::MZ::/init:PF' | sudo tee /usr/lib/binfmt.d/WSLInterop.conf >/dev/null
    if systemctl list-units --all 2>/dev/null | grep -q systemd-binfmt; then
        sudo systemctl unmask systemd-binfmt.service
        sudo systemctl restart systemd-binfmt.service
        sudo systemctl mask systemd-binfmt.service
    else
        echo ':WSLInterop:M::MZ::/init:PF' | sudo tee /proc/sys/fs/binfmt_misc/register >/dev/null 2>&1 || true
    fi
    if powershell.exe -NoProfile -Command 'echo ok' 2>/dev/null | grep -q ok; then
        fmt_ok "WSL interop restored."
    else
        fmt_err "WSL interop could not be fixed automatically."
    fi
}

if [ "$OS" = "Linux" ]; then
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

    # Enable parallel downloads
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || true

    # 2. Update and install base packages (Arch)
    fmt_info "Updating system and installing base packages..."
    sudo pacman -Syu --noconfirm || fmt_warn "System upgrade encountered issues."
    sudo pacman -S --needed --noconfirm zsh git curl wget neovim nano eza bat zoxide fzf ripgrep \
      base-devel unzip zip bzip2 tar xsel github-cli openssh \
      python nodejs npm gcc cmake make btop htop tmux tree jq \
      yazi fd p7zip poppler imagemagick cmatrix asciiquarium fastfetch lazygit \
      yarn libnotify

    # ---------- Fix WSL interop before Windows commands ----------
    fix_wsl_interop

elif [ "$OS" = "Darwin" ]; then
    # 2. Update and install base packages (macOS)
    fmt_info "Installing Homebrew and base packages for macOS..."
    if ! command -v brew >/dev/null 2>&1; then
        fmt_info "Homebrew not found. Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for this script session
        if [ -x "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        fmt_ok "Homebrew installed."
    else
        fmt_info "Homebrew is already installed."
    fi
    fmt_info "Updating Homebrew and installing Brew packages..."
    brew update
    brew install zsh git curl wget neovim nano eza bat zoxide fzf ripgrep \
      unzip zip sevenzip gh python nodejs gcc cmake make \
      btop htop tmux tree jq yazi fd poppler imagemagick cmatrix \
      asciiquarium fastfetch lazygit yarn libnotify
fi

# 3. Install JetBrainsMono Nerd Font
if [ "$OS" = "Linux" ]; then
    if ls /mnt/c/Windows/Fonts | grep -qi "JetBrainsMono"; then
        fmt_info "JetBrainsMono Nerd Font already installed in Windows."
    else
        fmt_info "Installing JetBrainsMono Nerd Font..."
        TMP_DIR="/tmp/fonts"
        ARCHIVE="/tmp/JetBrainsMono.tar.xz"
        mkdir -p "$TMP_DIR"

        curl -fsSL -o "$ARCHIVE" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
        tar -xf "$ARCHIVE" -C "$TMP_DIR"

        WIN_USER=$(powershell.exe '$env:UserName' | tr -d '\r')
        WIN_FONT_TMP="/mnt/c/Users/$WIN_USER/AppData/Local/Temp/jb-fonts"
        mkdir -p "$WIN_FONT_TMP"

        cp "$TMP_DIR"/JetBrainsMonoNerdFont-{Regular,Bold,Italic,BoldItalic}.ttf "$WIN_FONT_TMP"
        explorer.exe "$(wslpath -w "$WIN_FONT_TMP")" >/dev/null 2>&1 &

        fmt_warn "ACTION REQUIRED: Select all fonts in the opened folder -> Right click -> Install"
        read -p "Press ENTER after installing fonts..."

        rm -rf "$TMP_DIR" "$ARCHIVE"
    fi
elif [ "$OS" = "Darwin" ]; then
    fmt_info "Installing JetBrainsMono Nerd Font..."
    TMP_DIR="/tmp/fonts"
    ARCHIVE="/tmp/JetBrainsMono.tar.xz"
    mkdir -p "$TMP_DIR"
    
    curl -fsSL -o "$ARCHIVE" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf "$ARCHIVE" -C "$TMP_DIR"

    MAC_FONT_DIR="$HOME/Library/Fonts"
    mkdir -p "$MAC_FONT_DIR"
    cp "$TMP_DIR"/JetBrainsMonoNerdFont-{Regular,Bold,Italic,BoldItalic}.ttf "$MAC_FONT_DIR/"
    fmt_ok "JetBrainsMono Nerd Font installed in macOS."
    fmt_warn "ACTION REQUIRED: Open your Terminal App's Settings and update your font to 'JetBrainsMono Nerd Font'."
    rm -rf "$TMP_DIR" "$ARCHIVE"
fi

# 4. Install Paru (AUR Helper - Linux Only)
if [ "$OS" = "Linux" ]; then
    if ! command -v paru >/dev/null 2>&1; then
        fmt_info "Installing Paru..."
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        if [ "$EUID" -eq 0 ]; then
            sudo useradd -m -d /tmp/builduser builduser
            echo "builduser ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/builduser
            sudo chown -R builduser:builduser /tmp/paru
            sudo -u builduser makepkg -si --noconfirm
        else
            makepkg -si --noconfirm
        fi
        cd - > /dev/null || true
        fmt_ok "Paru installed."
    else
        fmt_info "Paru already installed."
    fi
fi

# 5. Change default shell to zsh
if [ "$OS" = "Linux" ]; then
    ZSH_PATH="/usr/bin/zsh"
elif [ "$OS" = "Darwin" ]; then
    ZSH_PATH="/bin/zsh"
fi

if [ "$SHELL" != "$ZSH_PATH" ] && command -v zsh >/dev/null 2>&1; then
    fmt_info "Changing default shell to zsh..."
    if [ "$OS" = "Linux" ]; then
        sudo chsh -s "$ZSH_PATH" "$USER"
    else
        chsh -s "$ZSH_PATH"
    fi
    fmt_ok "Shell changed to zsh."
fi

# 6. Install uv (Python Package Manager)
fmt_info "Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh || fmt_warn "uv install failed."
else
    fmt_info "uv already installed."
fi

fmt_info "Installing Zinit (zsh plugin manager)..."
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
install_zinit() {
    rm -rf "$ZINIT_HOME"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
        fmt_err "Zinit installation failed."
        exit 1
    fi
}
# Detect broken install
if [ -d "$ZINIT_HOME" ]; then
    if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
        fmt_warn "Detected broken Zinit installation. Reinstalling..."
        install_zinit
    else
        fmt_info "Zinit already installed."
    fi
else
    install_zinit
fi
fmt_ok "Zinit ready."

# 7. Download custom configurations
fmt_info "Downloading workshop dotfiles..."
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
[ -f ~/.p10k.zsh ] && cp ~/.p10k.zsh ~/.p10k.zsh.bak

curl -fsSL -o ~/.zshrc https://Shanu-Kumawat.github.io/class/.zshrc || fmt_warn "Failed to download .zshrc"
curl -fsSL -o ~/.p10k.zsh https://Shanu-Kumawat.github.io/class/.p10k.zsh || fmt_warn "Failed to download .p10k.zsh"

# 8. Install Neovim Config
fmt_info "Setting up Neovim..."
if [ -t 0 ]; then
    curl -fsSL https://Shanu-Kumawat.github.io/nvim | bash || fmt_warn "Neovim setup failed."
else
    fmt_warn "Skipping interactive Neovim setup."
fi

# 9. Git and GitHub Setup
fmt_info "Configuring Git and GitHub..."

# Ensure browser opener exists for gh login
if [ "$OS" = "Linux" ]; then
    if ! command -v xdg-open >/dev/null 2>&1; then
        fmt_info "Installing xdg-utils for browser integration..."
        sudo pacman -S --needed --noconfirm xdg-utils >/dev/null
    fi
fi

# ---------- Git Identity ----------
existing_name=$(git config --global user.name || true)
existing_email=$(git config --global user.email || true)

if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
    fmt_info "Git already configured:"
    echo "  Name : $existing_name"
    echo "  Email: $existing_email"

    read -p "Do you want to change these? [y/N]: " change_git
    change_git=${change_git:-n}

    if [[ "${change_git,,}" == "y" ]]; then
        read -p "Enter your full name for Git commits: " git_name
        read -p "Enter your GitHub email address: " git_email

        git config --global user.name "$git_name"
        git config --global user.email "$git_email"

        fmt_ok "Git identity updated."
    else
        git_email="$existing_email"
        fmt_info "Keeping existing Git identity."
    fi
else
    if [ -t 0 ]; then
        read -p "Enter your full name for Git commits: " git_name
        read -p "Enter your GitHub email address: " git_email

        git config --global user.name "$git_name"
        git config --global user.email "$git_email"

        fmt_ok "Git identity configured."
    else
        fmt_warn "Script is running non-interactively. Run 'git config --global user.name/email' later."
    fi
fi

git config --global init.defaultBranch main

# ---------- SSH Key Setup ----------
fmt_info "Setting up GitHub SSH authentication..."

# Ensure OpenSSH exists
if [ "$OS" = "Linux" ]; then
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        fmt_info "Installing OpenSSH..."
        sudo pacman -S --needed --noconfirm openssh
    fi
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Authenticate GitHub CLI if needed
if gh auth status >/dev/null 2>&1; then
    fmt_ok "GitHub CLI already authenticated."
else
    if [ -t 0 ]; then
        fmt_info "Authenticating GitHub CLI..."
        gh auth login --scopes admin:public_key
    else
        fmt_warn "Script is running non-interactively. Run 'gh auth login' later."
    fi
fi

# Generate SSH key if missing
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    if [ -t 0 ] || [ -n "$git_email" ]; then
        fmt_info "Generating SSH key..."
        ssh-keygen -t ed25519 -C "${git_email:-wsl-user}" -f "$HOME/.ssh/id_ed25519" -N ""
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1
    fi
else
    fmt_info "SSH key already exists."
fi

# Upload key to GitHub (ignore duplicates)
if [ -t 0 ] && gh auth status >/dev/null 2>&1; then
    fmt_info "Ensuring SSH key exists on GitHub..."
    gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "WSL/Mac Setup Key" 2>/dev/null || true
    fmt_ok "SSH key ensured on GitHub."
fi

# Avoid SSH trust prompt
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

# Verify SSH connection
fmt_info "Testing GitHub SSH connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    fmt_ok "GitHub SSH authentication working."
else
    fmt_warn "SSH authentication test failed."
fi

fmt_warn "Restart Terminal or open a new shell for all changes to apply."
fmt_info "Initializing zsh plugins..."
zsh -i -c exit
