#!/bin/bash

set -e  # Exit if anything fails

GREEN='\e[32m'
RESET='\e[0m'

echo -e "${GREEN}Updating system...${RESET}"
sudo apt update
sudo apt upgrade -y

echo -e "${GREEN}Installing essential drivers and minimal GUI environment...${RESET}"
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree firmware-iwlwifi \
xorg openbox obconf lightdm lightdm-gtk-greeter \
network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit \
alsa-utils pulseaudio pavucontrol chromium xfce4-power-manager feh curl unzip

echo -e "${GREEN}Creating user 'star-campus' if it doesn't exist...${RESET}"
if ! id "star-campus" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" star-campus
fi

echo -e "${GREEN}Adding 'star-campus' user to necessary groups...${RESET}"
sudo usermod -aG audio,video,netdev,plugdev star-campus

echo -e "${GREEN}Enabling necessary services...${RESET}"
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo -e "${GREEN}Configuring LightDM for autologin as 'star-campus'...${RESET}"
sudo sed -i '/^\[Seat:\*\]/a autologin-user=star-campus\nautologin-session=openbox' /etc/lightdm/lightdm.conf

echo -e "${GREEN}Creating Chromium Watcher script...${RESET}"
sudo tee /usr/local/bin/chromium-watcher.sh > /dev/null <<'EOF'
#!/bin/bash
touch /tmp/watcher_enabled
chromium --kiosk --incognito "https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus" &
while true
do
    if [ ! -f /tmp/watcher_enabled ]; then
        echo "Watcher stopped."
        exit 0
    fi
    if ! pgrep -x "chromium" > /dev/null; then
        chromium --kiosk --incognito "https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus" &
    fi
    sleep 5
done
EOF

sudo chmod +x /usr/local/bin/chromium-watcher.sh
sudo chown star-campus:star-campus /usr/local/bin/chromium-watcher.sh

echo -e "${GREEN}Downloading and setting up wallpaper for star-campus...${RESET}"
mkdir -p /home/star-campus/Pictures
curl -L -o /home/star-campus/Pictures/wallpaper.png "https://github.com/iberostar-itbrasil/star-campOS/raw/main/wallpaper.png"
sudo chown -R star-campus:star-campus /home/star-campus/Pictures

echo -e "${GREEN}Installing custom Chromium extension...${RESET}"
sudo mkdir -p /usr/lib/chromium/extensions/nav-bar-ext
curl -L -o /tmp/nav-bar-ext.zip "https://github.com/iberostar-itbrasil/star-campOS/raw/main/nav-bar-ext.zip"
sudo unzip -o /tmp/nav-bar-ext.zip -d /usr/lib/chromium/extensions/nav-bar-ext
sudo chmod -R 755 /usr/lib/chromium/extensions/nav-bar-ext
rm /tmp/nav-bar-ext.zip

echo -e "${GREEN}Setting up Openbox autostart for star-campus...${RESET}"
mkdir -p /home/star-campus/.config/openbox

cat <<EOF > /home/star-campus/.config/openbox/autostart
feh --bg-scale /home/star-campus/Pictures/wallpaper.png &
lxpolkit &
pulseaudio --start &
nm-applet &
chromium-watcher.sh &
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config

echo -e "${GREEN}Configuring Openbox keyboard shortcuts (Shift + Alt + T to open terminal and stop watcher)...${RESET}"
CONFIG_FILE="/home/star-campus/.config/openbox/rc.xml"
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p $(dirname "$CONFIG_FILE")
  cp /etc/xdg/openbox/rc.xml "$CONFIG_FILE"
  sudo chown star-campus:star-campus "$CONFIG_FILE"
fi

if ! grep -q "A-S-T" "$CONFIG_FILE"; then
  sed -i '/<keyboard>/a \
    <keybind key="A-S-T">\
      <action name="Execute">\
        <command>rm -f /tmp/watcher_enabled && x-terminal-emulator</command>\
      </action>\
    </keybind>' "$CONFIG_FILE"
fi

echo -e "${GREEN}Setting ownership to star-campus user for home directory...${RESET}"
sudo chown -R star-campus:star-campus /home/star-campus

echo -e "${GREEN}Finalizing setup... Please reboot your system.${RESET}"
