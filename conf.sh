#!/bin/bash

set -e  # Exit if anything fails

echo "Updating system..."
sudo apt update
sudo apt upgrade -y

echo "Installing essential drivers and minimal GUI environment..."
sudo apt install -y firmware-linux firmware-linux-free firmware-linux-nonfree firmware-iwlwifi \
xorg openbox obconf lightdm lightdm-gtk-greeter \
network-manager network-manager-gnome wireless-tools wpasupplicant lxpolkit \
alsa-utils pulseaudio pavucontrol firefox-esr xfce4-power-manager feh curl unzip

echo "Enabling necessary services..."
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo "Adding user to audio group..."
sudo usermod -aG audio $USER

echo "Configuring LightDM for autologin..."
sudo sed -i '/^\[Seat:\*\]/a autologin-user='"$USER"'\nautologin-session=openbox' /etc/lightdm/lightdm.conf

echo "Creating Firefox Watcher script..."
sudo tee /usr/local/bin/firefox-watcher.sh > /dev/null <<'EOF'
#!/bin/bash
while true
do
    if ! pgrep -x "firefox" > /dev/null
    then
        firefox --kiosk --private-window "https://starteam.grupoiberostar.com/sesion/nuevo?ref=campus" &
    fi
    sleep 5
done
EOF

sudo chmod +x /usr/local/bin/firefox-watcher.sh

echo "Downloading and setting up wallpaper..."
mkdir -p ~/Pictures
curl -L -o ~/Pictures/wallpaper.jpg "https://encurtador.com.br/5caKS"

echo "Installing custom Firefox extension..."
# Create directory for the extension
sudo mkdir -p /usr/lib/firefox/browser/extensions/nav-bar-ext

# Download and unzip extension
curl -L -o /tmp/nav-bar-ext.zip "https://github.com/iberostar-itbrasil/star-campOS/raw/main/nav-bar-ext.zip"
sudo unzip -o /tmp/nav-bar-ext.zip -d /usr/lib/firefox/browser/extensions/nav-bar-ext

# Set permissions
sudo chmod -R 755 /usr/lib/firefox/browser/extensions/nav-bar-ext

# Clean up temporary zip
rm /tmp/nav-bar-ext.zip

echo "Setting up Openbox autostart..."
mkdir -p ~/.config/openbox

cat <<EOF > ~/.config/openbox/autostart
# Set wallpaper using feh
feh --bg-scale ~/Pictures/wallpaper.jpg &

# Start PolicyKit agent (for Wi-Fi permissions)
lxpolkit &

# Start PulseAudio
pulseaudio --start &

# Start NetworkManager Applet (Wi-Fi GUI)
nm-applet &

# Start Firefox Watcher (launch Firefox Kiosk+Private mode)
firefox-watcher.sh &
EOF

echo "Configuring Openbox keyboard shortcuts (Shift + Alt + T for terminal)..."
if ! grep -q "A-S-T" ~/.config/openbox/rc.xml; then
  sed -i '/<keyboard>/a \
    <keybind key="A-S-T">\
      <action name="Execute">\
        <command>x-terminal-emulator</command>\
      </action>\
    </keybind>' ~/.config/openbox/rc.xml
fi

echo "Finalizing setup..."
echo "Setup completed successfully! Please reboot your system."
