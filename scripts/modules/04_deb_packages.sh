#!/bin/bash
# setup/03_deb.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEMP_FILE="temp.deb"
PAUSE_MSG="Press Enter to continue..."

if ! command -v dpkg &> /dev/null; then
    print_error "Error: dpkg not installed."
    exit 1
fi

print_header "Updating package list"
sudo apt update
wait_for_enter "List updated. $PAUSE_MSG"

# 遍历 setup.ini 中的 DEB_PACKAGES 数组
for package in "${DEB_PACKAGES[@]}"; do
    IFS=":" read -r pkg_desc pkg_url <<< "$package"
    
    print_header "Processing ${pkg_desc}"
    
    # 1. 下载
    if ! download_file "$pkg_url" "$TEMP_FILE"; then
        print_error "Download failed for $pkg_desc"
        exit 1
    fi

    # 2. 安装
    print_message $BLUE "Installing..."
    if ! sudo dpkg -i "$TEMP_FILE"; then
        print_warning "Dependency error detected. Attempting auto-fix..."
        
        if sudo apt-get install -f -y; then
            print_success "Dependencies fixed."
        else
            print_error "Failed to fix dependencies. Installation aborted."
            rm -f "$TEMP_FILE"
            exit 1
        fi
    fi

    rm -f "$TEMP_FILE"
    wait_for_enter "${pkg_desc} installed. $PAUSE_MSG"
done

print_success "DEB installation process completed."
