#!/bin/bash
# scripts/common.sh - 增强版 (Fixed)
# ======================================================================================================
# 公共函数库 - 包含统一的模板引擎和配置管理
# 版本: 3.1
# ======================================================================================================

set -e
set -o pipefail

# ==============================
# 错误处理
# ==============================
handle_error() {
    local exit_code=$?
    local line_number=$1
    local script_name="${BASH_SOURCE[1]}"
    echo
    echo -e "\033[0;31m[ERROR] 脚本执行失败！\033[0m"
    echo -e "\033[0;31m出错模块: $script_name\033[0m"
    echo -e "\033[0;31m出错行号: $line_number\033[0m"
    echo -e "\033[0;31m退出代码: $exit_code\033[0m"
    exit $exit_code
}
trap 'handle_error $LINENO' ERR

# ==============================
# 颜色定义
# ==============================
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==============================
# 路径与配置加载
# ==============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="$SCRIPT_DIR/config.ini"
SECRETS_FILE="$PROJECT_ROOT/config/secrets.env"
SECRETS_EXAMPLE="$PROJECT_ROOT/config/secrets.env.example"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED}[ERROR] 找不到配置文件: $CONFIG_FILE${NC}"
    exit 1
fi

# 加载敏感配置（如果存在）
if [ -f "$SECRETS_FILE" ]; then
    echo -e "${GREEN}[INFO] 加载个人配置: $SECRETS_FILE${NC}"
    source "$SECRETS_FILE"
    SECRETS_LOADED=true
else
    echo -e "${YELLOW}[WARN] 未找到个人配置，将使用默认值${NC}"
    echo -e "${YELLOW}[HINT] 创建配置: cp $SECRETS_EXAMPLE $SECRETS_FILE${NC}"
    SECRETS_LOADED=false
fi

# ==============================
# 系统路径标准化 (FIX)
# ==============================
detect_system_paths() {
    # 如果系统安装了 xdg-user-dirs，使用它来获取正确的路径
    if command -v xdg-user-dir &>/dev/null; then
        DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
        DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
        DOCUMENTS_DIR="$(xdg-user-dir DOCUMENTS)"
    else
        # 回退到默认英语路径
        DESKTOP_DIR="$HOME/Desktop"
        DOWNLOAD_DIR="$HOME/Downloads"
        DOCUMENTS_DIR="$HOME/Documents"
    fi
    
    # 确保目录存在
    mkdir -p "$DESKTOP_DIR" "$DOWNLOAD_DIR"
}

# 初始化系统路径
detect_system_paths

# 数据目录
GLOBAL_DATA_DIR="$PROJECT_ROOT/${DATA_DIR_NAME:-data}"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# ==============================
# 基础打印函数
# ==============================
print_message() {
    local color="$1"
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_success() { print_message "$GREEN" "✓ $1"; }
print_error() { print_message "$RED" "✗ $1"; }
print_warning() { print_message "$YELLOW" "⚠ $1"; }
print_info() { print_message "$CYAN" "ℹ $1"; }

# 兼容别名
error() { print_error "$1"; exit 1; }
log() { print_info "$1"; }

# ==============================
# 🔥 核心：统一的模板引擎
# ==============================

# 转义 sed 特殊字符
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g' -e 's/$/\\/'
}

