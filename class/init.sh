#!/bin/bash

# 1. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Welcome to the Arch WSL Setup Script!"
echo "-------------------------------------"

# 2. Prompt for the new username
read -p "Enter the new username you want to create: " NEW_USER

# 3. Update the system
echo ">>> Updating system packages..."
pacman -Syu --noconfirm

# 4. Install essential packages
echo ">>> Installing essential packages (sudo, base-devel, micro, curl)..."
pacman -S --noconfirm --needed sudo base-devel micro curl

# 5. Create the normal user
echo ">>> Creating user '$NEW_USER'..."
useradd -m -G wheel "$NEW_USER"

# 6. Set the password
echo ">>> Please set a password for '$NEW_USER':"
passwd "$NEW_USER"

# 7. Enable sudo for the wheel group
echo ">>> Enabling sudo privileges for the wheel group..."

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# 8. Set the default WSL user
echo ">>> Configuring WSL to log in as '$NEW_USER' by default..."
cat <<EOF > /etc/wsl.conf
[user]
default=$NEW_USER
EOF

echo "-------------------------------------"
echo "Setup Complete!"
echo "To finish, exit this shell by typing: exit"
echo "Then, restart WSL from Windows PowerShell by running: wsl --shutdown"
echo "When you open Arch again, you will be logged in as '$NEW_USER'."
