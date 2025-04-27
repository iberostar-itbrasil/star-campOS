#!/bin/bash

set -e  # Exit if anything fails

GREEN='\e[32m'
RESET='\e[0m'

echo -e "${GREEN}Installing sudo...${RESET}"
apt install -y sudo

echo -e "${GREEN}Updating system...${RESET}"
sudo apt update
sudo apt upgrade -y

echo -e "${GREEN}Installing essential packages...${RESET}"
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree firmware-iwlwifi \
xorg openbox obconf lightdm lightdm-gtk-greeter \
network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit \
alsa-utils pulseaudio pavucontrol chromium xfce4-power-manager feh curl unzip \
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

echo -e "${GREEN}Creating Chromium Watcher script...${RESET}"
sudo tee /usr/local/bin/chromium-watcher.sh > /dev/null <<'EOF'
#!/bin/bash
touch /tmp/watcher_enabled

# Launch Chromium initially
chromium --kiosk --incognito \
--no-first-run --disable-translate --disable-infobars --disable-session-crashed-bubble --disable-pinch \
--overscroll-history-navigation=0 --start-maximized \
--load-extension=/usr/lib/chromium/extensions/nav-bar-ext \
"https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus" &

while true
do
    if [ ! -f /tmp/watcher_enabled ]; then
        echo "Watcher stopped."
        exit 0
    fi
    if ! pgrep -x "chromium" > /dev/null; then
        chromium --kiosk --incognito \
        --no-first-run --disable-translate --disable-infobars --disable-session-crashed-bubble --disable-pinch \
        --overscroll-history-navigation=0 --start-maximized \
        --load-extension=/usr/lib/chromium/extensions/nav-bar-ext \
        "https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus" &
    fi
    sleep 5
done
EOF

sudo chmod +x /usr/local/bin/chromium-watcher.sh
sudo chown star-campus:star-campus /usr/local/bin/chromium-watcher.sh

echo -e "${GREEN}Downloading and setting up wallpaper...${RESET}"
mkdir -p /home/star-campus/Pictures
curl -L -o /home/star-campus/Pictures/wallpaper.png "https://github.com/iberostar-itbrasil/star-campOS/raw/main/wallpaper.png"
sudo chown -R star-campus:star-campus /home/star-campus/Pictures

echo -e "${GREEN}Downloading and setting up Chromium extension...${RESET}"
sudo mkdir -p /usr/lib/chromium/extensions/nav-bar-ext
curl -L -o /tmp/nav-bar-ext.zip "https://github.com/iberostar-itbrasil/star-campOS/raw/main/nav-bar-ext.zip"
sudo unzip -o /tmp/nav-bar-ext.zip -d /usr/lib/chromium/extensions/nav-bar-ext
sudo chmod -R 755 /usr/lib/chromium/extensions/nav-bar-ext
rm /tmp/nav-bar-ext.zip

echo -e "${GREEN}Setting up Openbox autostart...${RESET}"
mkdir -p /home/star-campus/.config/openbox

cat <<EOF > /home/star-campus/.config/openbox/autostart
# Load custom keyboard map (block shortcuts)
xmodmap /home/star-campus/.Xmodmap &

# Set wallpaper
feh --bg-scale /home/star-campus/Pictures/wallpaper.png &

# Start PolicyKit agent (for Wi-Fi permissions)
lxpolkit &

# Start PulseAudio
pulseaudio --start &

# Start NetworkManager Applet (Wi-Fi GUI)
nm-applet &

# Start Chromium Watcher
chromium-watcher.sh &
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config

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

echo -e "${GREEN}Configuring Openbox keyboard shortcuts (Shift + Alt + T to open xterm and stop watcher)...${RESET}"
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
        <command>rm -f /tmp/watcher_enabled && xterm</command>\
      </action>\
    </keybind>' "$CONFIG_FILE"
fi

echo -e "${GREEN}Setting ownership for all files to star-campus...${RESET}"
sudo chown -R star-campus:star-campus /home/star-campus

echo -e "${GREEN}FINAL STEP: Setup completed successfully! Please REBOOT your system.${RESET}"
