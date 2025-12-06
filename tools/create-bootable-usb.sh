#!/bin/bash
# tools/create-bootable-usb.sh
# ======================================================================================================
# Ubuntu 24.04 自动安装 USB 制作工具
# 
# 功能:
# 1. 将 Ubuntu ISO 写入 USB
# 2. 注入 autoinstall 配置
# 3. 复制安装脚本到 USB
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
print_warning() { echo -e "${YELLOW}! $1${NC}"; }

print_header() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查必要工具
for tool in wget mkfs.vfat sgdisk; do
    if ! command -v $tool &> /dev/null; then
        print_error "缺少必要工具: $tool"
        print_msg "请运行: sudo apt install wget dosfstools gdisk"
        exit 1
    fi
done

print_header "Ubuntu 24.04 自动安装 USB 制作工具"

# 1. 获取 ISO 文件路径
echo -e "${YELLOW}请提供 Ubuntu 24.04 ISO 文件:${NC}"
read -p "ISO 文件路径 (或输入 download 自动下载): " ISO_PATH

if [ "$ISO_PATH" == "download" ]; then
    print_msg "正在下载 Ubuntu 24.04 LTS ISO..."
    ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"
    ISO_PATH="/tmp/ubuntu-24.04-desktop-amd64.iso"
    wget -O "$ISO_PATH" "$ISO_URL" || {
        print_error "下载失败"
        exit 1
    }
fi

if [ ! -f "$ISO_PATH" ]; then
    print_error "ISO 文件不存在: $ISO_PATH"
    exit 1
fi

print_success "ISO 文件: $ISO_PATH"

# 2. 选择 USB 设备
print_msg "检测到以下存储设备:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "disk|part"

echo
print_warning "警告: 所选设备的所有数据将被清除!"
read -p "请输入 USB 设备名称 (例如: sdc): " USB_DEVICE

# 验证设备
USB_PATH="/dev/$USB_DEVICE"
if [ ! -b "$USB_PATH" ]; then
    print_error "设备不存在: $USB_PATH"
    exit 1
fi

# 检查是否是系统盘
if mount | grep -q "^$USB_PATH"; then
    print_error "设备正在使用中，请先卸载"
    exit 1
fi

# 确认操作
echo
print_warning "即将格式化设备: $USB_PATH"
lsblk "$USB_PATH"
echo
read -p "确认继续? (输入 YES): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    print_msg "操作已取消"
    exit 0
fi

# 3. 准备 USB
print_header "准备 USB 设备"

print_msg "卸载所有分区..."
for partition in ${USB_PATH}*; do
    if [ "$partition" != "$USB_PATH" ]; then
        umount "$partition" 2>/dev/null || true
    fi
done

print_msg "清除分区表..."
sgdisk --zap-all "$USB_PATH"
sleep 2

print_msg "创建 GPT 分区表..."
sgdisk --new=1:0:0 --typecode=1:ef00 "$USB_PATH"
sleep 2

print_msg "格式化为 FAT32..."
mkfs.vfat -F 32 -n "UBUNTU2404" "${USB_PATH}1"
sleep 2

print_success "USB 设备准备完成"

# 4. 挂载和复制
print_header "复制文件到 USB"

MOUNT_POINT="/mnt/usb_install"
mkdir -p "$MOUNT_POINT"

print_msg "挂载 USB..."
mount "${USB_PATH}1" "$MOUNT_POINT"

print_msg "挂载 ISO..."
ISO_MOUNT="/mnt/ubuntu_iso"
mkdir -p "$ISO_MOUNT"
mount -o loop "$ISO_PATH" "$ISO_MOUNT"

print_msg "复制 ISO 内容..."
rsync -ah --info=progress2 "$ISO_MOUNT/" "$MOUNT_POINT/"

print_msg "卸载 ISO..."
umount "$ISO_MOUNT"
rmdir "$ISO_MOUNT"

print_success "ISO 内容已复制"

# 5. 注入 autoinstall 配置
print_header "配置自动安装"

AUTOINSTALL_DIR="$MOUNT_POINT/autoinstall"
mkdir -p "$AUTOINSTALL_DIR"

# 复制配置文件
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$SCRIPT_ROOT/autoinstall/user-data" ]; then
    cp "$SCRIPT_ROOT/autoinstall/user-data" "$AUTOINSTALL_DIR/"
    touch "$AUTOINSTALL_DIR/meta-data"
    print_success "自动安装配置已添加"
else
    print_warning "未找到 autoinstall 配置，将创建基本配置"
    
    cat > "$AUTOINSTALL_DIR/user-data" << 'EOF'
#cloud-config
autoinstall:
  version: 1
  interactive-sections: []
  locale: en_US.UTF-8
  keyboard:
    layout: us
  timezone: Asia/Shanghai
  identity:
    hostname: ubuntu
    username: ubuntu
    password: "$6$rounds=4096$salt$password_hash"
  ssh:
    install-server: true
    allow-pw: true
  storage:
    layout:
      name: lvm
EOF
    
    touch "$AUTOINSTALL_DIR/meta-data"
fi

# 6. 复制安装脚本
print_msg "复制安装脚本..."
if [ -d "$SCRIPT_ROOT/scripts" ]; then
    mkdir -p "$MOUNT_POINT/ubuntu-install"
    rsync -ah "$SCRIPT_ROOT/" "$MOUNT_POINT/ubuntu-install/" \
        --exclude='.git' \
        --exclude='logs' \
        --exclude='*.log'
    print_success "安装脚本已复制"
fi

# 7. 修改启动配置
print_msg "配置启动参数..."
GRUB_CFG="$MOUNT_POINT/boot/grub/grub.cfg"

if [ -f "$GRUB_CFG" ]; then
    # 备份原始配置
    cp "$GRUB_CFG" "${GRUB_CFG}.bak"
    
    # 添加自动安装选项
    sed -i '/menuentry.*Try or Install Ubuntu/a\
menuentry "Autoinstall Ubuntu 24.04" {\
    set gfxpayload=keep\
    linux   /casper/vmlinuz autoinstall ds=nocloud\\;s=/cdrom/autoinstall/ ---\
    initrd  /casper/initrd\
}' "$GRUB_CFG"
    
    print_success "启动配置已修改"
fi

# 8. 清理和卸载
print_header "完成"

sync
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

print_success "自动安装 USB 制作完成!"
echo
print_msg "USB 设备: $USB_PATH"
print_msg "分区: ${USB_PATH}1"
echo
print_warning "使用说明:"
print_msg "1. 插入 USB 到目标计算机"
print_msg "2. 从 USB 启动"
print_msg "3. 选择 'Autoinstall Ubuntu 24.04'"
print_msg "4. 系统将自动安装"
print_msg "5. 安装完成后首次登录会提示运行配置脚本"
echo
print_warning "注意:"
print_msg "- 确保目标机器已连接网络"
print_msg "- 安装前请备份重要数据"
print_msg "- 编辑 autoinstall/user-data 自定义安装选项"
