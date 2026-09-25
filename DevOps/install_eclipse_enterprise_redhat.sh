#!/bin/bash
# ==============================================================================
# Script Name: install_eclipse_enterprise.sh
# Description: Automates download and installation of Eclipse IDE for 
#              Enterprise Java and Web Developers on 64-bit RHEL.
# ==============================================================================

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo or as root."
  exit 1
fi

echo "[+] Verifying OpenJDK installation..."
if ! command -v java &> /dev/null; then
    echo "[!] Java runtime not found. Installing OpenJDK 21 Development Environment..."
    if command -v dnf &> /dev/null; then
        dnf install -y java-21-openjdk-devel
    elif command -v yum &> /dev/null; then
        yum install -y java-21-openjdk-devel
    else
        echo "[-] Package manager (dnf/yum) not found. Please install Java manually."
        exit 1
    fi
else
    echo "[+] Java is already installed: $(java -version 2>&1 | head -n 1)"
fi

# Define URLs and Tarball file names
# Mirror download link pointing directly to the Enterprise/Web package for Linux x86_64
DOWNLOAD_URL="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2026-09/R/eclipse-jee-2026-09-R-linux-gtk-x86_64.tar.gz&r=1"
TAR_NAME="eclipse-jee-linux-x86_64.tar.gz"
INSTALL_DIR="/opt"

echo "[+] Downloading Eclipse IDE for Enterprise Java and Web Developers..."
curl -L "$DOWNLOAD_URL" -o "/tmp/$TAR_NAME"

if [ $? -ne 0 ] || [ ! -f "/tmp/$TAR_NAME" ]; then
    echo "[-] Download failed. Please verify your internet connection or the package URL."
    exit 1
fi

echo "[+] Extracting archive files to $INSTALL_DIR..."
# Remove any prior custom installation in /opt/eclipse to prevent conflicts
if [ -d "$INSTALL_DIR/eclipse" ]; then
    rm -rf "$INSTALL_DIR/eclipse"
fi

tar -zxf "/tmp/$TAR_NAME" -C "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo "[-] Extraction failed."
    exit 1
fi

echo "[+] Configuring system environment links..."
# Create symlink so 'eclipse' command works globally from the terminal shell
ln -sf "$INSTALL_DIR/eclipse/eclipse" /usr/bin/eclipse

echo "[+] Generating GNOME Desktop Application Launcher Entry..."
cat <<EOF > /usr/share/applications/eclipse.desktop
[Desktop Entry]
Name=Eclipse Enterprise IDE
Comment=Eclipse IDE for Enterprise Java and Web Developers
Exec=/usr/bin/eclipse
Icon=/opt/eclipse/icon.xpm
Terminal=false
Type=Application
Categories=Development;IDE;Java;
EOF

# Clean temporary archive cache
rm -f "/tmp/$TAR_NAME"

echo "=============================================================================="
echo "[+] SUCCESS: Eclipse Enterprise IDE has been installed!"
echo "[+] You can now launch it by typing 'eclipse' in your terminal"
echo "[+] Or open it from your Applications menu (Development graphics category)."
echo "=============================================================================="
