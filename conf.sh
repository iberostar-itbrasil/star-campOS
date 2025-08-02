#!/bin/bash

set -e  # Exit if anything fails

echo "Updating system..."
sudo apt update
sudo apt upgrade -y

echo "Installing essential drivers (Wi-Fi, Ethernet, Audio)..."
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree \
firmware-iwlwifi firmware-realtek firmware-atheros firmware-brcm80211 firmware-intel-sound

echo "Installing graphical system (X11 + Openbox)..."
sudo apt install -y xorg openbox obconf tint2 lightdm lightdm-gtk-greeter

echo "Installing networking tools..."
sudo apt install -y network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit

echo "Installing audio system..."
sudo apt install -y alsa-utils pulseaudio pavucontrol volumeicon-alsa xfce4-volumed

echo "Installing browser..."
sudo apt install -y firefox-esr

echo "Enabling necessary services..."
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo "Adding user to audio group (for sound permissions)..."
sudo usermod -aG audio $USER

echo "Setting up Openbox autostart for network and audio..."
mkdir -p ~/.config/openbox

cat <<EOF > ~/.config/openbox/autostart
# Set background (solid color)
xsetroot -solid "#222222" &
# Start PolicyKit agent for Wi-Fi permissions
lxpolkit &
# Start PulseAudio daemon
pulseaudio --start &
# Start NetworkManager Applet (Wi-Fi GUI)
nm-applet &
# Start Volume Control Tray
volumeicon &
# Start Power Manager (battery and brightness control)
xfce4-power-manager &
# Start lightweight panel (taskbar)
tint2 &
EOF

echo "Setup complete! Please REBOOT your system now."