# 验证模板变量
validate_template_vars() {
    local template_file="$1"
    shift
    local vars=("$@")
    
    # 提取模板中所有占位符
    local placeholders=$(grep -oP '@@\K[A-Z_]+(?=@@)' "$template_file" 2>/dev/null || true)
    
    if [ -z "$placeholders" ]; then
        return 0
    fi
    
    # 检查是否所有占位符都有对应的变量
    local missing=()
    for placeholder in $placeholders; do
        local found=false
        for var in "${vars[@]}"; do
            local key="${var%%=*}"
            if [ "$key" == "$placeholder" ]; then
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            # 检查是否是环境变量
            if [ -z "${!placeholder}" ]; then
                missing+=("$placeholder")
            fi
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "模板缺少必需变量: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# 🔥 主模板处理函数
install_template() {
    local template_name="$1"
    local dest_path="$2"
    shift 2
    local replacements=("$@")
    
    # 1. 查找模板文件
    local template_path=""
    
    # 尝试多个位置
    for search_dir in "$TEMPLATES_DIR" "$GLOBAL_DATA_DIR" "$SCRIPT_DIR/templates"; do
        if [ -f "$search_dir/$template_name" ]; then
            template_path="$search_dir/$template_name"
            break
        fi
        
        # 尝试在子目录中查找
        if [ -f "$search_dir/desktop-files/$template_name" ]; then
            template_path="$search_dir/desktop-files/$template_name"
            break
        fi
    done
    
    # 检查数据目录中的对应位置
    local relative_dir=$(dirname "$template_name")
    if [ -f "$GLOBAL_DATA_DIR/$relative_dir/$template_name" ]; then
        template_path="$GLOBAL_DATA_DIR/$relative_dir/$template_name"
    fi
    
    if [ -z "$template_path" ] || [ ! -f "$template_path" ]; then
        print_error "找不到模板: $template_name"
        print_info "已搜索路径:"
        print_info "  - $TEMPLATES_DIR"
        print_info "  - $GLOBAL_DATA_DIR"
        return 1
    fi
    
    # 2. 验证模板变量
    if ! validate_template_vars "$template_path" "${replacements[@]}"; then
        print_warning "模板验证失败，但继续处理"
    fi
    
    # 3. 创建目标目录
    local dest_dir=$(dirname "$dest_path")
    mkdir -p "$dest_dir"
    
    # 4. 复制模板
    cp "$template_path" "$dest_path"
    print_info "已复制模板: $(basename "$template_name") -> $dest_path"
    
    # 5. 替换占位符
    local replaced_count=0
    
    # 方法 A: 使用提供的键值对
    for pair in "${replacements[@]}"; do
        local key="${pair%%=*}"
        local value="${pair#*=}"
        
        if [ -n "$value" ]; then
            # 使用 Perl 进行更安全的替换（处理特殊字符）
            if command -v perl &>/dev/null; then
                perl -i -pe "s/\@\@${key}\@\@/${value}/g" "$dest_path"
            else
                # 回退到 sed
                local value_escaped=$(escape_sed "$value")
                sed -i "s|@@${key}@@|${value_escaped}|g" "$dest_path"
            fi
            ((replaced_count++))
        fi
    done
    
    # 方法 B: 自动从环境变量替换
    local placeholders=$(grep -oP '@@\K[A-Z_]+(?=@@)' "$dest_path" 2>/dev/null || true)
    
    for placeholder in $placeholders; do
        # 检查是否已在 replacements 中处理
        local already_replaced=false
        for pair in "${replacements[@]}"; do
            if [ "${pair%%=*}" == "$placeholder" ]; then
                already_replaced=true
                break
            fi
        done
        
        if [ "$already_replaced" = true ]; then
            continue
        fi
        
        # 从环境变量获取值
        local env_value="${!placeholder}"
        
        if [ -n "$env_value" ]; then
            if command -v perl &>/dev/null; then
                perl -i -pe "s/\@\@${placeholder}\@\@/${env_value}/g" "$dest_path"
            else
                local value_escaped=$(escape_sed "$env_value")
                sed -i "s|@@${placeholder}@@|${value_escaped}|g" "$dest_path"
            fi
            ((replaced_count++))
        else
            print_warning "未找到变量: $placeholder"
        fi
    done
    
    # 6. 检查是否还有未替换的占位符
    local remaining=$(grep -oP '@@\K[A-Z_]+(?=@@)' "$dest_path" 2>/dev/null | wc -l)
    
    if [ "$remaining" -gt 0 ]; then
        print_warning "配置文件中仍有 $remaining 个未替换的占位符"
        grep -oP '@@\K[A-Z_]+(?=@@)' "$dest_path" 2>/dev/null | sort -u | while read var; do
            print_warning "  - @@${var}@@"
        done
    fi
    
    # 7. 设置权限
    set_file_permissions "$dest_path"
    
    print_success "模板已生成: $(basename "$dest_path") (替换了 $replaced_count 个变量)"
    return 0
}

# 设置文件权限
set_file_permissions() {
    local file="$1"
    
    # 系统配置文件
    if [[ "$file" == "/etc/"* ]] || [[ "$file" == "/usr/"* ]]; then
        chmod 644 "$file" 2>/dev/null || sudo chmod 644 "$file"
        return
    fi
    
    # 可执行文件
    if [[ "$file" == *.sh ]] || [[ "$file" == */bin/* ]] || [[ "$file" == *"/doublecmd" ]]; then
        chmod +x "$file" 2>/dev/null || true
        return
    fi
    
    # .desktop 文件
    if [[ "$file" == *.desktop ]]; then
        chmod 644 "$file" 2>/dev/null || true
        return
    fi
    
    # 私密文件（如 OpenVPN 配置）
    if [[ "$file" == *.ovpn ]] || [[ "$file" == *".ssh/"* ]] || [[ "$file" == *.key ]]; then
        chmod 600 "$file" 2>/dev/null || true
        return
    fi
    
    # 默认权限
    chmod 644 "$file" 2>/dev/null || true
}

# ==============================
# 服务管理
# ==============================
start_service() {
    local service_name="$1"
    local is_user="${2:-false}"
    
    local ctl_cmd="systemctl"
    if [ "$is_user" = "true" ]; then
        ctl_cmd="systemctl --user"
    fi

    print_info "启动服务: $service_name"
    
    $ctl_cmd daemon-reload 2>/dev/null || true
    $ctl_cmd enable "$service_name" 2>/dev/null || true
    $ctl_cmd restart "$service_name"
    
    sleep 2
    
    if $ctl_cmd is-active --quiet "$service_name"; then
        print_success "$service_name 已启动"
        return 0
    else
        print_error "$service_name 启动失败"
        $ctl_cmd status "$service_name" || true
        return 1
    fi
}

# ==============================
# 工具函数
# ==============================
command_exists() {
    command -v "$1" &>/dev/null
}

append_line_if_not_exists() {
    local line="$1"
    local file="$2"
    local use_sudo="${3:-false}"
    
    if [ ! -f "$file" ]; then
        if [ "$use_sudo" = "true" ]; then
            sudo touch "$file"
        else
            touch "$file"
        fi
    fi

    if ! grep -qF "$line" "$file" 2>/dev/null; then
        if [ "$use_sudo" = "true" ]; then
            echo "$line" | sudo tee -a "$file" > /dev/null
        else
            echo "$line" >> "$file"
        fi
        print_info "已追加配置到 $(basename "$file")"
    fi
}

wait_for_enter() {
    local message="${1:-按回车键继续...}"
    echo -e "${YELLOW}${message}${NC}"
    read -r
}

download_file() {
    local url="$1"
    local output="$2"
    local filename=$(basename "$output")
    
    mkdir -p "$(dirname "$output")"
    
    local need_download=true
    local remote_size=""

    print_info "正在检查: $filename"

    # 1. 尝试获取远程文件大小 (Content-Length)
    if command_exists curl; then
        # -s: 静默, -L: 跟随重定向, -I: 仅获取头部
        # tr -d '\r' 去除 HTTP 头部中的回车符
        remote_size=$(curl -sL -I "$url" | grep -i "^Content-Length:" | tail -n 1 | awk '{print $2}' | tr -d '\r')
    elif command_exists wget; then
        remote_size=$(wget --spider --server-response "$url" 2>&1 | grep -i "Content-Length:" | tail -n 1 | awk '{print $2}' | tr -d '\r')
    fi

    # 2. 检查本地文件状态
    if [ -f "$output" ]; then
        local local_size=$(stat -c%s "$output" 2>/dev/null || echo 0)
        
        # 验证 remote_size 是否为有效数字
        if [[ "$remote_size" =~ ^[0-9]+$ ]]; then
            if [ "$local_size" -eq "$remote_size" ]; then
                print_success "文件已存在且大小一致 ($local_size bytes)，跳过下载"
                need_download=false
            else
                print_warning "文件大小不匹配 (本地: $local_size vs 远程: $remote_size)，正在重新下载..."
                rm -f "$output"
            fi
        else
            print_warning "无法验证远程文件大小，将强制覆盖旧文件..."
            rm -f "$output"
        fi
    fi
    
    # 3. 执行下载
    if [ "$need_download" = true ]; then
        print_info "开始下载: $filename"
        if command_exists wget; then
            wget -q --show-progress -O "$output" "$url" || return 1
        elif command_exists curl; then
            curl -L -o "$output" "$url" || return 1
        else
            print_error "未找到 wget 或 curl"
            return 1
        fi
        print_success "下载完成"
    fi
    
    return 0
}


# ==============================
# 调试信息
# ==============================
if [ "${DEBUG_MODE:-false}" = "true" ]; then
    print_header "调试信息"
    print_info "SCRIPT_DIR: $SCRIPT_DIR"
    print_info "PROJECT_ROOT: $PROJECT_ROOT"
    print_info "GLOBAL_DATA_DIR: $GLOBAL_DATA_DIR"
    print_info "TEMPLATES_DIR: $TEMPLATES_DIR"
    print_info "SECRETS_LOADED: $SECRETS_LOADED"
    print_info "DESKTOP_DIR: $DESKTOP_DIR"
    echo
fi
