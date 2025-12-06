#!/bin/bash
# scripts/modules/02_remove_snap.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "移除 Snap"

# 1. 移除 Snap 软件包
if command_exists snap; then
    log "正在移除 Snap 软件包..."
    snaps=$(snap list 2>/dev/null | awk '{if (NR>1) print $1}' || true)
    for snap in $snaps; do
        sudo snap remove "$snap" 2>/dev/null || true
    done
else
    print_warning "未检测到 Snap 命令，跳过包移除。"
fi

# 2. 停止服务
log "停止 Snap 服务..."
sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
sudo systemctl disable snapd.service snapd.socket 2>/dev/null || true

# 3. 卸载 Snapd
log "卸载 Snapd..."
sudo apt purge -y snapd || true
sudo apt-mark hold snapd || true

# 4. 清理残留
log "清理残留文件..."
sudo rm -rf "$HOME/snap" /snap /var/snap /var/lib/snapd /var/cache/snapd

# 5. 配置 APT 优先级阻止 Snap
log "配置 APT 优先级..."
DEST_PREF_FILE="/etc/apt/preferences.d/nosnap.pref"

# 暂时生成到 tmp，再移动以获取 sudo 权限
TMP_PREF="/tmp/nosnap.pref"
install_template "nosnap.pref" "$TMP_PREF"
sudo mv "$TMP_PREF" "$DEST_PREF_FILE"
sudo chown root:root "$DEST_PREF_FILE"
sudo chmod 644 "$DEST_PREF_FILE"

print_success "Snap 已移除"
