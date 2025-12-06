#!/bin/bash
# scripts/modules/09_aria2.sh - 重构版
# ======================================================================================================
# Aria2 安装和配置脚本
# 版本: 3.3 - 移除 Service 文件中的二进制路径硬编码
# ======================================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "配置 Aria2"

# ==============================
# 1. 检查和安装 Aria2
# ==============================
if ! command_exists aria2c; then
    print_info "安装 Aria2..."
    sudo apt update
    sudo apt install -y aria2
else
    print_success "Aria2 已安装"
fi

# 获取版本和路径
ARIA2_VERSION=$(aria2c --version | head -n1 || echo "Unknown")
ARIA2_BIN=$(command -v aria2c)

print_info "Aria2 版本: $ARIA2_VERSION"
print_info "Aria2 路径: $ARIA2_BIN"

if [ -z "$ARIA2_BIN" ]; then
    print_error "无法找到 aria2c 可执行文件路径"
    exit 1
fi

# ==============================
# 2. 创建必需目录
# ==============================
print_info "创建配置目录..."

ARIA2_USER_CONFIG_DIR="${ARIA2_CONFIG_DIR:-$HOME/.config/aria2}"
ARIA2_DOWNLOAD_PATH="${ARIA2_DOWNLOAD_DIR:-$HOME/Downloads}"

mkdir -p "$ARIA2_USER_CONFIG_DIR"
mkdir -p "$ARIA2_DOWNLOAD_PATH"

print_success "目录已创建:"
print_info "  配置: $ARIA2_USER_CONFIG_DIR"
print_info "  下载: $ARIA2_DOWNLOAD_PATH"

# ==============================
# 3. 生成配置文件（使用模板）
# ==============================
print_info "生成 Aria2 配置文件..."

ARIA2_CONF_FILE="$ARIA2_USER_CONFIG_DIR/aria2.conf"
ARIA2_TEMPLATE="aria2/aria2.conf.template"

# 检查敏感配置是否已加载
if [ "$SECRETS_LOADED" != "true" ]; then
    print_error "未加载敏感配置 (secrets.env)"
    print_warning "请创建配置文件: cp config/secrets.env.example config/secrets.env"
    exit 1
fi

