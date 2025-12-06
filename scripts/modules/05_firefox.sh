#!/bin/bash
# scripts/modules/05_firefox.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "安装 Firefox (PPA Version)"

# 1. 添加 PPA 源
log "添加 Firefox PPA: $FIREFOX_PPA"
if ! grep -q "mozillateam" /etc/apt/sources.list.d/* 2>/dev/null; then
    sudo add-apt-repository -y "$FIREFOX_PPA"
else
    print_warning "Firefox PPA already added."
fi

# 2. 配置 APT 优先级
log "配置 APT 优先级..."
DEST_PREF_FILE="/etc/apt/preferences.d/mozilla-firefox"
TMP_PREF="/tmp/mozilla-firefox"

install_template "mozilla-firefox.pref" "$TMP_PREF"
sudo mv "$TMP_PREF" "$DEST_PREF_FILE"
sudo chown root:root "$DEST_PREF_FILE"
sudo chmod 644 "$DEST_PREF_FILE"

# 3. 安装
log "更新并安装 Firefox..."
sudo apt update
sudo apt install -y firefox

print_success "Firefox (PPA) 安装完成"
