#!/bin/bash
# scripts/modules/10_openvpn.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "配置 OpenVPN"

# 1. 安装依赖
print_message $BLUE "安装 GNOME 支持..."
sudo apt install -y network-manager-openvpn-gnome

# 2. 部署配置文件
# 从 config.ini 获取变量，如果未定义则使用默认值
if [ -z "$OPENVPN_CONFIG_DIR" ]; then
    OPENVPN_CONFIG_DIR="$HOME/programs/openvpn"
fi

# [Fix] 获取 Profile 名称
VPN_PROFILE="${OPENVPN_PROFILE_NAME:-VPN_Profile}"

print_message $BLUE "部署配置文件到: $OPENVPN_CONFIG_DIR"
mkdir -p "$OPENVPN_CONFIG_DIR"

# 源文件可能是任何 .ovpn 文件，但我们优先寻找匹配 PROFILE_NAME 的
SRC_OVPN="$GLOBAL_DATA_DIR/openvpn/${VPN_PROFILE}.ovpn"
TARGET_OVPN="$OPENVPN_CONFIG_DIR/${VPN_PROFILE}.ovpn"

if [ -f "$SRC_OVPN" ]; then
    cp "$SRC_OVPN" "$TARGET_OVPN"
    chmod 600 "$TARGET_OVPN"
    print_success "OpenVPN 配置文件已部署: $(basename "$TARGET_OVPN")"
else
    # 尝试寻找目录下唯一的 .ovpn 文件
    FOUND_OVPN=$(find "$GLOBAL_DATA_DIR/openvpn" -name "*.ovpn" | head -n 1)
    if [ -n "$FOUND_OVPN" ]; then
        print_warning "未找到 ${VPN_PROFILE}.ovpn，但找到了 $(basename "$FOUND_OVPN")"
        cp "$FOUND_OVPN" "$TARGET_OVPN"
        chmod 600 "$TARGET_OVPN"
        print_success "已部署替代配置文件"
    else
        print_warning "未找到源配置文件: $SRC_OVPN"
    fi
fi

# 3. 部署桌面快捷方式
# 将桌面文件名称小写化
OPENVPN_DESKTOP_FILE="${VPN_PROFILE,,}.desktop"
SRC_VPN_DESKTOP="$GLOBAL_DATA_DIR/openvpn/$OPENVPN_DESKTOP_FILE"

if [ -f "$SRC_VPN_DESKTOP" ]; then
    print_message $BLUE "创建桌面快捷方式..."
    TARGET_DESKTOP="$DESKTOP_DIR/$OPENVPN_DESKTOP_FILE"
    
    cp "$SRC_VPN_DESKTOP" "$TARGET_DESKTOP"
    
    # 修正路径 (确保指向正确的配置文件位置)
    sed -i "s|/home/[^/]*/|$HOME/|g" "$TARGET_DESKTOP"
    chmod +x "$TARGET_DESKTOP"
    
    print_success "OpenVPN 快捷方式已创建"
else
    # 如果找不到特定的桌面文件，尝试使用模板
    TEMPLATE_FILE="openvpn.desktop.template"
    if [ -f "$TEMPLATES_DIR/desktop-files/$TEMPLATE_FILE" ] || [ -f "$GLOBAL_DATA_DIR/openvpn/$TEMPLATE_FILE" ]; then
        print_info "使用模板生成桌面文件..."
        TARGET_DESKTOP="$DESKTOP_DIR/$OPENVPN_DESKTOP_FILE"
        
        install_template "$TEMPLATE_FILE" "$TARGET_DESKTOP" \
            "PROFILE_NAME=$VPN_PROFILE" \
            "CONFIG_FILE=$TARGET_OVPN"
            
        chmod +x "$TARGET_DESKTOP"
        print_success "OpenVPN 快捷方式已生成"
    else
        print_warning "未找到 OpenVPN 桌面文件或模板"
    fi
fi

print_success "OpenVPN 配置完成"