# 验证必需变量
required_vars=(
    "ARIA2_RPC_SECRET"
    "ARIA2_WEBDAV_USER"
    "ARIA2_WEBDAV_PASSWORD"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "缺少必需变量: $var"
        print_warning "请在 config/secrets.env 中配置"
        exit 1
    fi
done

# 使用模板引擎生成配置
if ! install_template "$ARIA2_TEMPLATE" "$ARIA2_CONF_FILE" \
    "ARIA2_CONFIG_DIR=$ARIA2_USER_CONFIG_DIR" \
    "ARIA2_DOWNLOAD_DIR=$ARIA2_DOWNLOAD_PATH" \
    "ARIA2_RPC_SECRET=$ARIA2_RPC_SECRET" \
    "ARIA2_WEBDAV_USER=$ARIA2_WEBDAV_USER" \
    "ARIA2_WEBDAV_PASSWORD=$ARIA2_WEBDAV_PASSWORD"; then
    print_error "配置文件生成失败"
    exit 1
fi

# ==============================
# 4. 创建必需文件
# ==============================
print_info "创建会话文件..."

ARIA2_SESSION_FILE="$ARIA2_USER_CONFIG_DIR/aria2.session"
ARIA2_DHT_FILE="$ARIA2_USER_CONFIG_DIR/dht.dat"

# 会话文件
if [ ! -f "$ARIA2_SESSION_FILE" ]; then
    touch "$ARIA2_SESSION_FILE"
    print_success "已创建: aria2.session"
else
    print_info "会话文件已存在"
fi

# DHT 路由表
if [ ! -f "$ARIA2_DHT_FILE" ]; then
    # 尝试从数据目录复制
    if [ -f "$GLOBAL_DATA_DIR/aria2/dht.dat" ]; then
        cp "$GLOBAL_DATA_DIR/aria2/dht.dat" "$ARIA2_DHT_FILE"
        print_success "已复制: dht.dat"
    else
        touch "$ARIA2_DHT_FILE"
        print_info "已创建空 DHT 文件（将在首次运行时自动填充）"
    fi
else
    print_info "DHT 文件已存在"
fi

# ==============================
# 5. 配置系统服务
# ==============================
print_info "配置 Aria2 为系统服务..."

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_USER_DIR/aria2c.service"
SERVICE_TEMPLATE="service/aria2c.service.template"

mkdir -p "$SYSTEMD_USER_DIR"

# 生成服务文件（使用模板）
# 将 @@ARIA2_CONF_FILE@@ 替换为配置路径
# 将 @@ARIA2_BIN@@ 替换为实际二进制路径
if ! install_template "$SERVICE_TEMPLATE" "$SERVICE_FILE" \
    "ARIA2_CONF_FILE=$ARIA2_CONF_FILE" \
    "ARIA2_BIN=$ARIA2_BIN"; then
    print_error "服务文件生成失败"
    exit 1
fi

chmod 644 "$SERVICE_FILE"
print_success "服务文件已创建: $SERVICE_FILE"

# 启动服务
if ! start_service "aria2c" true; then
    print_warning "服务启动失败，尝试手动启动..."
    
    # 手动测试配置
    if "$ARIA2_BIN" --conf-path="$ARIA2_CONF_FILE" --check-integrity=true --dry-run=true; then
        print_success "配置文件验证通过"
        
        # 尝试前台运行（调试用）
        print_info "尝试前台运行 Aria2..."
        timeout 5 "$ARIA2_BIN" --conf-path="$ARIA2_CONF_FILE" || true
    else
        print_error "配置文件验证失败，请检查配置"
        exit 1
    fi
fi

# ==============================
# 6. 验证安装
# ==============================
print_header "验证 Aria2 配置"

sleep 3

if systemctl --user is-active --quiet aria2c; then
    print_success "Aria2 服务运行正常"
    
    # 显示服务状态
    print_info "服务状态:"
    systemctl --user status aria2c --no-pager | head -n 10
    
    # 测试 RPC 连接
    print_info "测试 RPC 连接..."
    if command_exists curl; then
        RPC_URL="http://localhost:6800/jsonrpc"
        RPC_PAYLOAD='{"jsonrpc":"2.0","id":"test","method":"aria2.getVersion","params":["token:'$ARIA2_RPC_SECRET'"]}'
        
        if curl -s -X POST -d "$RPC_PAYLOAD" "$RPC_URL" | grep -q "result"; then
            print_success "RPC 连接正常"
        else
            print_warning "RPC 连接失败（可能需要稍等片刻）"
        fi
    fi
else
    print_error "Aria2 服务未运行"
    print_warning "尝试查看日志:"
    journalctl --user -u aria2c --no-pager -n 20
    exit 1
fi

# ==============================
# 7. 显示配置信息
# ==============================
print_header "Aria2 配置完成"

print_success "安装位置:"
print_info "  二进制文件: $ARIA2_BIN"
print_info "  配置文件: $ARIA2_CONF_FILE"
print_info "  会话文件: $ARIA2_SESSION_FILE"
print_info "  日志文件: $ARIA2_USER_CONFIG_DIR/aria2.log"
print_info "  下载目录: $ARIA2_DOWNLOAD_PATH"

print_success "RPC 配置:"
print_info "  监听地址: http://localhost:6800/jsonrpc"
print_info "  访问密钥: $ARIA2_RPC_SECRET"

print_success "Web 前端（推荐）:"
print_info "  AriaNg: https://ariang.mayswind.net/latest/"
print_info "  Webui: https://ziahamza.github.io/webui-aria2/"

print_success "常用命令:"
print_info "  启动服务: systemctl --user start aria2c"
print_info "  停止服务: systemctl --user stop aria2c"
print_info "  重启服务: systemctl --user restart aria2c"
print_info "  查看状态: systemctl --user status aria2c"
print_info "  查看日志: journalctl --user -u aria2c -f"

print_warning "注意事项:"
print_info "1. RPC 密钥已配置，请妥善保管"
print_info "2. 服务已设置为开机自启动"
print_info "3. 配置文件支持热重载（重启服务生效）"
print_info "4. 建议定期更新 BT Tracker 列表"

print_success "Aria2 配置完成！"
