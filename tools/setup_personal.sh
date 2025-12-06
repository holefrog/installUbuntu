#!/bin/bash
# tools/setup-personal-config.sh - 增强版 (Fixed)
# ======================================================================================================
# 个人配置快速部署工具
# 
# 功能:
# 1. 从安全备份恢复真实配置文件
# 2. 自动生成 secrets.env
# 3. 验证配置完整性
# ======================================================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() { echo -e "${BLUE}==> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

# 确定路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# [Fix] 改进备份路径检测
# 优先检查环境变量 -> 当前目录下的 ubuntu_install_private -> 以前的硬编码路径
DEFAULT_BACKUP_NAME="ubuntu_install_private"
POSSIBLE_PATHS=(
    "${PRIVATE_BACKUP}"
    "$PWD/$DEFAULT_BACKUP_NAME"
    "$PROJECT_ROOT/../$DEFAULT_BACKUP_NAME"
    "/media/$USER/Data/$DEFAULT_BACKUP_NAME"
)

BACKUP_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
        BACKUP_DIR="$path"
        break
    fi
done

# 目标文件
SECRETS_FILE="$PROJECT_ROOT/config/secrets.env"
SECRETS_EXAMPLE="$PROJECT_ROOT/config/secrets.env.example"

print_msg "个人配置部署工具 v2.1"
echo

# ==============================
# 1. 检查备份目录
# ==============================
if [ -z "$BACKUP_DIR" ]; then
    print_warning "未自动发现备份目录。"
    read -p "请输入备份目录路径 (留空取消): " USER_INPUT_PATH
    if [ -n "$USER_INPUT_PATH" ] && [ -d "$USER_INPUT_PATH" ]; then
        BACKUP_DIR="$USER_INPUT_PATH"
    else
        print_error "无效的目录。"
        print_info "您可以手动将私有文件放入: $PWD/$DEFAULT_BACKUP_NAME"
        echo
        read -p "是否仅生成 secrets.env 模板并退出? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
             if [ ! -f "$SECRETS_FILE" ]; then
                cp "$SECRETS_EXAMPLE" "$SECRETS_FILE"
                print_success "已生成模板: $SECRETS_FILE"
             fi
             exit 0
        else
             exit 1
        fi
    fi
fi

PRIVATE_BACKUP="$BACKUP_DIR"
print_success "使用备份源: $PRIVATE_BACKUP"

# ==============================
# 2. 恢复 secrets.env
# ==============================
print_msg "配置 secrets.env..."

if [ -f "$PRIVATE_BACKUP/secrets.env" ]; then
    # 从备份恢复
    print_info "从备份恢复 secrets.env"
    cp "$PRIVATE_BACKUP/secrets.env" "$SECRETS_FILE"
    print_success "secrets.env 已恢复"
elif [ -f "$SECRETS_FILE" ]; then
    print_warning "secrets.env 已存在，保留现有配置"
else
    # 创建新配置
    print_info "创建新的 secrets.env（基于模板）"
    cp "$SECRETS_EXAMPLE" "$SECRETS_FILE"
    print_success "已创建: $SECRETS_FILE"
fi

# ==============================
# 3. 恢复 Aria2 配置
# ==============================
print_msg "恢复 Aria2 配置..."

ARIA2_DEST="$PROJECT_ROOT/data/aria2/aria2.conf"

if [ -f "$PRIVATE_BACKUP/aria2.conf" ]; then
    cp "$PRIVATE_BACKUP/aria2.conf" "$ARIA2_DEST"
    print_success "aria2.conf 已恢复"
    
    # 自动提取配置到 secrets.env
    if [ -f "$SECRETS_FILE" ]; then
        # 提取 RPC Secret
        RPC_SECRET=$(grep '^rpc-secret=' "$ARIA2_DEST" | cut -d'=' -f2)
        if [ -n "$RPC_SECRET" ]; then
            if command -v perl &>/dev/null; then
                perl -i -pe "s/ARIA2_RPC_SECRET=.*/ARIA2_RPC_SECRET=\"$RPC_SECRET\"/" "$SECRETS_FILE"
            else
                sed -i "s/ARIA2_RPC_SECRET=.*/ARIA2_RPC_SECRET=\"$RPC_SECRET\"/" "$SECRETS_FILE"
            fi
            print_success "已更新 ARIA2_RPC_SECRET"
        fi
    fi
else
    print_warning "未找到 aria2.conf"
fi

# ==============================
# 4. 恢复 OpenVPN 配置
# ==============================
print_msg "恢复 OpenVPN 配置..."

# [Fix] 智能查找 .ovpn 文件
FOUND_OVPN=$(find "$PRIVATE_BACKUP" -maxdepth 1 -name "*.ovpn" | head -n 1)

if [ -n "$FOUND_OVPN" ]; then
    OVPN_FILENAME=$(basename "$FOUND_OVPN")
    OPENVPN_DEST="$PROJECT_ROOT/data/openvpn/$OVPN_FILENAME"
    
    cp "$FOUND_OVPN" "$OPENVPN_DEST"
    chmod 600 "$OPENVPN_DEST"
    print_success "已恢复 VPN 配置: $OVPN_FILENAME"
    
    # 尝试更新 config.ini 中的 profile name
    PROFILE_NAME="${OVPN_FILENAME%.*}"
    if [ -f "$PROJECT_ROOT/scripts/config.ini" ]; then
        sed -i "s/OPENVPN_PROFILE_NAME=.*/OPENVPN_PROFILE_NAME=\"$PROFILE_NAME\"/" "$PROJECT_ROOT/scripts/config.ini"
        print_info "已更新 config.ini 中的 OPENVPN_PROFILE_NAME"
    fi
    
    # 自动提取配置到 secrets.env
    if [ -f "$SECRETS_FILE" ]; then
        VPN_SERVER=$(grep '^remote ' "$OPENVPN_DEST" | awk '{print $2}')
        if [ -n "$VPN_SERVER" ]; then
            sed -i "s/OPENVPN_SERVER=.*/OPENVPN_SERVER=\"$VPN_SERVER\"/" "$SECRETS_FILE"
            print_success "已更新 OPENVPN_SERVER"
        fi
    fi
else
    print_warning "备份中未找到 .ovpn 文件"
fi

# ==============================
# 5. 恢复其他文件
# ==============================
print_msg "恢复其他配置..."

# SSH 密钥
if [ -d "$PRIVATE_BACKUP/.ssh" ]; then
    print_info "恢复 SSH 密钥..."
    mkdir -p "$HOME/.ssh"
    cp -r "$PRIVATE_BACKUP/.ssh/"* "$HOME/.ssh/" 2>/dev/null || true
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/"* 2>/dev/null || true
    print_success "SSH 密钥已恢复"
fi

# Git 配置
if [ -f "$PRIVATE_BACKUP/.gitconfig" ]; then
    cp "$PRIVATE_BACKUP/.gitconfig" "$HOME/"
    print_success "Git 配置已恢复"
fi

# ==============================
# 6. 验证配置
# ==============================
print_msg "验证配置完整性..."

VALIDATION_PASSED=true

# 检查 secrets.env
if [ -f "$SECRETS_FILE" ]; then
    required_vars=(
        "ARIA2_RPC_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=.*CHANGE_ME" "$SECRETS_FILE" 2>/dev/null; then
            print_warning "$var 仍使用占位符"
            VALIDATION_PASSED=false
        fi
    done
fi

echo
if [ "$VALIDATION_PASSED" = true ]; then
    print_success "个人配置部署完成！"
else
    print_warning "配置部署完成，但请手动检查 secrets.env"
fi
