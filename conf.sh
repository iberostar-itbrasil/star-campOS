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
alsa-utils pulseaudio pavucontrol xfce4-power-manager feh curl unzip \
x11-xserver-utils xterm python3 python3-pyqt5 python3-pyqt5.qtwebengine

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

echo -e "${GREEN}Setting up Openbox autostart to launch Kiosk Browser...${RESET}"
mkdir -p /home/star-campus/.config/openbox

cat <<EOF > /home/star-campus/.config/openbox/autostart
# Set wallpaper
feh --bg-scale /home/star-campus/Pictures/wallpaper.png &

# Start PolicyKit agent (for Wi-Fi permissions)
lxpolkit &
pulseaudio --start &
nm-applet &

# Start Python Kiosk Browser
python3 /home/star-campus/kiosk_browser.py &
EOF

sudo chown -R star-campus:star-campus /home/star-campus/.config

echo -e "${GREEN}Creating Python Kiosk Browser App...${RESET}"

cat <<EOF > /home/star-campus/kiosk_browser.py
#!/usr/bin/env python3

import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QPushButton, QHBoxLayout
from PyQt5.QtWebEngineWidgets import QWebEngineView

class KioskBrowser(QMainWindow):
    def __init__(self):
        super().__init__()

        self.homepage = "https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus"

        central_widget = QWidget()
        layout = QVBoxLayout(central_widget)
        self.setCentralWidget(central_widget)

        self.browser = QWebEngineView()
        self.browser.load(QUrl(self.homepage))
        layout.addWidget(self.browser)

        nav_bar = QHBoxLayout()

        home_button = QPushButton("Home")
        back_button = QPushButton("Back")
        close_button = QPushButton("Close")

        home_button.clicked.connect(self.go_home)
        back_button.clicked.connect(self.browser.back)
        close_button.clicked.connect(self.close_browser)

        nav_bar.addWidget(home_button)
        nav_bar.addWidget(back_button)
        nav_bar.addWidget(close_button)

        layout.addLayout(nav_bar)

        self.setWindowTitle("StarCampus Kiosk")
        self.showFullScreen()

    def go_home(self):
        self.browser.load(QUrl(self.homepage))

    def close_browser(self):
        QApplication.quit()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    browser = KioskBrowser()
    sys.exit(app.exec_())
EOF

sudo chown star-campus:star-campus /home/star-campus/kiosk_browser.py
sudo chmod +x /home/star-campus/kiosk_browser.py

echo -e "${GREEN}Setting ownership for all files to star-campus...${RESET}"
sudo chown -R star-campus:star-campus /home/star-campus

echo -e "${GREEN}FINAL STEP: Setup completed successfully! Please REBOOT your system.${RESET}"
