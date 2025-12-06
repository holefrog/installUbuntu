#!/bin/bash
# scripts/modules/07_nextcloud.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "安装 NextCloud"

# 1. 安装 AppImage
mkdir -p "$NEXTCLOUD_INSTALL_DIR"
log "下载 NextCloud..."
download_file "$NEXTCLOUD_URL" "${NEXTCLOUD_INSTALL_DIR}/${NEXTCLOUD_FILE}"
chmod +x "${NEXTCLOUD_INSTALL_DIR}/${NEXTCLOUD_FILE}"

# 2. 下载图标
log "配置图标..."
ICON_URL="https://raw.githubusercontent.com/nextcloud/desktop/master/theme/colored/Nextcloud.png"
download_file "$ICON_URL" "${NEXTCLOUD_INSTALL_DIR}/nextcloud.png"

# 3. 创建桌面快捷方式
log "生成桌面快捷方式..."
DESKTOP_FILE="${NEXTCLOUD_INSTALL_DIR}/nextcloud.desktop"

# 检查是否有备份的 desktop 文件
BACKUP_DESKTOP="$GLOBAL_DATA_DIR/nextcloud/nextcloud.desktop"
if [ -f "$BACKUP_DESKTOP" ]; then
    log "恢复备份配置..."
    cp "$BACKUP_DESKTOP" "$DESKTOP_FILE"
    # 简单的 sed 修正路径
    sed -i "s|/home/[^/]*/|$HOME/|g" "$DESKTOP_FILE"
else
    # 使用模板生成
    install_template "nextcloud.desktop" "$DESKTOP_FILE" \
        "INSTALL_DIR=$NEXTCLOUD_INSTALL_DIR" \
        "EXEC_FILE=$NEXTCLOUD_FILE"
fi

# 安装菜单项
sudo desktop-file-install "$DESKTOP_FILE"

# [Fix] 使用标准化的桌面目录
cp "$DESKTOP_FILE" "$DESKTOP_DIR/" 2>/dev/null || true
print_info "桌面快捷方式已复制到: $DESKTOP_DIR"

# 4. 开机自启
mkdir -p "$HOME/.config/autostart"
cp "$DESKTOP_FILE" "$HOME/.config/autostart/" 2>/dev/null || true

print_success "NextCloud 安装完成"
