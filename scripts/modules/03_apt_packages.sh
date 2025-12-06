#!/bin/bash
# setup/02_apt.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAUSE_MSG="Press Enter to continue..."

print_header "Updating package list"
sudo apt update
wait_for_enter "List updated. $PAUSE_MSG"

# 遍历 setup.ini 中的 APT_PACKAGES 数组
for package in "${APT_PACKAGES[@]}"; do
    pkg_name="${package%%:*}"
    pkg_desc="${package##*:}"
    print_header "Installing ${pkg_desc}"
    
    sudo apt install "$pkg_name" -y
    wait_for_enter "${pkg_desc} installed. $PAUSE_MSG"
done

print_header "Installing Google Chrome"
sudo mkdir -p /etc/apt/trusted.gpg.d

if ! wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo tee /etc/apt/trusted.gpg.d/google_linux_signing_key.asc >/dev/null; then
    print_error "Failed to download Google Chrome key"
    exit 1
fi

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/google_linux_signing_key.asc] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

sudo apt update
sudo apt install google-chrome-stable -y
wait_for_enter "Google Chrome installed. $PAUSE_MSG"

print_success "All APT packages installed."
