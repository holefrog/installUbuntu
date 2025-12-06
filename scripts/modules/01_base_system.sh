#!/bin/bash
# scripts/modules/01_base_system.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header "基础系统设置"

# 1. 修改 /etc/hosts
print_message $BLUE "配置 /etc/hosts..."
HOSTS_FILE="/etc/hosts"

if [ -n "$HOSTS_BLOCKLIST" ]; then
    for entry in "${HOSTS_BLOCKLIST[@]}"; do
        # 处理转义字符
        expanded_entry=$(echo -e "$entry")
        append_line_if_not_exists "$expanded_entry" "$HOSTS_FILE" "sudo"
    done
fi

# 2. 修改 ~/.bashrc
print_message $BLUE "配置 ~/.bashrc..."
BASHRC_FILE="$HOME/.bashrc"

if [ -n "$SHELL_ALIASES" ]; then
    for alias_line in "${SHELL_ALIASES[@]}"; do
        append_line_if_not_exists "$alias_line" "$BASHRC_FILE"
    done
fi

# 尝试应用更改
source "$BASHRC_FILE" || true

print_success "基础系统设置完成"
