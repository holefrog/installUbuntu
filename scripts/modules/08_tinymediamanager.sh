#!/bin/bash
# scripts/modules/08_tinymediamanager.sh
# ======================================================================================================
# tinyMediaManager 安装脚本
# 一个强大的媒体库管理工具，支持电影和电视剧的元数据管理
# ======================================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "安装 tinyMediaManager"

# 检查 Java 环境
print_message $BLUE "检查 Java 运行环境..."
if ! command -v java &> /dev/null; then
    # 使用 config.ini 中的变量
    JAVA_PKG="${JAVA_PACKAGE:-openjdk-21-jre}"
    print_warning "未检测到 Java，正在安装 $JAVA_PKG..."
    sudo apt update
    sudo apt install -y "$JAVA_PKG"
else
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    print_message $GREEN "已安装 Java 版本: $JAVA_VERSION"
fi

# 创建安装目录
mkdir -p "$TMM_INSTALL_DIR"

# 下载 tinyMediaManager
print_message $BLUE "正在下载 tinyMediaManager ${TMM_VERSION}..."
download_file "$TMM_URL" "/tmp/${TMM_FILE}"

# 解压
# [Fix] 使用 -xf 让 tar 自动检测格式 (兼容 .tar.gz 和 .tar.xz)
print_message $BLUE "正在解压..."
tar -xf "/tmp/${TMM_FILE}" -C "$TMM_INSTALL_DIR" --strip-components=1
rm -f "/tmp/${TMM_FILE}"
print_success "解压完成"

# 赋予执行权限
chmod +x "${TMM_INSTALL_DIR}/tinyMediaManager"
chmod +x "${TMM_INSTALL_DIR}/"*.sh 2>/dev/null || true

# 创建启动脚本
print_message $BLUE "创建启动脚本..."
cat > "${TMM_INSTALL_DIR}/tmm.sh" << 'EOF'
#!/bin/bash
# tinyMediaManager 启动脚本

cd "$(dirname "$0")"
./tinyMediaManager "$@"
EOF

chmod +x "${TMM_INSTALL_DIR}/tmm.sh"

# 下载图标（如果不存在）
if [ ! -f "${TMM_INSTALL_DIR}/tmm.png" ]; then
    print_message $BLUE "正在下载应用图标..."
    ICON_URL="https://www.tinymediamanager.org/images/icon.png"
    download_file "$ICON_URL" "${TMM_INSTALL_DIR}/tmm.png" || {
        print_warning "图标下载失败，将使用默认图标"
        touch "${TMM_INSTALL_DIR}/tmm.png"
    }
fi

# 创建桌面快捷方式
print_message $BLUE "创建桌面快捷方式..."
DESKTOP_FILE="${TMM_INSTALL_DIR}/tinymediamanager.desktop"

# 使用模板生成
install_template "tmm.desktop.template" "$DESKTOP_FILE" \
    "INSTALL_DIR=$TMM_INSTALL_DIR"

# 验证并安装桌面文件
sudo desktop-file-validate "$DESKTOP_FILE" || print_warning "桌面文件验证失败，但继续安装"
sudo desktop-file-install "$DESKTOP_FILE"

# 复制到桌面和应用程序菜单
# 使用标准化的桌面目录
cp "$DESKTOP_FILE" "$DESKTOP_DIR/" 2>/dev/null || true
cp "$DESKTOP_FILE" "$HOME/.local/share/applications/" 2>/dev/null || true
chmod +x "$DESKTOP_DIR/tinymediamanager.desktop" 2>/dev/null || true

print_success "tinyMediaManager 桌面快捷方式已创建"

# 创建数据目录
print_message $BLUE "创建数据目录..."
mkdir -p "$HOME/.tinyMediaManager"
mkdir -p "$HOME/Videos/Movies"
mkdir -p "$HOME/Videos/TV Shows"
print_success "数据目录已创建"

# 配置信息
print_header "tinyMediaManager 配置信息"
print_message $GREEN "安装位置: ${TMM_INSTALL_DIR}"
print_message $GREEN "数据目录: $HOME/.tinyMediaManager"
print_message $GREEN "默认媒体库:"
print_message $GREEN "  - 电影: $HOME/Videos/Movies"
print_message $GREEN "  - 电视剧: $HOME/Videos/TV Shows"

# 创建快速启动别名
print_message $BLUE "添加命令行别名..."
if ! grep -q "alias tmm=" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# tinyMediaManager quick launch" >> "$HOME/.bashrc"
    echo "alias tmm='${TMM_INSTALL_DIR}/tmm.sh &'" >> "$HOME/.bashrc"
    print_success "已添加命令行别名 'tmm'"
fi

print_success "tinyMediaManager 安装完成"

# 询问是否立即启动
print_message $YELLOW ""
read -p "是否立即启动 tinyMediaManager? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message $BLUE "正在启动 tinyMediaManager..."
    "${TMM_INSTALL_DIR}/tmm.sh" &
    sleep 2
    print_success "tinyMediaManager 已启动"
fi
