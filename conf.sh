#!/bin/bash

set -e  # Exit if anything fails

GREEN='\e[32m'
RESET='\e[0m'

echo -e "${GREEN}Installing sudo first...${RESET}"
apt install -y sudo

echo -e "${GREEN}Updating system...${RESET}"
sudo apt update
sudo apt upgrade -y

echo -e "${GREEN}Installing essential packages...${RESET}"
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree firmware-iwlwifi \
xorg openbox obconf lightdm lightdm-gtk-greeter \
network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit \
alsa-utils pulseaudio pavucontrol luakit xfce4-power-manager feh curl unzip \
x11-xserver-utils xterm

echo -e "${GREEN}Creating user 'star-campus' if it doesn't exist...${RESET}"
if ! id "star-campus" &>/dev/null; then
    adduser --disabled-password --gecos "" star-campus
fi

echo -e "${GREEN}Adding 'star-campus' user to necessary groups...${RESET}"
usermod -aG audio,video,netdev,plugdev star-campus

echo -e "${GREEN}Enabling necessary services...${RESET}"
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo -e "${GREEN}Configuring LightDM for autologin as 'star-campus'...${RESET}"
sudo sed -i '/^\[Seat:\*\]/a autologin-user=star-campus\nautologin-session=openbox' /etc/lightdm/lightdm.conf

echo -e "${GREEN}Downloading and setting up wallpaper...${RESET}"
mkdir -p /home/star-campus/Pictures
curl -L -o /home/star-campus/Pictures/wallpaper.png "https://github.com/iberostar-itbrasil/star-campOS/raw/main/wallpaper.png"
sudo chown -R star-campus:star-campus /home/star-campus/Pictures

echo -e "${GREEN}Setting up Openbox autostart...${RESET}"
mkdir -p /home/star-campus/.config/openbox

cat <<EOF > /home/star-campus/.config/openbox/autostart
# Set wallpaper
feh --bg-scale /home/star-campus/Pictures/wallpaper.png &

# Start PolicyKit agent (for Wi-Fi permissions)
lxpolkit &
pulseaudio --start &
nm-applet &

# Start Luakit Kiosk
luakit &
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config

echo -e "${GREEN}Creating Luakit Kiosk Configuration...${RESET}"
mkdir -p /home/star-campus/.config/luakit

cat <<EOF > /home/star-campus/.config/luakit/rc.lua
local window = require "window"
local modes = require "modes"

-- Remove all keybinds
modes.remap_binds("normal", {})
modes.remap_binds("insert", {})
modes.remap_binds("command", {})
modes.remap_binds("prompt", {})

-- Open locked URL fullscreen
local w = window.open("https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus")
w:fullscreen()

-- Disable right-click menu
webview.context_menu_enabled = false
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config/luakit

echo -e "${GREEN}Creating .Xmodmap to disable dangerous shortcuts...${RESET}"
cat <<EOF > /home/star-campus/.Xmodmap
! Disable Ctrl+T (New Tab)
keycode 28 = NoSymbol

! Disable Ctrl+W (Close Tab)
keycode 25 = NoSymbol

! Disable Alt+F4 (Close Window)
keycode 70 = NoSymbol
EOF

sudo chown star-campus:star-campus /home/star-campus/.Xmodmap

echo -e "${GREEN}Setting ownership for all files to star-campus...${RESET}"
sudo chown -R star-campus:star-campus /home/star-campus

echo -e "${GREEN}FINAL STEP: Setup completed successfully! Please REBOOT your system.${RESET}"
