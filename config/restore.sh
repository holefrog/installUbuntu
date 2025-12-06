#!/bin/bash
# backup/restore.sh
# ---------------------------------------------------------
# 纯数据迁移脚本 (Data Migration Only)
# 安全原则：采用“白名单”模式，仅恢复 /home/$USER 下的数据
# ---------------------------------------------------------

set -e

# =================配置区域=================
# 备份存储根目录
BACKUP_ROOT="/media/$USER/Data/ubuntu_backups"

# 定义源路径与目标路径
# 注意：backup.sh 使用 rsync -R (相对路径)，所以备份内部结构是 home/$USER/...
BACKUP_SOURCE_PATH="home/$USER"
TARGET_RESTORE_PATH="$HOME"
# =========================================

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_msg() { echo -e "${BLUE}==> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_err() { echo -e "${RED}✗ $1${NC}"; }

# 1. 检查备份根目录
if [ ! -d "$BACKUP_ROOT" ]; then
    print_err "备份根目录不存在: $BACKUP_ROOT"
    print_err "请检查外部磁盘是否挂载到 /media/$USER/Data"
    exit 1
fi

# 2. 自动获取最新备份目录
LATEST_BACKUP=$(ls -td "$BACKUP_ROOT"/*/ 2>/dev/null | head -1)
if [ -z "$LATEST_BACKUP" ]; then
    print_err "未找到任何备份。"
    exit 1
fi

# 3. 检查备份中是否存在用户数据
SOURCE_DIR="${LATEST_BACKUP%/}/$BACKUP_SOURCE_PATH"

if [ ! -d "$SOURCE_DIR" ]; then
    print_err "最新备份中未找到当前用户的数据！"
    echo "  查找路径: $SOURCE_DIR"
    echo "  当前用户: $USER"
    echo "  可能原因: 备份是由其他用户创建的，或备份不完整。"
    exit 1
fi

echo -e "----------------------------------------------------"
echo -e "源备份目录: ${YELLOW}$SOURCE_DIR${NC}"
echo -e "目标恢复地: ${GREEN}$TARGET_RESTORE_PATH${NC}"
echo -e "----------------------------------------------------"
echo "此操作将仅恢复用户主目录下的数据（.ssh, programs, configs 等）。"
echo "系统文件（如 /etc, /boot, /var）将被完全忽略。"
echo -e "----------------------------------------------------"

# 4. 模式选择
echo "请选择:"
echo " 1) 模拟运行 (Dry-run) - 推荐初次使用"
echo " 2) 执行恢复"
read -p "请输入 [1/2]: " -r MODE

if [[ "$MODE" == "1" ]]; then
    print_msg "正在模拟数据差异..."
    # -n: 模拟, -v: 详细
    rsync -avn "$SOURCE_DIR/" "$TARGET_RESTORE_PATH/"
    print_success "模拟完成。以上文件将被恢复。"
    exit 0
elif [[ "$MODE" == "2" ]]; then
    print_msg "正在开始数据迁移..."
else
    echo "取消操作。"
    exit 1
fi

# 5. 执行数据恢复
# -a: 归档模式 (保留权限/时间等)
# -v: 详细输出
# 注意：不使用 --delete，防止误删新系统中已存在的文件
rsync -av "$SOURCE_DIR/" "$TARGET_RESTORE_PATH/"

# 6. 最后的权限保障
# 因为只恢复到 $HOME，通常不需要 sudo，但为了防止 rsync 保留了错误的 UID/GID
print_msg "正在确数据所有权..."
sudo chown -R "$USER:$USER" "$TARGET_RESTORE_PATH"

print_success "数据迁移完成！无需重启。"
print_success "请检查 ~/programs 或 ~/.ssh 等目录确认。"
