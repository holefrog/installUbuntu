#!/bin/bash
# backup/local_backup.sh
# ---------------------------------------------------------
# 本地备份脚本
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 尝试引用 setup 下的 common.sh 以保持风格一致 (可选)
COMMON_LIB="$SCRIPT_DIR/../setup/common.sh"
if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    # 简单的回退定义
    print_message() { echo -e "$1$2\033[0m"; }
    GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'
    print_header() { echo "=== $1 ==="; }
    print_success() { echo "Done: $1"; }
fi

# 配置
BACKUP_ROOT="/media/$USER/Data/ubuntu_backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TARGET_DIR="$BACKUP_ROOT/$TIMESTAMP"
CONFIG_FILE="$SCRIPT_DIR/backup.ini"

print_header "开始执行备份"

# 检查挂载点
if [ ! -d "/media/$USER/Data" ]; then
    print_message $RED "错误: 未找到数据盘挂载点 /media/$USER/Data"
    # 可选: 退出或备份到本地
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件丢失: $CONFIG_FILE"
    exit 1
fi

mkdir -p "$TARGET_DIR"

while IFS= read -r path || [ -n "$path" ]; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue
    path=$(echo "$path" | xargs)
    
    # 动态展开 ~
    real_path=$(eval echo "$path")
    
    if [ -e "$real_path" ]; then
        print_message $BLUE "Backing up: $real_path"
        rsync -aR "$real_path" "$TARGET_DIR/"
    fi
done < "$CONFIG_FILE"

cp "$CONFIG_FILE" "$TARGET_DIR/"
print_success "备份完成: $TARGET_DIR"
