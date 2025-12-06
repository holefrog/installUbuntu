#!/bin/bash
# setup/06_rime.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SOURCE_RIME_DIR="$GLOBAL_DATA_DIR/rime-data"

print_header "Rime 输入法配置"

print_message $YELLOW "Installing Rime..."
sudo apt install -y ibus-rime librime-data-wubi

# 忽略服务未运行的错误
ibus restart || true

if [ -d "$SOURCE_RIME_DIR" ]; then
    print_message $BLUE "Deploying config..."
    mkdir -p "$HOME/.config/ibus/rime/"
    
    cp -r "$SOURCE_RIME_DIR/"* "$HOME/.config/ibus/rime/"
    print_success "Config copied."
    
    if command -v ibus-daemon &> /dev/null; then
        /usr/bin/ibus-daemon -drx || true
        print_success "Rime re-deployed."
    fi
else
    print_warning "Rime data not found: $SOURCE_RIME_DIR"
fi

print_success "Rime setup done."
