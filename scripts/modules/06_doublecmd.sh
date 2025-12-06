#!/bin/bash
# scripts/modules/06_doublecmd.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

DOWNLOAD_URL="${DC_BASE_URL}/${DC_FILE_NAME}"
INSTALL_DIR="${INSTALL_PROGRAMS_DIR}/doublecmd"

print_header "安装 Double Commander"

# 下载与解压
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    download_file "$DOWNLOAD_URL" "$DC_FILE_NAME"
    log "正在解压..."
    tar -xf "$DC_FILE_NAME" -C "$INSTALL_DIR" --strip-components=1
    rm -f "$DC_FILE_NAME"
fi

# 配置 Desktop 文件
log "创建快捷方式..."
DESKTOP_DEST="${INSTALL_DIR}/doublecmd.desktop"

# 使用模板生成
# update: 明确使用 .template 后缀
install_template "doublecmd.desktop.template" "$DESKTOP_DEST" "INSTALL_DIR=$INSTALL_DIR"

# 安装到系统菜单
sudo desktop-file-install "$DESKTOP_DEST"

print_success "Double Commander 安装完成"
