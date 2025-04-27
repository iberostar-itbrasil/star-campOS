#!/bin/bash

set -e  # Exit if anything fails

GREEN='\e[32m'
RESET='\e[0m'

echo -e "${GREEN}Installing essential system components...${RESET}"
apt install -y sudo
sudo apt update
sudo apt upgrade -y
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree firmware-iwlwifi \
xorg openbox obconf lightdm lightdm-gtk-greeter \
network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit \
alsa-utils pulseaudio pavucontrol xfce4-power-manager feh curl unzip \
x11-xserver-utils xterm python3 python3-pyqt5 python3-pyqt5.qtwebengine

echo -e "${GREEN}Creating user 'star-campus' if needed...${RESET}"
if ! id "star-campus" &>/dev/null; then
    adduser --disabled-password --gecos "" star-campus
fi

echo -e "${GREEN}Adding 'star-campus' to system groups...${RESET}"
usermod -aG audio,video,netdev,plugdev star-campus

echo -e "${GREEN}Setting up LightDM for autologin...${RESET}"
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

# Start PolicyKit agent
lxpolkit &
pulseaudio --start &
nm-applet &

# Start Python Kiosk Browser
python3 /home/star-campus/kiosk_browser.py &
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config

echo -e "${GREEN}Installing the Kiosk Browser code...${RESET}"

cat <<EOF > /home/star-campus/kiosk_browser.py
$(sed 's/$/\\n/' /home/star-campus/kiosk_browser.py)
EOF

sudo chown star-campus:star-campus /home/star-campus/kiosk_browser.py
sudo chmod +x /home/star-campus/kiosk_browser.py

echo -e "${GREEN}Setup complete. Please REBOOT your system.${RESET}"
