#!/bin/bash
# scripts/main.sh
# ======================================================================================================
# Ubuntu 24.04 LTS 主安装脚本
# 版本: 2.1 (Fixed)
# 最后更新: 2024-12-05
# ======================================================================================================

set -e
set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 确定脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 引入公共函数库
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo -e "${RED}[ERROR] 找不到核心库: $SCRIPT_DIR/common.sh${NC}"
    exit 1
fi

# ==============================
# 初始化
# ==============================
print_header "Ubuntu 24.04 LTS 自动安装程序"

# [Fix] 刷新并保持 Sudo 权限
if sudo -v; then
    # 在后台循环更新 sudo 时间戳，防止长时间安装过程中 sudo 超时
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    print_success "Sudo 权限检查通过"
else
    print_error "无法获取 sudo 权限，请使用具有 sudo 权限的用户运行"
    exit 1
fi

# 创建日志目录
mkdir -p "$LOG_DIR"

# 启用日志记录
if [ "$ENABLE_LOGGING" = true ]; then
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    print_success "日志记录已启用: $LOG_FILE"
fi

# 显示环境信息
print_message $BLUE "运行环境:"
print_message $BLUE "  项目根目录: $PROJECT_ROOT"
print_message $BLUE "  脚本目录: $SCRIPT_DIR"
print_message $BLUE "  数据目录: $GLOBAL_DATA_DIR"
print_message $BLUE "  桌面目录: $DESKTOP_DIR" 
print_message $BLUE "  配置文件: $SCRIPT_DIR/config.ini"
print_message $BLUE "  日志文件: $LOG_FILE"
print_message $BLUE "  当前用户: $USER"
print_message $BLUE "  系统版本: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"

# ==============================
# 安装步骤定义
# ==============================
INSTALL_MODULES=(
    "modules/00_prepare.sh:系统准备检查"
    "modules/01_base_system.sh:基础系统设置"
    "modules/02_remove_snap.sh:移除 Snap"
    "modules/03_apt_packages.sh:安装 APT 软件包"
    "modules/04_deb_packages.sh:安装 DEB 软件包"
    "modules/05_firefox.sh:安装 Firefox (PPA)"
    "modules/06_doublecmd.sh:安装 Double Commander"
    "modules/07_nextcloud.sh:安装 NextCloud"
    "modules/08_tinymediamanager.sh:安装 tinyMediaManager"
    "modules/09_aria2.sh:配置 Aria2"
    "modules/10_openvpn.sh:配置 OpenVPN"
    "modules/11_rime.sh:安装 Rime 输入法"
)

# ==============================
# 显示安装计划
# ==============================
print_header "安装计划"
echo "将按以下顺序执行 ${#INSTALL_MODULES[@]} 个模块:"
echo

step_num=1
for module in "${INSTALL_MODULES[@]}"; do
    description="${module##*:}"
    printf "${BLUE}[%2d]${NC} %s\n" "$step_num" "$description"
    ((step_num++))
done

echo
print_warning "此过程可能需要 30-60 分钟，取决于网络速度。"
print_warning "某些步骤需要输入密码或确认操作。"

# 询问是否继续
echo
read -p "$(echo -e ${YELLOW}是否继续安装? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_msg "安装已取消"
    exit 0
fi

# ==============================
# 执行安装模块
# ==============================
START_TIME=$(date +%s)
FAILED_MODULES=()
SKIPPED_MODULES=()
SUCCESS_COUNT=0

print_header "开始执行安装"

