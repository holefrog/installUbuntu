#!/bin/bash
# tools/backup-personal-config.sh
# 备份个人敏感配置到安全位置

set -e

BACKUP_DIR="/media/$USER/Data/ubuntu_install_private"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_TARGET="$BACKUP_DIR/backup_$TIMESTAMP"

mkdir -p "$BACKUP_TARGET"

echo "备份敏感配置到: $BACKUP_TARGET"

# 备份 Aria2
if [ -f "data/aria2/aria2.conf" ]; then
    cp data/aria2/aria2.conf "$BACKUP_TARGET/"
    echo "✓ Aria2 配置已备份"
fi

# 备份 OpenVPN
if [ -f "data/openvpn/AC3100.ovpn" ]; then
    cp data/openvpn/AC3100.ovpn "$BACKUP_TARGET/"
    echo "✓ OpenVPN 配置已备份"
fi

# 备份环境变量
if [ -f ".env" ]; then
    cp .env "$BACKUP_TARGET/"
    echo "✓ 环境变量已备份"
fi

# 创建符号链接到最新备份
rm -f "$BACKUP_DIR/latest"
ln -s "$BACKUP_TARGET" "$BACKUP_DIR/latest"

echo
echo "备份完成！"
echo "最新备份: $BACKUP_DIR/latest"
