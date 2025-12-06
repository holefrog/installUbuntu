#!/bin/bash
# scripts/modules/00_prepare.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "系统准备检查"

# 更新软件源
print_message $YELLOW "正在更新软件包列表..."
sudo apt update

# 确保基础工具已安装
print_message $YELLOW "检查基础组件..."
sudo apt install -y gnome-software wget curl || true

print_success "系统准备就绪"