for module in "${INSTALL_MODULES[@]}"; do
    # 解析模块信息
    module_path="${module%%:*}"
    module_desc="${module##*:}"
    full_path="$SCRIPT_DIR/$module_path"
    
    # 显示当前步骤
    print_header "[$((SUCCESS_COUNT + 1))/${#INSTALL_MODULES[@]}] $module_desc"
    
    # 检查模块文件是否存在
    if [ ! -f "$full_path" ]; then
        print_error "找不到模块: $full_path"
        FAILED_MODULES+=("$module_desc")
        
        # 询问是否继续
        read -p "$(echo -e ${YELLOW}是否跳过此模块继续? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "安装中止"
            exit 1
        fi
        SKIPPED_MODULES+=("$module_desc")
        continue
    fi
    
    # 赋予执行权限
    chmod +x "$full_path"
    
    # 执行模块
    if [ "$DRY_RUN" = true ]; then
        print_warning "[DRY RUN] 模拟执行: $module_desc"
        sleep 1
        ((SUCCESS_COUNT++))
        continue
    fi
    
    # 实际执行
    if bash "$full_path"; then
        print_success "模块完成: $module_desc"
        ((SUCCESS_COUNT++))
    else
        EXIT_CODE=$?
        print_error "模块失败: $module_desc (退出码: $EXIT_CODE)"
        FAILED_MODULES+=("$module_desc")
        
        # 询问是否继续
        read -p "$(echo -e ${YELLOW}是否继续下一个模块? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "安装中止"
            exit 1
        fi
    fi
    
    # 模块间短暂延迟
    sleep 2
done

# ==============================
# 安装完成总结
# ==============================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "安装完成"

echo
print_message $GREEN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message $GREEN "   安装统计"
print_message $GREEN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message $GREEN "✓ 成功完成: $SUCCESS_COUNT 个模块"
print_message $GREEN "✗ 失败: ${#FAILED_MODULES[@]} 个模块"
print_message $GREEN "⊘ 跳过: ${#SKIPPED_MODULES[@]} 个模块"
print_message $GREEN "⏱ 总耗时: ${MINUTES} 分 ${SECONDS} 秒"
print_message $GREEN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 显示失败的模块
if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
    echo
    print_warning "以下模块执行失败:"
    for failed in "${FAILED_MODULES[@]}"; do
        print_message $RED "  ✗ $failed"
    done
fi

# 显示跳过的模块
if [ ${#SKIPPED_MODULES[@]} -gt 0 ]; then
    echo
    print_warning "以下模块被跳过:"
    for skipped in "${SKIPPED_MODULES[@]}"; do
        print_message $YELLOW "  ⊘ $skipped"
    done
fi

# ==============================
# 后续操作建议
# ==============================
echo
print_header "后续操作建议"

print_message $YELLOW "1. 重启系统"
print_message $BLUE "   某些更改需要重启才能生效（特别是输入法）"
print_message $BLUE "   命令: sudo reboot"

print_message $YELLOW "2. 配置输入法"
print_message $BLUE "   设置 → 地区和语言 → 管理已安装的语言"
print_message $BLUE "   确保输入法系统为 IBus"
print_message $BLUE "   添加输入源: Chinese (Rime)"

print_message $YELLOW "3. 安装 GNOME 扩展"
print_message $BLUE "   打开扩展管理器，搜索并安装:"
print_message $BLUE "   - Vitals (系统监控)"
print_message $BLUE "   - OpenWeather (天气)"
print_message $BLUE "   - Screenshot Tool (截图)"
print_message $BLUE "   - Clipboard Indicator (剪贴板)"

print_message $YELLOW "4. 配置应用程序"
print_message $BLUE "   NextCloud: 输入服务器地址并登录"
print_message $BLUE "   Aria2: 已自动配置为系统服务"
print_message $BLUE "   tinyMediaManager: 添加媒体库文件夹"

print_message $YELLOW "5. 检查日志"
print_message $BLUE "   完整日志: $LOG_FILE"
print_message $BLUE "   系统日志: journalctl -xe"

# ==============================
# 自动重启选项
# ==============================
echo
if [ "$AUTO_REBOOT" = true ]; then
    print_warning "将在 10 秒后自动重启..."
    sleep 10
    sudo reboot
else
    read -p "$(echo -e ${YELLOW}是否立即重启系统? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_msg "正在重启..."
        sudo reboot
    else
        print_success "安装完成！请稍后手动重启系统。"
    fi
fi

# 标记安装完成
touch "$HOME/.ubuntu_install_complete"

exit 0
