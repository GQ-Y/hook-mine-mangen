#!/bin/bash

# MineAdmin 统一管理脚本
# 支持 Ubuntu 24.04 x86_64 和 ARM64 架构
# 集成安装、管理、监控、配置等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Dialog检测和安装
check_and_install_dialog() {
    if ! command -v dialog &> /dev/null; then
        print_info "检测到系统未安装dialog，正在安装..."
        
        # 检测系统类型并安装dialog
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                print_info "使用Homebrew安装dialog..."
                if brew install dialog; then
                    print_success "dialog安装成功"
                else
                    print_error "dialog安装失败"
                    show_dialog_install_guide
                    exit 1
                fi
            else
                print_error "macOS需要安装Homebrew才能安装dialog"
                show_dialog_install_guide
                exit 1
            fi
        elif [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu
            print_info "使用apt安装dialog..."
            if sudo apt-get update && sudo apt-get install -y dialog; then
                print_success "dialog安装成功"
            else
                print_error "dialog安装失败"
                show_dialog_install_guide
                exit 1
            fi
        elif [[ -f /etc/redhat-release ]]; then
            # CentOS/RHEL
            print_info "使用yum/dnf安装dialog..."
            if sudo yum install -y dialog 2>/dev/null || sudo dnf install -y dialog; then
                print_success "dialog安装成功"
            else
                print_error "dialog安装失败"
                show_dialog_install_guide
                exit 1
            fi
        else
            print_error "无法自动安装dialog，请手动安装"
            show_dialog_install_guide
            exit 1
        fi
        
        # 验证安装
        if command -v dialog &> /dev/null; then
            print_success "dialog安装验证成功"
            # 等待一秒让用户看到成功消息
            sleep 1
        else
            print_error "dialog安装验证失败"
            show_dialog_install_guide
            exit 1
        fi
    else
        print_success "dialog已安装"
    fi
}

# 显示dialog安装引导
show_dialog_install_guide() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📖 Dialog 安装引导${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}macOS 安装方法:${NC}"
        echo "1. 安装Homebrew（如果未安装）:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "2. 安装dialog:"
        echo "   brew install dialog"
        echo ""
    elif [[ -f /etc/debian_version ]]; then
        echo -e "${BLUE}Debian/Ubuntu 安装方法:${NC}"
        echo "sudo apt-get update && sudo apt-get install -y dialog"
        echo ""
    elif [[ -f /etc/redhat-release ]]; then
        echo -e "${BLUE}CentOS/RHEL 安装方法:${NC}"
        echo "sudo yum install -y dialog"
        echo "或"
        echo "sudo dnf install -y dialog"
        echo ""
    else
        echo -e "${BLUE}通用安装方法:${NC}"
        echo "请访问 https://invisible-island.net/dialog/ 下载源码编译安装"
        echo ""
    fi
    
    echo -e "${YELLOW}安装完成后，重新运行此脚本即可使用图形化界面${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMMAND_NAME="hook"
ARCH=$(uname -m)
INSTALL_DIR="/usr/local/bin"
COMMAND_SCRIPT="$INSTALL_DIR/$COMMAND_NAME"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_success() {
    print_message $GREEN "✅ $1"
}

print_error() {
    print_message $RED "❌ $1"
}

print_warning() {
    print_message $YELLOW "⚠️  $1"
}

print_info() {
    print_message $WHITE "ℹ️  $1"
}

print_title() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🚀 MineAdmin 统一管理工具                    ║"
    echo "║                    支持 Ubuntu 24.04                        ║"
    echo "║                    架构: $ARCH                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Dialog主菜单
dialog_main_menu() {
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_menu$$
    
    # 显示主菜单 - 调整尺寸以适应终端
    dialog --title "🚀 MineAdmin 统一管理工具" \
           --backtitle "支持 Ubuntu 24.04 | 架构: $ARCH" \
           --menu "请选择要执行的操作：" 0 0 0 \
           1 "系统兼容性检测" \
           2 "一键安装部署" \
           3 "选择Web模式" \
           4 "启动所有服务" \
           5 "选择性启动服务" \
           6 "停止所有服务" \
           7 "重启所有服务" \
           8 "查看服务状态" \
           9 "查看容器日志" \
           10 "查看系统资源" \
           11 "查看网络连接" \
           12 "重新生成配置" \
           13 "修改密码" \
           14 "查看配置信息" \
           15 "查看已安装插件" \
           16 "设置开机自启动" \
           17 "清理Docker缓存" \
           18 "容器导出功能" \
           19 "容器导入功能" \
           20 "查看导出镜像" \
           21 "清理导出镜像" \
           22 "完全卸载" \
           23 "安装全局命令" \
           24 "卸载全局命令" \
           25 "检查命令状态" \
           26 "查看帮助" \
           0 "退出" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    # 返回选择结果
    echo "$choice"
}

# 命令菜单（默认显示）
show_command_menu() {
    clear
    print_title
    echo ""
    echo -e "${WHITE}📋 MineAdmin 管理工具 - 可用命令${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${MAGENTA}🚀 部署管理:${NC}"
    echo "  ./docker/mineadmin.sh check    - 系统兼容性检测"
    echo "  ./docker/mineadmin.sh install  - 一键安装部署"
    echo "  ./docker/mineadmin.sh build    - 前端构建"
    echo ""
    echo -e "${MAGENTA}⚙️  服务管理:${NC}"
    echo "  ./docker/mineadmin.sh start    - 启动所有服务"
    echo "  ./docker/mineadmin.sh sestart       - 选择性启动服务"
    echo "  ./docker/mineadmin.sh stop     - 停止所有服务"
    echo "  ./docker/mineadmin.sh restart  - 重启所有服务"
    echo "  ./docker/mineadmin.sh status   - 查看服务状态"
    echo "  ./docker/mineadmin.sh logs     - 查看容器日志"
    echo "  ./docker/mineadmin.sh resources - 查看系统资源"
    echo ""
    echo -e "${MAGENTA}🔧 配置管理:${NC}"
    echo "  ./docker/mineadmin.sh network  - 查看网络连接"
    echo "  ./docker/mineadmin.sh config   - 重新生成配置"
    echo "  ./docker/mineadmin.sh generate-config - 交互式生成配置"
    echo "  ./docker/mineadmin.sh password - 修改密码"
    echo "  ./docker/mineadmin.sh info     - 查看配置信息"
    echo "  ./docker/mineadmin.sh plugins  - 查看已安装插件"
    echo ""
    echo -e "${MAGENTA}📦 容器管理:${NC}"
    echo "  ./docker/mineadmin.sh export   - 容器导出功能"
    echo "  ./docker/mineadmin.sh import   - 容器导入功能"
    echo "  ./docker/mineadmin.sh import-history - 查看导入历史"
    echo "  ./docker/mineadmin.sh list-images - 查看导出镜像"
    echo "  ./docker/mineadmin.sh clean-images - 清理导出镜像"
    echo ""
    echo -e "${MAGENTA}🧹 清理维护:${NC}"
    echo "  ./docker/mineadmin.sh clean    - 清理Docker缓存"
    echo "  ./docker/mineadmin.sh uninstall - 完全卸载"
    echo ""
    echo -e "${MAGENTA}🔗 全局命令:${NC}"
    echo "  ./docker/mineadmin.sh setup    - 安装全局命令"
    echo "  ./docker/mineadmin.sh remove   - 卸载全局命令"
    echo "  ./docker/mineadmin.sh test     - 检查命令状态"
    echo ""
    echo -e "${MAGENTA}📖 帮助信息:${NC}"
    echo "  ./docker/mineadmin.sh help     - 查看详细帮助"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 使用提示:${NC}"
    echo "  1. 直接输入命令即可执行对应功能"
    echo "  2. 安装全局命令后可使用 'hook <命令>' 简化操作"
    echo "  3. 使用 'hook help' 查看详细帮助信息"
    echo ""
    echo -e "${WHITE}示例:${NC}"
    echo "  $ ./docker/mineadmin.sh check"
    echo "  $ ./docker/mineadmin.sh install"
    echo "  $ ./docker/mineadmin.sh status"
    echo ""
    echo -e "${GREEN}✅ 当前脚本支持所有命令模式，无需使用图形化菜单${NC}"
    echo ""
    echo -e "${BLUE}按任意键退出...${NC}"
    read -n 1 -s
}

# 命令模式菜单（当dialog不可用时显示）
command_mode_menu() {
    clear
    print_title
    echo ""
    echo -e "${WHITE}📋 命令模式 - 请使用以下命令:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${MAGENTA}🚀 部署管理:${NC}"
    echo "  hook check    - 系统兼容性检测"
    echo "  hook install  - 一键安装部署"
    echo "  hook build    - 前端构建"
    echo ""
    echo -e "${MAGENTA}⚙️  服务管理:${NC}"
    echo "  hook start    - 启动所有服务"
    echo "  hook sestart  - 选择性启动服务"
    echo "  hook stop     - 停止所有服务"
    echo "  hook restart  - 重启所有服务"
    echo "  hook status   - 查看服务状态"
    echo "  hook logs     - 查看容器日志"
    echo "  hook resources - 查看系统资源"
    echo ""
    echo -e "${MAGENTA}🔧 配置管理:${NC}"
    echo "  hook network  - 查看网络连接"
    echo "  hook config   - 重新生成配置"
    echo "  hook generate-config - 交互式生成配置"
    echo "  hook password - 修改密码"
    echo "  hook info     - 查看配置信息"
    echo "  hook plugins  - 查看已安装插件"
    echo ""
    echo -e "${MAGENTA}📦 容器管理:${NC}"
    echo "  hook export   - 容器导出功能"
    echo "  hook import   - 容器导入功能"
    echo "  hook import-history - 查看导入历史"
    echo "  hook list-images - 查看导出镜像"
    echo "  hook clean-images - 清理导出镜像"
    echo ""
    echo -e "${MAGENTA}🧹 清理维护:${NC}"
    echo "  hook clean    - 清理Docker缓存"
    echo "  hook uninstall - 完全卸载"
    echo ""
    echo -e "${MAGENTA}🔗 全局命令:${NC}"
    echo "  hook setup    - 安装全局命令"
    echo "  hook remove   - 卸载全局命令"
    echo "  hook test     - 检查命令状态"
    echo ""
    echo -e "${MAGENTA}📖 帮助信息:${NC}"
    echo "  hook help     - 查看帮助信息"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 提示: 直接输入命令即可执行对应功能${NC}"
    echo ""
    echo -e "${WHITE}示例:${NC}"
    echo "  $ hook check"
    echo "  $ hook install"
    echo "  $ hook status"
    echo ""
    echo -e "${GREEN}✅ 当前脚本支持所有命令模式，无需使用数字菜单${NC}"
    echo ""
    echo -e "${BLUE}按任意键继续...${NC}"
    read -n 1 -s
}

# 系统兼容性检测
check_system_compatibility() {
    echo -e "${BLUE}[1/6] 检测操作系统...${NC}"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo -e "${WHITE}操作系统:${NC} $PRETTY_NAME"
        echo -e "${WHITE}版本:${NC} $VERSION_ID"
        
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "24.04" ]]; then
                print_success "Ubuntu 24.04 LTS - 完全兼容"
            elif [[ "$VERSION_ID" == "22.04" ]]; then
                print_warning "Ubuntu 22.04 LTS - 基本兼容，建议升级到24.04"
            else
                print_warning "Ubuntu $VERSION_ID - 可能兼容，建议使用24.04"
            fi
        else
            print_error "非Ubuntu系统，可能不兼容"
        fi
    else
        print_error "无法检测操作系统信息"
    fi
    
    echo -e "${BLUE}[2/6] 检测系统架构...${NC}"
    echo -e "${WHITE}架构:${NC} $ARCH"
    
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
        print_success "x86_64 架构 - 完全兼容"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        print_success "ARM64 架构 - 完全兼容"
    else
        print_warning "未知架构 $ARCH - 可能不兼容"
    fi
    
    echo -e "${BLUE}[3/6] 检测内存...${NC}"
    local mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    echo -e "${WHITE}总内存:${NC} ${mem_total}GB"
    
    if [[ $mem_total -ge 2 ]]; then
        print_success "内存充足 (≥2GB)"
    else
        print_error "内存不足 (<2GB)，建议至少2GB内存"
    fi
    
    echo -e "${BLUE}[4/6] 检测磁盘空间...${NC}"
    local disk_free=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    echo -e "${WHITE}可用空间:${NC} ${disk_free}GB"
    
    if [[ $disk_free -ge 10 ]]; then
        print_success "磁盘空间充足 (≥10GB可用)"
    else
        print_error "磁盘空间不足 (<10GB可用)，建议至少10GB可用空间"
    fi
    
    echo -e "${BLUE}[5/6] 检测网络连接...${NC}"
    if curl -s --connect-timeout 5 https://www.google.com &> /dev/null; then
        print_success "外网连接正常"
    else
        print_warning "外网连接可能有问题"
    fi
    
    if curl -s --connect-timeout 5 https://registry-1.docker.io &> /dev/null; then
        print_success "Docker Hub连接正常"
    else
        print_warning "Docker Hub连接可能有问题"
    fi
    
    echo -e "${BLUE}[6/6] 检测必要工具...${NC}"
    local tools=("curl" "wget" "git" "unzip" "grep" "sed" "awk")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool - 已安装"
        else
            print_error "$tool - 未安装"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_success "所有必要工具都已安装"
    else
        print_warning "缺少以下工具: ${missing_tools[*]}"
        echo "请运行: sudo apt update && sudo apt install -y ${missing_tools[*]}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 建议:${NC}"
    echo "1. 如果所有检测都通过，可以安全运行安装"
    echo "2. 如果有警告，建议先解决问题再安装"
    echo "3. 如果有错误，必须解决问题后才能安装"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 一键安装部署
install_mineadmin() {
    print_info "开始安装 MineAdmin..."
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        return 1
    fi
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        print_info "正在安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_success "Docker安装完成"
    else
        print_success "Docker已安装"
    fi
    
    # 检查Docker Compose是否安装
    if ! command -v docker-compose &> /dev/null; then
        print_info "正在安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose安装完成"
    else
        print_success "Docker Compose已安装"
    fi
    
    # 生成配置文件
    print_info "正在生成配置文件..."
    generate_config_interactive
    
    if [ $? -ne 0 ]; then
        print_error "配置生成失败，安装终止"
        return 1
    fi
    
    # 构建Docker镜像
    print_info "正在构建Docker镜像..."
    cd "$PROJECT_ROOT"
    
    # 检测系统架构
    local build_arch=""
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
        build_arch="linux/amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        build_arch="linux/arm64"
    else
        build_arch="linux/amd64"
        print_warning "未知架构，使用默认架构: $build_arch"
    fi
    
    print_info "检测到架构: $ARCH，使用构建平台: $build_arch"
    
    # 构建后端镜像
    docker build --platform $build_arch -f docker/Dockerfile.server-app -t mineadmin/server-app:latest .
    
    # 构建前端生产镜像
    docker build --platform $build_arch -f docker/Dockerfile.web-prod -t mineadmin/web-prod:latest .
    
    # 启动服务
    print_info "正在启动服务..."
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d
    
    # 等待服务启动
    print_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    if docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "Up"; then
        print_success "MineAdmin安装完成！"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}🎯 访问信息:${NC}"
        echo "后端API: http://localhost:9501"
        echo "前端生产: http://localhost:80"
        echo ""
        echo -e "${WHITE}📡 监听端口:${NC}"
        echo "9501 - 后端API服务"
        echo "9502 - WebSocket服务"
        echo "9509 - 通知服务"
        echo "80   - 前端生产服务"
        echo "3306 - MySQL数据库"
        echo "6379 - Redis缓存"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # 安装全局命令
        install_global_command
        
        # 询问是否安装插件
        ask_install_plugins
    else
        print_error "服务启动失败，请检查日志"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env logs
    fi
}

# 选择Web模式
select_web_mode() {
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_web_mode$$
    
    # 显示Web模式选择菜单
    dialog --title "选择Web模式" \
           --backtitle "MineAdmin 管理工具" \
           --menu "请选择Web运行模式：" 10 50 5 \
           1 "生产模式 (nginx) - 端口80" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -n "$choice" ]; then
        # 切换到项目根目录
        cd "$PROJECT_ROOT"
        
        case $choice in
            1)
                        print_info "切换到生产模式..."
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d web-prod
                print_success "已切换到生产模式，访问地址: http://$(hostname -I | awk '{print $1}'):80"
                ;;
        esac
    else
        print_info "取消选择Web模式"
    fi
}

# 启动所有服务
start_services() {
    print_info "正在启动所有服务..."
    cd "$PROJECT_ROOT"
    # 启动所有服务
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d
    print_success "所有服务已启动"
}

# 选择性启动服务
selective_start_services() {
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_selective_start$$
    
    # 显示服务选择菜单（支持多选）
    dialog --title "选择性启动服务" \
           --backtitle "MineAdmin 管理工具" \
           --checklist "请选择要启动的服务（空格选择，回车确认）：" 15 60 8 \
           "mysql" "MySQL数据库" on \
           "redis" "Redis缓存" on \
           "server-app" "后端服务" off \
           "web-prod" "前端生产服务" off 2> "$tempfile"
    
    # 读取选择结果
    local selected_services=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$selected_services" ]; then
        print_info "取消启动服务"
        return
    fi
    
    # 切换到项目目录
    cd "$PROJECT_ROOT"
    
    # 检查是否需要启动后端服务
    local need_backend=false
    if echo "$selected_services" | grep -q "server-app"; then
        need_backend=true
    fi
    
    # 检查是否需要启动前端生产服务
    local need_production=false
    if echo "$selected_services" | grep -q "web-prod"; then
        need_production=true
    fi
    
    print_info "正在启动选中的服务..."
    
    # 启动基础服务（MySQL和Redis）
    if echo "$selected_services" | grep -q "mysql\|redis"; then
        local base_services=""
        if echo "$selected_services" | grep -q "mysql"; then
            base_services="$base_services mysql"
        fi
        if echo "$selected_services" | grep -q "redis"; then
            base_services="$base_services redis"
        fi
        
        if [ -n "$base_services" ]; then
            print_info "启动基础服务: $base_services"
            docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d $base_services
        fi
    fi
    
    # 启动后端服务（需要MySQL和Redis）
    if [ "$need_backend" = true ]; then
        print_info "启动后端服务..."
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d server-app
    fi
    
    # 启动前端生产服务
    if [ "$need_production" = true ]; then
        print_info "启动前端生产服务..."
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d web-prod
    fi
    
    print_success "选中的服务已启动"
    
    # 显示启动的服务信息
    echo ""
    echo -e "${WHITE}已启动的服务:${NC}"
    for service in $selected_services; do
        case $service in
            "mysql")
                echo "  ✅ MySQL数据库 - 端口: 3306"
                ;;
            "redis")
                echo "  ✅ Redis缓存 - 端口: 6379"
                ;;
            "server-app")
                echo "  ✅ 后端服务 - 端口: 9501, 9502, 9509"
                ;;
            "web-prod")
                echo "  ✅ 前端生产服务 - 端口: 80"
                ;;
        esac
    done
}

# 停止所有服务
stop_services() {
    print_info "正在停止所有服务..."
    cd "$PROJECT_ROOT"
    # 停止所有服务
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env down
    print_success "所有服务已停止"
}

# 重启所有服务
restart_services() {
    print_info "正在重启所有服务..."
    cd "$PROJECT_ROOT"
    # 重启当前运行的服务（不包括生产模式）
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env restart
    print_success "所有服务已重启"
}

# 查看服务状态
show_service_status() {
    print_info "服务状态:"
    cd "$PROJECT_ROOT"
    # 显示所有服务状态
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps
    echo ""
    print_info "系统资源使用情况:"
    docker stats --no-stream
}

# Dialog查看容器日志
show_container_logs() {
    local containers=("MySQL" "Redis" "Server App" "Web Prod")
    local services=("mysql" "redis" "server-app" "web-prod")
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_logs$$
    
    # 显示容器选择菜单
    dialog --title "查看容器日志" \
           --backtitle "MineAdmin 管理工具" \
           --menu "请选择要查看的容器日志：" 12 50 8 \
           1 "MySQL" \
           2 "Redis" \
           3 "Server App" \
           4 "Web Prod" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -n "$choice" ]; then
        local idx=$((choice-1))
        local container_name="${containers[$idx]}"
        local service_name="${services[$idx]}"
        
        # 切换到项目目录并显示日志
        cd "$PROJECT_ROOT"
        dialog --title "容器日志 - $container_name" \
               --backtitle "MineAdmin 管理工具" \
               --textbox <(docker-compose -f docker/docker-compose.yml --env-file server-app/.env logs "$service_name") 20 80
    fi
}

# 查看系统资源
show_system_resources() {
    echo -e "${WHITE}系统资源使用情况:${NC}"
    echo ""
    echo -e "${BLUE}CPU使用率:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    echo ""
    echo -e "${BLUE}内存使用情况:${NC}"
    free -h
    echo ""
    echo -e "${BLUE}磁盘使用情况:${NC}"
    df -h
    echo ""
    echo -e "${BLUE}Docker容器资源使用:${NC}"
    docker stats --no-stream
}

# 查看网络连接
show_network_connections() {
    echo -e "${WHITE}网络连接情况:${NC}"
    echo ""
    echo -e "${BLUE}监听端口:${NC}"
    # 检测系统类型，使用不同的netstat参数
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        netstat -an | grep LISTEN
    else
        # Linux
        netstat -tlnp
    fi
    echo ""
    echo -e "${BLUE}Docker网络:${NC}"
    docker network ls
    echo ""
    echo -e "${BLUE}容器网络详情:${NC}"
    docker network inspect mineadmin_default 2>/dev/null || echo "网络不存在"
}

# 重新生成配置
regenerate_config() {
    print_info "正在重新生成配置..."
    
    echo ""
    echo -e "${WHITE}请选择配置生成方式：${NC}"
    echo "  1) 快速配置 (使用默认值)"
    echo "  2) 交互式配置 (自定义所有选项)"
    echo ""
    echo -e "${CYAN}请输入选择 (1-2):${NC}"
    read -r choice
    
    case $choice in
        1)
            generate_config_quick
            ;;
        2)
            generate_config_interactive
            ;;
        *)
            print_info "配置生成已取消"
            return
            ;;
    esac
    
    print_success "配置已重新生成"
}

# 快速配置生成
generate_config_quick() {
    print_info "正在生成快速配置..."
    
    # 使用固定JWT密钥
    local jwt_secret="azOVxsOWt3r0ozZNz8Ss429ht0T8z6OpeIJAIwNp6X0xqrbEY2epfIWyxtC1qSNM8eD6/LQ/SahcQi2ByXa/2A=="
    local mine_access_token="" # 默认空
    
    # 获取系统内网IP地址
    local local_ip=$(ifconfig | grep -E "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    if [ -z "$local_ip" ]; then
        local_ip="127.0.0.1"
    fi
    local app_url="http://$local_ip:9501"
    
    # 使用您提供的默认配置值
    local app_name="MineAdmin"
    local app_debug="true"
    local db_driver="mysql"
    local db_host="mysql"
    local db_port="3306"
    local db_database="mineadmin"
    local db_username="root"
    local db_password="root123"
    local redis_host="redis"
    local redis_port="6379"
    local redis_password="root123"
    local redis_db="3"
    
    # 生成配置文件
    generate_config_files "$app_name" "$app_debug" "$app_url" \
                         "$db_driver" "$db_host" "$db_port" "$db_database" "$db_username" "$db_password" \
                         "$redis_host" "$redis_port" "$redis_password" "$redis_db" \
                         "$mine_access_token" "$jwt_secret"
    
    print_success "快速配置生成完成！"
    echo ""
    echo -e "${WHITE}默认配置信息:${NC}"
    echo "  应用名称: $app_name"
    echo "  调试模式: $app_debug"
    echo "  应用URL: $app_url"
    echo "  数据库类型: $db_driver"
    echo "  数据库: $db_host:$db_port/$db_database"
    echo "  Redis: $redis_host:$redis_port"
    echo ""
    echo -e "${YELLOW}注意: 请重新构建容器以使新配置生效${NC}"
}

# 生成配置文件
generate_config_files() {
    local app_name="$1"
    local app_debug="$2"
    local app_url="$3"
    local db_driver="$4"
    local db_host="$5"
    local db_port="$6"
    local db_database="$7"
    local db_username="$8"
    local db_password="$9"
    local redis_host="${10}"
    local redis_port="${11}"
    local redis_password="${12}"
    local redis_db="${13}"
    local mine_access_token="${14}"
    local jwt_secret="${15}"
    
    # 固定环境为 dev
    local app_env="dev"
    
    # 生成后端.env文件
    print_info "正在生成后端配置文件..."
    cat > "$PROJECT_ROOT/server-app/.env" << EOF
APP_NAME=$app_name
APP_ENV=$app_env
APP_DEBUG=$app_debug

DB_DRIVER=$db_driver
DB_HOST=$db_host
DB_PORT=$db_port
DB_DATABASE=$db_database
DB_USERNAME=$db_username
DB_PASSWORD=$db_password
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci
DB_PREFIX=

REDIS_HOST=$redis_host
REDIS_AUTH=$redis_password
REDIS_PORT=$redis_port
REDIS_DB=$redis_db

APP_URL = $app_url

JWT_SECRET=$jwt_secret

MINE_ACCESS_TOKEN=$mine_access_token

# Docker Compose 环境变量
MYSQL_ROOT_PASSWORD=root123
REDIS_PASSWORD=$redis_password
TZ=Asia/Shanghai
SERVER_PORT=9501
SERVER_HTTP_PORT=9502
SERVER_GRPC_PORT=9509
WEB_PORT=80
EOF
}

# 交互式配置生成
generate_config_interactive() {
    print_info "开始交互式配置生成..."
    echo ""
    
    # 获取系统内网IP地址
    local local_ip=$(ifconfig | grep -E "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    if [ -z "$local_ip" ]; then
        local_ip="127.0.0.1"
    fi
    
    # 使用固定的默认配置值
    local default_app_name="MineAdmin"
    local default_app_debug="true"
    local default_app_url="http://$local_ip:9501"
    local default_db_driver="mysql"
    local default_db_host="mysql"
    local default_db_port="3306"
    local default_db_database="mineadmin"
    local default_db_username="root"
    local default_db_password="root123"
    local default_redis_host="redis"
    local default_redis_port="6379"
    local default_redis_password="root123"
    local default_redis_db="3"
    local default_mine_access_token=""
    
    # 使用固定JWT密钥
    local jwt_secret="azOVxsOWt3r0ozZNz8Ss429ht0T8z6OpeIJAIwNp6X0xqrbEY2epfIWyxtC1qSNM8eD6/LQ/SahcQi2ByXa/2A=="
    
    echo -e "${WHITE}=== MineAdmin 配置生成向导 ===${NC}"
    echo ""
    
    # 应用名称
    echo -e "${CYAN}应用名称${NC} [默认: $default_app_name]:"
    read -r app_name
    app_name="${app_name:-$default_app_name}"
    
    # 调试模式
    echo -e "${CYAN}是否启用调试模式？${NC} [默认: $default_app_debug] (true/false):"
    read -r app_debug
    app_debug="${app_debug:-$default_app_debug}"
    
    # 应用URL
    echo -e "${CYAN}应用URL${NC} [默认: $default_app_url]:"
    read -r app_url
    app_url="${app_url:-$default_app_url}"
    
    echo ""
    echo -e "${WHITE}=== 数据库配置 ===${NC}"
    echo ""
    
    # 数据库类型选择
    echo -e "${CYAN}选择数据库类型${NC} [默认: $default_db_driver] (mysql/postgresql):"
    read -r db_driver
    db_driver="${db_driver:-$default_db_driver}"
    
    # 数据库主机
    echo -e "${CYAN}数据库主机${NC} [默认: $default_db_host]:"
    read -r db_host
    db_host="${db_host:-$default_db_host}"
    
    # 数据库端口
    local default_port
    if [[ "$db_driver" == "postgresql" ]]; then
        default_port="5432"
    else
        default_port="3306"
    fi
    echo -e "${CYAN}数据库端口${NC} [默认: $default_port]:"
    read -r db_port
    db_port="${db_port:-$default_port}"
    
    # 数据库名称
    echo -e "${CYAN}数据库名称${NC} [默认: $default_db_database]:"
    read -r db_database
    db_database="${db_database:-$default_db_database}"
    
    # 数据库用户名
    echo -e "${CYAN}数据库用户名${NC} [默认: $default_db_username]:"
    read -r db_username
    db_username="${db_username:-$default_db_username}"
    
    # 数据库密码
    echo -e "${CYAN}数据库密码${NC} [默认: root123]:"
    read -s db_password
    echo ""
    db_password="${db_password:-$default_db_password}"
    
    echo ""
    echo -e "${WHITE}=== Redis配置 ===${NC}"
    echo ""
    
    # Redis主机
    echo -e "${CYAN}Redis主机${NC} [默认: $default_redis_host]:"
    read -r redis_host
    redis_host="${redis_host:-$default_redis_host}"
    
    # Redis端口
    echo -e "${CYAN}Redis端口${NC} [默认: $default_redis_port]:"
    read -r redis_port
    redis_port="${redis_port:-$default_redis_port}"
    
    # Redis密码
    echo -e "${CYAN}Redis密码${NC} [默认: root123]:"
    read -s redis_password
    echo ""
    redis_password="${redis_password:-$default_redis_password}"
    
    # Redis数据库
    echo -e "${CYAN}Redis数据库${NC} [默认: $default_redis_db]:"
    read -r redis_db
    redis_db="${redis_db:-$default_redis_db}"
    
    echo ""
    echo -e "${WHITE}=== 其他配置 ===${NC}"
    echo ""
    
    # Mine访问令牌（默认为空）
    echo -e "${CYAN}Mine访问令牌${NC} [默认: 空] (可选，直接回车跳过):"
    read -r mine_access_token
    mine_access_token="${mine_access_token:-}"
    
    echo ""
    
    # 显示配置摘要
    echo -e "${WHITE}=== 配置摘要 ===${NC}"
    echo "  应用名称: $app_name"
    echo "  调试模式: $app_debug"
    echo "  应用URL: $app_url"
    echo "  数据库类型: $db_driver"
    echo "  数据库: $db_host:$db_port/$db_database"
    echo "  Redis: $redis_host:$redis_port"
    echo ""
    
    # 确认配置
    echo -e "${YELLOW}确认生成配置文件？(y/N):${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "配置生成已取消"
        return
    fi
    
    # 生成配置文件
    generate_config_files "$app_name" "$app_debug" "$app_url" \
                         "$db_driver" "$db_host" "$db_port" "$db_database" "$db_username" "$db_password" \
                         "$redis_host" "$redis_port" "$redis_password" "$redis_db" \
                         "$mine_access_token" "$jwt_secret"
    
    print_success "配置文件生成完成！"
    echo ""
    echo -e "${WHITE}生成的文件:${NC}"
    echo "  ✅ $PROJECT_ROOT/server-app/.env"
    echo ""
    echo -e "${YELLOW}注意: 请重新构建容器以使新配置生效${NC}"
}

# 修改密码
change_passwords() {
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_password$$
    
    # 显示密码修改选择菜单
    dialog --title "修改密码" \
           --backtitle "MineAdmin 管理工具" \
           --menu "请选择要修改的密码：" 10 50 5 \
           1 "MySQL Root密码" \
           2 "MySQL 用户密码" \
           3 "Redis 密码" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -n "$choice" ]; then
        case $choice in
            1)
                # 使用dialog输入新密码
                local new_password=$(dialog --title "修改MySQL Root密码" \
                                           --backtitle "MineAdmin 管理工具" \
                                           --passwordbox "请输入新的MySQL Root密码：" 8 50 3>&1 1>&2 2>&3)
                if [ -n "$new_password" ]; then
                    print_info "MySQL Root密码修改功能待实现"
                    print_info "新密码: $new_password"
                else
                    print_info "取消修改MySQL Root密码"
                fi
                ;;
            2)
                # 使用dialog输入新密码
                local new_password=$(dialog --title "修改MySQL用户密码" \
                                           --backtitle "MineAdmin 管理工具" \
                                           --passwordbox "请输入新的MySQL用户密码：" 8 50 3>&1 1>&2 2>&3)
                if [ -n "$new_password" ]; then
                    print_info "MySQL用户密码修改功能待实现"
                    print_info "新密码: $new_password"
                else
                    print_info "取消修改MySQL用户密码"
                fi
                ;;
            3)
                # 使用dialog输入新密码
                local new_password=$(dialog --title "修改Redis密码" \
                                           --backtitle "MineAdmin 管理工具" \
                                           --passwordbox "请输入新的Redis密码：" 8 50 3>&1 1>&2 2>&3)
                if [ -n "$new_password" ]; then
                    print_info "Redis密码修改功能待实现"
                    print_info "新密码: $new_password"
                else
                    print_info "取消修改Redis密码"
                fi
                ;;
        esac
    else
        print_info "取消修改密码"
    fi
}

# 查看配置信息
show_config_info() {
    echo -e "${WHITE}当前配置信息:${NC}"
    echo ""
    echo -e "${BLUE}后端配置 (.env):${NC}"
    cat "$PROJECT_ROOT/server-app/.env"
    echo ""
    echo -e "${BLUE}前端开发配置 (.env.development):${NC}"
    cat "$PROJECT_ROOT/web/.env.development"
    echo ""
    echo -e "${BLUE}前端生产配置 (.env.production):${NC}"
    cat "$PROJECT_ROOT/web/.env.production"
}

# 前端构建
build_frontend() {
    print_info "开始前端构建..."
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # 检查web目录是否存在
    if [ ! -d "web" ]; then
        print_error "web目录不存在: $PROJECT_ROOT/web"
        return 1
    fi
    
    # 检查系统是否安装了Node.js和pnpm
    print_info "检查Node.js和pnpm环境..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js未安装，请先安装Node.js"
        echo "安装命令: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - && sudo apt-get install -y nodejs"
        return 1
    fi
    
    if ! command -v pnpm &> /dev/null; then
        print_error "pnpm未安装，请先安装pnpm"
        echo "安装命令: npm install -g pnpm"
        return 1
    fi
    
    print_success "Node.js版本: $(node --version)"
    print_success "pnpm版本: $(pnpm --version)"
    
    # 进入web目录
    cd web
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        print_error "package.json不存在，请检查web目录是否正确"
        return 1
    fi
    
    # 清理旧的构建文件
    print_info "清理旧的构建文件..."
    rm -rf node_modules dist pnpm-lock.yaml
    
    # 安装依赖
    print_info "安装前端依赖..."
    pnpm config set registry https://registry.npmmirror.com/
    pnpm install
    
    if [ $? -ne 0 ]; then
        print_error "依赖安装失败"
        return 1
    fi
    
    # 构建生产版本
    print_info "构建生产版本..."
    pnpm build
    
    if [ $? -ne 0 ]; then
        print_error "构建失败"
        return 1
    fi
    
    # 检查构建结果
    if [ ! -d "dist" ]; then
        print_error "构建失败，dist目录不存在"
        return 1
    fi
    
    print_success "前端构建完成！"
    echo ""
    echo -e "${WHITE}构建结果:${NC}"
    echo "  ✅ 依赖安装完成"
    echo "  ✅ 生产版本构建完成"
    echo "  ✅ dist目录已生成"
    echo ""
    echo -e "${WHITE}dist目录内容:${NC}"
    ls -la dist/
    echo ""
    echo -e "${YELLOW}注意: 现在可以启动生产模式服务${NC}"
    echo "启动命令: hook web (选择生产模式)"
}

# 查看已安装插件
show_installed_plugins() {
    echo -e "${WHITE}已安装的插件:${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # 检查容器是否运行
    if ! docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "server-app.*Up"; then
        print_error "后端服务未运行，无法查看插件"
        return 1
    fi
    
    print_info "正在获取已安装插件列表..."
    
    # 执行命令获取已安装插件
    docker-compose -f docker/docker-compose.yml --env-file server-app/.env exec -T server-app swoole-cli bin/hyperf.php mine-extension:list 2>/dev/null || {
        print_warning "无法获取插件列表，可能没有安装插件或命令不存在"
        echo ""
        echo -e "${WHITE}手动查看插件目录:${NC}"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env exec -T server-app ls -la /app/plugin/ 2>/dev/null || echo "插件目录不存在"
    }
}

# 设置开机自启动
setup_autostart() {
    # 检查是否为Linux系统
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "开机自启动功能仅支持Linux系统"
        echo "当前系统: $OSTYPE"
        return 1
    fi
    
    # 检查是否为Ubuntu系统
    if [[ ! -f /etc/os-release ]] || ! grep -q "ubuntu" /etc/os-release; then
        print_warning "此功能主要针对Ubuntu系统优化，其他Linux发行版可能不兼容"
    fi
    
    # 检查systemd是否可用
    if ! command -v systemctl &> /dev/null; then
        print_error "系统不支持systemd，无法设置开机自启动"
        return 1
    fi
    
    # 检查Docker服务状态
    if ! systemctl is-active --quiet docker; then
        print_error "Docker服务未运行，请先启动Docker服务"
        echo "启动命令: sudo systemctl start docker"
        return 1
    fi
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_autostart$$
    
    # 显示自启动选择菜单
    dialog --title "设置开机自启动" \
           --backtitle "MineAdmin 管理工具" \
           --menu "请选择要设置的服务：" 12 60 6 \
           1 "Docker服务" \
           2 "MineAdmin服务" \
           3 "Docker + MineAdmin服务" \
           4 "查看当前自启动状态" \
           5 "禁用所有自启动" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$choice" ]; then
        print_info "取消设置开机自启动"
        return
    fi
    
    case $choice in
        1)
            setup_docker_autostart
            ;;
        2)
            setup_mineadmin_autostart
            ;;
        3)
            setup_docker_autostart
            setup_mineadmin_autostart
            ;;
        4)
            show_autostart_status
            ;;
        5)
            disable_autostart
            ;;
    esac
}

# 设置Docker开机自启动
setup_docker_autostart() {
    print_info "正在设置Docker服务开机自启动..."
    
    if sudo systemctl enable docker; then
        print_success "Docker服务开机自启动已启用"
    else
        print_error "设置Docker开机自启动失败"
        return 1
    fi
}

# 设置MineAdmin开机自启动
setup_mineadmin_autostart() {
    print_info "正在设置MineAdmin服务开机自启动..."
    
    # 创建systemd服务文件
    local service_file="/etc/systemd/system/mineadmin.service"
    local user=$(whoami)
    
    # 检查项目路径是否存在
    if [ ! -d "$PROJECT_ROOT" ]; then
        print_error "项目路径不存在: $PROJECT_ROOT"
        return 1
    fi
    
    # 创建服务文件内容
    local service_content="[Unit]
Description=MineAdmin Docker Compose Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_ROOT
    ExecStart=/usr/local/bin/docker-compose -f docker/docker-compose.yml --env-file server-app/.env up -d
    ExecStop=/usr/local/bin/docker-compose -f docker/docker-compose.yml --env-file server-app/.env down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target"
    
    # 写入服务文件
    if echo "$service_content" | sudo tee "$service_file" > /dev/null; then
        print_success "MineAdmin服务文件已创建"
    else
        print_error "创建MineAdmin服务文件失败"
        return 1
    fi
    
    # 重新加载systemd配置
    if sudo systemctl daemon-reload; then
        print_success "systemd配置已重新加载"
    else
        print_error "重新加载systemd配置失败"
        return 1
    fi
    
    # 启用服务
    if sudo systemctl enable mineadmin.service; then
        print_success "MineAdmin服务开机自启动已启用"
    else
        print_error "启用MineAdmin开机自启动失败"
        return 1
    fi
    
    print_info "MineAdmin服务将在系统启动时自动启动"
    print_info "服务文件位置: $service_file"
}

# 查看自启动状态
show_autostart_status() {
    echo -e "${WHITE}当前开机自启动状态:${NC}"
    echo ""
    
    # 检查Docker服务状态
    echo -e "${BLUE}Docker服务:${NC}"
    if systemctl is-enabled docker &> /dev/null; then
        local docker_status=$(systemctl is-enabled docker)
        if [[ "$docker_status" == "enabled" ]]; then
            print_success "Docker服务已启用开机自启动"
        else
            print_warning "Docker服务开机自启动状态: $docker_status"
        fi
    else
        print_error "无法获取Docker服务状态"
    fi
    
    echo ""
    
    # 检查MineAdmin服务状态
    echo -e "${BLUE}MineAdmin服务:${NC}"
    if systemctl is-enabled mineadmin.service &> /dev/null; then
        local mineadmin_status=$(systemctl is-enabled mineadmin.service)
        if [[ "$mineadmin_status" == "enabled" ]]; then
            print_success "MineAdmin服务已启用开机自启动"
        else
            print_warning "MineAdmin服务开机自启动状态: $mineadmin_status"
        fi
    else
        print_warning "MineAdmin服务未配置开机自启动"
    fi
    
    echo ""
    
    # 显示服务文件信息
    if [ -f "/etc/systemd/system/mineadmin.service" ]; then
        echo -e "${BLUE}MineAdmin服务文件:${NC}"
        echo "位置: /etc/systemd/system/mineadmin.service"
        echo "状态: 已创建"
    else
        echo -e "${BLUE}MineAdmin服务文件:${NC}"
        echo "状态: 未创建"
    fi
}

# 禁用所有自启动
disable_autostart() {
    print_info "正在禁用所有开机自启动..."
    
    # 禁用MineAdmin服务
    if systemctl is-enabled mineadmin.service &> /dev/null; then
        if sudo systemctl disable mineadmin.service; then
            print_success "MineAdmin服务开机自启动已禁用"
        else
            print_error "禁用MineAdmin开机自启动失败"
        fi
    else
        print_info "MineAdmin服务未配置开机自启动"
    fi
    
    # 删除MineAdmin服务文件
    if [ -f "/etc/systemd/system/mineadmin.service" ]; then
        if sudo rm -f "/etc/systemd/system/mineadmin.service"; then
            print_success "MineAdmin服务文件已删除"
        else
            print_error "删除MineAdmin服务文件失败"
        fi
        
        # 重新加载systemd配置
        if sudo systemctl daemon-reload; then
            print_success "systemd配置已重新加载"
        else
            print_error "重新加载systemd配置失败"
        fi
    fi
    
    # 询问是否禁用Docker服务自启动
    dialog --title "禁用Docker自启动" \
           --backtitle "MineAdmin 管理工具" \
           --yesno "是否同时禁用Docker服务的开机自启动？\n\n注意：禁用Docker自启动可能影响其他Docker应用" 8 60
    
    if [ $? -eq 0 ]; then
        if sudo systemctl disable docker; then
            print_success "Docker服务开机自启动已禁用"
        else
            print_error "禁用Docker开机自启动失败"
        fi
    else
        print_info "保留Docker服务开机自启动"
    fi
    
    print_success "所有开机自启动已禁用"
}

# 清理Docker缓存
clean_docker_cache() {
    print_info "正在清理Docker缓存..."
    docker system prune -f
    docker image prune -f
    docker volume prune -f
    print_success "Docker缓存清理完成"
}

# 完全卸载
uninstall_mineadmin() {
    echo -e "${RED}警告: 此操作将完全删除MineAdmin及其所有数据！${NC}"
    read -p "确认要卸载吗？(输入 'yes' 确认): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        print_info "正在卸载MineAdmin..."
        
        # 停止并删除容器
        cd "$PROJECT_ROOT"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env --profile production down -v
        
        # 删除镜像
        docker rmi mineadmin/server-app:latest mineadmin/web-prod:latest 2>/dev/null || true
        
        # 删除配置文件
        rm -f "$PROJECT_ROOT/server-app/.env"
        rm -f "$PROJECT_ROOT/web/.env.development"
        rm -f "$PROJECT_ROOT/web/.env.production"
        
        # 卸载全局命令
        uninstall_global_command
        
        print_success "MineAdmin已完全卸载"
    else
        print_info "卸载已取消"
    fi
}

# 安装全局命令
install_global_command() {
    print_info "正在安装全局命令 '$COMMAND_NAME'..."
    print_info "系统架构: $ARCH"
    print_info "安装路径: $INSTALL_DIR"
    
    # 检查项目路径
    if [ ! -d "$PROJECT_ROOT" ]; then
        print_error "项目路径不存在: $PROJECT_ROOT"
        return 1
    fi
    
    # 检查安装目录权限
    if [ ! -w "$INSTALL_DIR" ]; then
        print_warning "安装目录无写权限: $INSTALL_DIR"
        print_info "尝试使用sudo权限安装..."
        
        # 使用sudo创建命令脚本
        sudo tee "$COMMAND_SCRIPT" > /dev/null << EOF
#!/bin/bash

# MineAdmin 管理面板全局命令
# 通过 $COMMAND_NAME 命令快速启动管理面板
# 系统架构: $ARCH

# 项目路径
PROJECT_PATH="$PROJECT_ROOT"

# 检查项目路径是否存在
if [ ! -d "\$PROJECT_PATH" ]; then
    echo "❌ 错误: 项目路径不存在: \$PROJECT_PATH"
    echo "请确保项目文件完整，或重新运行安装脚本"
    exit 1
fi

# 切换到项目目录
cd "\$PROJECT_PATH"

# 启动管理面板
exec "\$PROJECT_PATH/docker/mineadmin.sh" "\$@"
EOF
        
        # 给命令脚本添加执行权限
        sudo chmod +x "$COMMAND_SCRIPT"
        print_success "使用sudo权限安装完成"
    else
        # 直接创建命令脚本
        cat > "$COMMAND_SCRIPT" << EOF
#!/bin/bash

# MineAdmin 管理面板全局命令
# 通过 $COMMAND_NAME 命令快速启动管理面板
# 系统架构: $ARCH

# 项目路径
PROJECT_PATH="$PROJECT_ROOT"

# 检查项目路径是否存在
if [ ! -d "\$PROJECT_PATH" ]; then
    echo "❌ 错误: 项目路径不存在: \$PROJECT_PATH"
    echo "请确保项目文件完整，或重新运行安装脚本"
    exit 1
fi

# 切换到项目目录
cd "\$PROJECT_PATH"

# 启动管理面板
exec "\$PROJECT_PATH/docker/mineadmin.sh" "\$@"
EOF
        
        # 给命令脚本添加执行权限
        chmod +x "$COMMAND_SCRIPT"
        print_success "直接安装完成"
    fi
    
    # 添加到shell配置文件
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    local config_updated=false
    
    # 添加到bashrc
    if [ -f "$bashrc_file" ]; then
        if ! grep -q "alias $COMMAND_NAME=" "$bashrc_file"; then
            echo "" >> "$bashrc_file"
            echo "# MineAdmin 管理面板命令" >> "$bashrc_file"
            echo "alias $COMMAND_NAME='$COMMAND_SCRIPT'" >> "$bashrc_file"
            config_updated=true
        fi
    fi
    
    # 添加到zshrc
    if [ -f "$zshrc_file" ]; then
        if ! grep -q "alias $COMMAND_NAME=" "$zshrc_file"; then
            echo "" >> "$zshrc_file"
            echo "# MineAdmin 管理面板命令" >> "$zshrc_file"
            echo "alias $COMMAND_NAME='$COMMAND_SCRIPT'" >> "$zshrc_file"
            config_updated=true
        fi
    fi
    
    print_success "全局命令安装完成！"
    echo ""
    echo -e "${CYAN}🎯 使用方法:${NC}"
    echo "在任何目录下，输入以下命令即可启动管理面板："
    echo -e "${GREEN}  $COMMAND_NAME${NC}"
    echo ""
    if [ "$config_updated" = true ]; then
        echo -e "${YELLOW}📝 注意: 配置已更新，请重新加载shell配置${NC}"
        echo "   - Bash: source ~/.bashrc"
        echo "   - Zsh:  source ~/.zshrc"
    fi
}

# 卸载全局命令
uninstall_global_command() {
    print_info "正在卸载全局命令 '$COMMAND_NAME'..."
    
    # 删除命令脚本
    if [ -f "$COMMAND_SCRIPT" ]; then
        if [ -w "$INSTALL_DIR" ]; then
            rm -f "$COMMAND_SCRIPT"
            print_success "命令脚本已删除"
        else
            sudo rm -f "$COMMAND_SCRIPT"
            print_success "使用sudo权限删除命令脚本"
        fi
    else
        print_warning "命令脚本不存在"
    fi
    
    # 从shell配置文件中移除别名
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    local config_updated=false
    
    # 从bashrc中移除
    if [ -f "$bashrc_file" ]; then
        if grep -q "alias $COMMAND_NAME=" "$bashrc_file"; then
            sed -i "/alias $COMMAND_NAME=/d" "$bashrc_file"
            sed -i "/# MineAdmin 管理面板命令/d" "$bashrc_file"
            config_updated=true
        fi
    fi
    
    # 从zshrc中移除
    if [ -f "$zshrc_file" ]; then
        if grep -q "alias $COMMAND_NAME=" "$zshrc_file"; then
            sed -i "/alias $COMMAND_NAME=/d" "$zshrc_file"
            sed -i "/# MineAdmin 管理面板命令/d" "$zshrc_file"
            config_updated=true
        fi
    fi
    
    print_success "全局命令卸载完成！"
    
    if [ "$config_updated" = true ]; then
        echo ""
        print_info "配置已更新，请重新加载shell配置"
    fi
}

# 检查命令状态
check_command_status() {
    print_info "全局命令状态检查:"
    echo ""
    echo -e "${WHITE}命令名称:${NC} $COMMAND_NAME"
    echo -e "${WHITE}命令脚本:${NC} $COMMAND_SCRIPT"
    echo -e "${WHITE}项目路径:${NC} $PROJECT_ROOT"
    echo -e "${WHITE}系统架构:${NC} $ARCH"
    echo -e "${WHITE}安装目录:${NC} $INSTALL_DIR"
    echo ""
    
    # 检查命令脚本是否存在
    if [ -f "$COMMAND_SCRIPT" ]; then
        print_success "命令脚本存在"
        if [ -x "$COMMAND_SCRIPT" ]; then
            print_success "命令脚本可执行"
        else
            print_error "命令脚本不可执行"
        fi
    else
        print_error "命令脚本不存在"
    fi
    
    # 检查命令是否可用
    if command -v "$COMMAND_NAME" &> /dev/null; then
        print_success "命令 '$COMMAND_NAME' 可用"
    else
        print_warning "命令 '$COMMAND_NAME' 不可用"
        echo "请重新加载shell配置或使用完整路径: $COMMAND_SCRIPT"
    fi
}

# 询问是否安装插件
ask_install_plugins() {
    echo ""
    echo -e "${WHITE}🔌 插件安装${NC}"
    echo "系统初始化完毕，swoole-cli 已全局可用"
    echo ""
    
    # 获取可用插件列表
    print_info "正在获取可用插件列表..."
    
    # 这里可以添加获取插件列表的逻辑
    # 暂时使用示例插件
    local available_plugins=(
        "jileapp/cms - CMS内容管理插件"
        "jileapp/shop - 商城插件"
        "jileapp/blog - 博客插件"
    )
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_plugins$$
    
    # 构建插件菜单选项
    local menu_options=""
    for i in "${!available_plugins[@]}"; do
        menu_options="$menu_options $((i+1)) \"${available_plugins[$i]}\""
    done
    menu_options="$menu_options 0 \"跳过插件安装\""
    
    # 显示插件选择菜单
    eval dialog --title "插件安装" \
         --backtitle "MineAdmin 管理工具" \
         --menu "请选择要安装的插件：" 15 70 10 $menu_options 2> "$tempfile"
    
    # 读取选择结果
    local plugin_choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$plugin_choice" ]; then
        print_info "取消插件安装"
        return
    fi
    
    if [[ "$plugin_choice" == "0" ]]; then
        print_info "跳过插件安装"
        return
    fi
    
    if [[ "$plugin_choice" -ge 1 && "$plugin_choice" -le ${#available_plugins[@]} ]]; then
        local selected_plugin="${available_plugins[$((plugin_choice-1))]}"
        local plugin_name=$(echo "$selected_plugin" | cut -d' ' -f1)
        
        echo ""
        echo -e "${WHITE}选择的插件:${NC} $selected_plugin"
        echo ""
        echo -e "${YELLOW}插件安装命令:${NC}"
        echo "swoole-cli -d swoole.use_shortname='Off' bin/hyperf.php mine-extension:install $plugin_name -y"
        echo ""
        
        # 使用dialog确认安装
        dialog --title "确认安装插件" \
               --backtitle "MineAdmin 管理工具" \
               --yesno "确认安装此插件吗？\n\n插件: $selected_plugin" 8 60
        
        if [ $? -eq 0 ]; then
            print_info "正在安装插件: $plugin_name"
            
                    # 进入容器执行插件安装命令
        cd "$PROJECT_ROOT"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env exec -T server-app swoole-cli -d swoole.use_shortname='Off' bin/hyperf.php mine-extension:install "$plugin_name" -y
            
            if [ $? -eq 0 ]; then
                print_success "插件安装成功: $plugin_name"
            else
                print_error "插件安装失败: $plugin_name"
            fi
        else
            print_info "取消插件安装"
        fi
    else
        print_error "无效选择"
    fi
}

# 容器导出功能
export_containers() {
    print_info "容器导出功能"
    
    # 创建images目录
    local images_dir="$PROJECT_ROOT/docker/images"
    if [ ! -d "$images_dir" ]; then
        mkdir -p "$images_dir"
        print_success "创建images目录: $images_dir"
    fi
    
    # 获取当前运行的容器和镜像
    local running_containers=()
    local container_ids=()
    
    # 获取docker-compose项目中的镜像
    cd "$PROJECT_ROOT"
    print_info "获取MineAdmin项目镜像..."
    
    # 获取docker-compose服务使用的镜像
    local compose_images=()
    print_info "正在获取docker-compose镜像列表..."
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            compose_images+=("$line")
            print_info "找到镜像: $line"
        fi
    done < <(docker-compose -f docker/docker-compose.yml --env-file server-app/.env config --images 2>/dev/null)
    
    print_info "找到 ${#compose_images[@]} 个compose镜像"
    
    # 如果没有找到compose镜像，获取所有Docker镜像
    if [ ${#compose_images[@]} -eq 0 ]; then
        print_info "未找到compose镜像，显示所有可用镜像..."
        
        while IFS= read -r line; do
            if [[ $line =~ ^[a-zA-Z0-9]+ ]]; then
                local image_id=$(echo "$line" | awk '{print $3}')
                local image_name=$(echo "$line" | awk '{print $1 ":" $2}')
                
                if [[ -n "$image_id" && -n "$image_name" && "$image_name" != "<none>:<none>" ]]; then
                    running_containers+=("$image_name")
                    container_ids+=("$image_name")
                fi
            fi
        done < <(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | tail -n +2)
    else
        # 使用compose镜像
        for image in "${compose_images[@]}"; do
            if [[ -n "$image" ]]; then
                running_containers+=("$image")
                container_ids+=("$image")
            fi
        done
    fi
    
    if [ ${#running_containers[@]} -eq 0 ]; then
        print_error "未找到可导出的容器或镜像"
        return 1
    fi
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_export$$
    
    # 显示容器选择菜单
    dialog --title "Select Containers to Export" \
           --backtitle "MineAdmin Management Tool" \
           --checklist "Please select containers to export (space to select, enter to confirm):" 20 80 15 \
           "${running_containers[0]}" "" off \
           "${running_containers[1]}" "" off \
           "${running_containers[2]}" "" off \
           "${running_containers[3]}" "" off 2> "$tempfile"
    
    # 读取选择结果
    local selected_containers=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$selected_containers" ]; then
        print_info "取消容器导出"
        return
    fi
    
    # 显示导出进度
    print_info "开始导出选中的容器..."
    echo ""
    
    local export_count=0
    local success_count=0
    
    for container in $selected_containers; do
        export_count=$((export_count + 1))
        
        # 找到对应的镜像名称
        local image_name=""
        for i in "${!running_containers[@]}"; do
            if [[ "${running_containers[$i]}" == "$container" ]]; then
                image_name="${container_ids[$i]}"
                break
            fi
        done
        
        if [ -z "$image_name" ]; then
            print_error "未找到镜像名称: $container"
            continue
        fi
        
        # 生成导出文件名
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local safe_name=$(echo "$container" | sed 's/[^a-zA-Z0-9._-]//g' | sed 's/[:]/_/g')
        local export_file="$images_dir/${safe_name}_${timestamp}.tar"
        
        echo -e "${BLUE}[$export_count] 导出:${NC} $container"
        echo -e "${WHITE}文件:${NC} $export_file"
        
        # 执行导出
        if docker save -o "$export_file" "$image_name" 2>/dev/null; then
            local file_size=$(du -h "$export_file" | cut -f1)
            print_success "导出成功: $file_size"
            success_count=$((success_count + 1))
        else
            print_error "导出失败"
        fi
        
        echo ""
    done
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_success "容器导出完成！"
    echo -e "${WHITE}导出目录:${NC} $images_dir"
    echo -e "${WHITE}成功导出:${NC} $success_count/$export_count"
    echo ""
    
    # 显示导出的文件列表
    if [ $success_count -gt 0 ]; then
        echo -e "${WHITE}导出的文件:${NC}"
        ls -lh "$images_dir"/*.tar 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    fi
}

# 检查镜像冲突
check_image_conflicts() {
    local file_path="$1"
    local conflicts=()
    
    # 获取tar文件中的镜像信息
    local tar_images=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^Loaded\ image:\ (.+)$ ]]; then
            local image_name="${BASH_REMATCH[1]}"
            tar_images+=("$image_name")
        fi
    done < <(docker load -i "$file_path" 2>&1 | grep "Loaded image:")
    
    # 检查每个镜像是否已存在
    for img in "${tar_images[@]}"; do
        if docker images "$img" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$img"; then
            conflicts+=("$img")
        fi
    done
    
    echo "${conflicts[@]}"
}

# 记录镜像导入历史
record_import_history() {
    local imported_images=("$@")
    local history_file="$PROJECT_ROOT/docker/images/import_history.log"
    
    if [ ${#imported_images[@]} -gt 0 ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] 导入镜像: ${imported_images[*]}" >> "$history_file"
    fi
}

# 查看镜像导入历史
show_import_history() {
    local history_file="$PROJECT_ROOT/docker/images/import_history.log"
    
    if [ ! -f "$history_file" ]; then
        print_info "暂无导入历史记录"
        return
    fi
    
    echo -e "${WHITE}镜像导入历史记录:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    tail -20 "$history_file" | while read -r line; do
        echo "  $line"
    done
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 容器导入功能
import_containers() {
    print_info "容器导入功能"
    
    # 检查images目录
    local images_dir="$PROJECT_ROOT/docker/images"
    if [ ! -d "$images_dir" ]; then
        print_error "images目录不存在: $images_dir"
        print_info "请先导出一些容器镜像"
        return 1
    fi
    
    # 获取可导入的镜像文件
    local image_files=()
    local file_paths=()
    local file_sizes=()
    
    while IFS= read -r -d '' file; do
        if [[ "$file" == *.tar ]]; then
            local filename=$(basename "$file")
            local filesize=$(du -h "$file" | cut -f1)
            local filesize_bytes=$(du -b "$file" | cut -f1)
            image_files+=("$filename")
            file_paths+=("$file")
            file_sizes+=("$filesize")
        fi
    done < <(find "$images_dir" -name "*.tar" -print0 2>/dev/null)
    
    if [ ${#image_files[@]} -eq 0 ]; then
        print_error "未找到可导入的镜像文件"
        print_info "请先导出一些容器镜像到: $images_dir"
        return 1
    fi
    
    # 显示可导入的文件列表
    echo -e "${WHITE}可导入的镜像文件:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "%-4s %-50s %-15s %s\n" "序号" "文件名" "大小" "路径"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for i in "${!image_files[@]}"; do
        printf "%-4s %-50s %-15s %s\n" "$((i+1))" "${image_files[$i]}" "${file_sizes[$i]}" "$(dirname "${file_paths[$i]}")"
    done
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 提供导入选项
    echo -e "${WHITE}导入选项:${NC}"
    echo "1. 选择性导入 - 手动选择要导入的文件"
    echo "2. 批量导入 - 导入所有文件"
    echo "3. 智能导入 - 只导入MineAdmin相关镜像"
    echo ""
    echo -e "${CYAN}请选择导入模式 (1-3):${NC}"
    read -r import_mode
    
    case $import_mode in
        1)
            # 选择性导入 - 继续原有的dialog选择
            ;;
        2)
            # 批量导入 - 选择所有文件
            selected_files=()
            for i in "${!image_files[@]}"; do
                local display_name="${image_files[$i]} (${file_sizes[$i]})"
                selected_files+=("$display_name")
            done
            print_info "已选择所有文件进行批量导入"
            ;;
        3)
            # 智能导入 - 只导入MineAdmin相关镜像
            selected_files=()
            for i in "${!image_files[@]}"; do
                if [[ "${image_files[$i]}" =~ mineadmin ]]; then
                    local display_name="${image_files[$i]} (${file_sizes[$i]})"
                    selected_files+=("$display_name")
                fi
            done
            if [ ${#selected_files[@]} -eq 0 ]; then
                print_warning "未找到MineAdmin相关镜像文件"
                print_info "切换到选择性导入模式"
            else
                print_info "已选择MineAdmin相关镜像进行智能导入"
            fi
            ;;
        *)
            print_info "使用默认的选择性导入模式"
            ;;
    esac
    
    # 如果没有预选文件，则使用dialog选择
    if [ ${#selected_files[@]} -eq 0 ]; then
        # 创建临时文件存储选择
        local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_import$$
        
        # 构建文件选择菜单选项（支持多选）
        local menu_options=()
        for i in "${!image_files[@]}"; do
            local display_name="${image_files[$i]} (${file_sizes[$i]})"
            menu_options+=("$display_name" "" "off")
        done
        
        # 显示文件选择菜单
        dialog --title "选择要导入的镜像文件" \
               --backtitle "MineAdmin 管理工具" \
               --checklist "请选择要导入的镜像文件（空格选择，回车确认）：" 20 80 15 \
               "${menu_options[@]}" 2> "$tempfile"
        
        # 读取选择结果
        local dialog_result=$(cat "$tempfile" 2>/dev/null)
        rm -f "$tempfile"
        
        if [ -z "$dialog_result" ]; then
            print_info "取消容器导入"
            return
        fi
        
        # 将dialog结果转换为数组
        selected_files=()
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                selected_files+=("$line")
            fi
        done <<< "$dialog_result"
    fi
    
    # 显示导入预览
    print_info "导入预览 - 将要导入的镜像文件:"
    echo ""
    local preview_count=0
    for file_display in "${selected_files[@]}"; do
        preview_count=$((preview_count + 1))
        echo -e "${BLUE}[$preview_count]${NC} $file_display"
    done
    echo ""
    
    # 确认导入
    echo -e "${YELLOW}确认导入以上 $preview_count 个镜像文件？(y/N):${NC}"
    read -r confirm_import
    if [[ ! "$confirm_import" =~ ^[Yy]$ ]]; then
        print_info "取消导入操作"
        return
    fi
    
    # 显示导入进度
    print_info "开始导入选中的镜像文件..."
    echo ""
    
    local import_count=0
    local success_count=0
    local imported_images=()
    local failed_files=()
    
    for file_display in "${selected_files[@]}"; do
        import_count=$((import_count + 1))
        
        # 找到对应的文件路径
        local file_path=""
        local file_index=-1
        for i in "${!image_files[@]}"; do
            local display_name="${image_files[$i]} (${file_sizes[$i]})"
            if [[ "$display_name" == "$file_display" ]]; then
                file_path="${file_paths[$i]}"
                file_index=$i
                break
            fi
        done
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            print_error "未找到文件: $file_display"
            continue
        fi
        
        echo -e "${BLUE}[$import_count] 导入:${NC} ${image_files[$file_index]}"
        echo -e "${WHITE}文件:${NC} $file_path"
        echo -e "${WHITE}大小:${NC} ${file_sizes[$file_index]}"
        
        # 检查文件完整性
        print_info "检查文件完整性..."
        if ! tar -tf "$file_path" > /dev/null 2>&1; then
            print_error "文件损坏或格式不正确"
            continue
        fi
        
        # 获取导入前的镜像列表
        local before_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null)
        
        # 执行导入
        print_info "正在导入镜像..."
        local import_output=$(docker load -i "$file_path" 2>&1)
        local import_result=$?
        
        if [ $import_result -eq 0 ]; then
            # 获取导入后的镜像列表
            local after_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null)
            
            # 找出新导入的镜像
            local new_images=()
            while IFS= read -r image; do
                if [[ -n "$image" && ! "$before_images" =~ "$image" ]]; then
                    new_images+=("$image")
                fi
            done <<< "$after_images"
            
            if [ ${#new_images[@]} -gt 0 ]; then
                print_success "导入成功"
                echo -e "${WHITE}导入的镜像:${NC}"
                for img in "${new_images[@]}"; do
                    echo "  ✅ $img"
                    imported_images+=("$img")
                done
                success_count=$((success_count + 1))
            else
                print_warning "导入完成但未检测到新镜像"
                echo -e "${WHITE}导入输出:${NC} $import_output"
                failed_files+=("${image_files[$file_index]} - 未检测到新镜像")
            fi
        else
            print_error "导入失败"
            echo -e "${WHITE}错误信息:${NC} $import_output"
            failed_files+=("${image_files[$file_index]} - 导入失败")
        fi
        
        echo ""
    done
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_success "容器导入完成！"
    echo -e "${WHITE}成功导入:${NC} $success_count/$import_count"
    
    # 显示失败的文件
    if [ ${#failed_files[@]} -gt 0 ]; then
        echo -e "${WHITE}失败的文件:${NC} ${#failed_files[@]} 个"
        for failed in "${failed_files[@]}"; do
            echo "  ❌ $failed"
        done
    fi
    echo ""
    
    # 显示导入的镜像信息
    if [ ${#imported_images[@]} -gt 0 ]; then
        echo -e "${WHITE}导入的镜像列表:${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf "%-50s %-15s %-20s %s\n" "镜像名称" "大小" "创建时间" "ID"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        for img in "${imported_images[@]}"; do
            local img_info=$(docker images "$img" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}\t{{.ID}}" 2>/dev/null | tail -n +2)
            if [[ -n "$img_info" ]]; then
                printf "%-50s %-15s %-20s %s\n" $img_info
            else
                printf "%-50s %-15s %-20s %s\n" "$img" "未知" "未知" "未知"
            fi
        done
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    # 检查是否有MineAdmin相关镜像
    local mineadmin_images=()
    for img in "${imported_images[@]}"; do
        if [[ "$img" =~ mineadmin ]]; then
            mineadmin_images+=("$img")
        fi
    done
    
    # 记录导入历史
    if [ ${#imported_images[@]} -gt 0 ]; then
        record_import_history "${imported_images[@]}"
    fi
    
    # 询问是否启动服务
    if [ $success_count -gt 0 ]; then
        if [ ${#mineadmin_images[@]} -gt 0 ]; then
            echo -e "${WHITE}检测到MineAdmin相关镜像:${NC}"
            for img in "${mineadmin_images[@]}"; do
                echo "  🎯 $img"
            done
            echo ""
            
            dialog --title "启动MineAdmin服务" \
                   --backtitle "MineAdmin 管理工具" \
                   --yesno "镜像导入完成，是否立即启动MineAdmin服务？\n\n检测到MineAdmin相关镜像，建议启动服务进行验证。" 10 70
            
            if [ $? -eq 0 ]; then
                print_info "正在启动MineAdmin服务..."
                start_services
            else
                print_info "您可以稍后使用 'hook start' 命令启动服务"
            fi
        else
            dialog --title "镜像导入完成" \
                   --backtitle "MineAdmin 管理工具" \
                   --yesno "镜像导入完成，是否启动MineAdmin服务？\n\n注意：导入的镜像可能不是MineAdmin相关镜像。" 8 70
            
            if [ $? -eq 0 ]; then
                print_info "正在启动MineAdmin服务..."
                start_services
            else
                print_info "您可以稍后使用 'hook start' 命令启动服务"
            fi
        fi
    fi
    
    # 镜像导入验证
    if [ ${#imported_images[@]} -gt 0 ]; then
        echo -e "${WHITE}🔍 镜像导入验证:${NC}"
        echo ""
        
        local valid_count=0
        for img in "${imported_images[@]}"; do
            echo -e "${BLUE}验证镜像:${NC} $img"
            
            # 检查镜像是否存在
            if docker images "$img" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$img"; then
                # 检查镜像是否可以正常拉取信息
                if docker inspect "$img" > /dev/null 2>&1; then
                    print_success "镜像验证通过"
                    valid_count=$((valid_count + 1))
                else
                    print_warning "镜像存在但无法获取详细信息"
                fi
            else
                print_error "镜像验证失败 - 镜像不存在"
            fi
            echo ""
        done
        
        echo -e "${WHITE}验证结果:${NC} $valid_count/${#imported_images[@]} 个镜像验证通过"
        echo ""
    fi
    
    # 提供后续操作建议
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}💡 后续操作建议:${NC}"
    echo "1. 使用 'hook status' 查看服务状态"
    echo "2. 使用 'hook logs' 查看容器日志"
    echo "3. 使用 'docker images' 查看所有镜像"
    echo "4. 使用 'hook start' 启动所有服务"
    echo "5. 使用 'docker run --rm <镜像名> --help' 测试镜像"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 查看导出的镜像文件
list_exported_images() {
    print_info "查看导出的镜像文件"
    
    local images_dir="$PROJECT_ROOT/docker/images"
    if [ ! -d "$images_dir" ]; then
        print_error "images目录不存在: $images_dir"
        return 1
    fi
    
    local image_files=($(find "$images_dir" -name "*.tar" -type f 2>/dev/null))
    
    if [ ${#image_files[@]} -eq 0 ]; then
        print_info "未找到导出的镜像文件"
        return 0
    fi
    
    echo -e "${WHITE}导出的镜像文件列表:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "%-50s %-15s %-20s %s\n" "文件名" "大小" "修改时间" "路径"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for file in "${image_files[@]}"; do
        local filename=$(basename "$file")
        local filesize=$(du -h "$file" | cut -f1)
        # 检测系统类型，使用不同的stat参数
        local modtime=""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            modtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
        else
            # Linux
            modtime=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        fi
        local filepath=$(dirname "$file")
        
        printf "%-50s %-15s %-20s %s\n" "$filename" "$filesize" "$modtime" "$filepath"
    done
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}总计:${NC} ${#image_files[@]} 个文件"
    
    # 计算总大小
    local total_size=$(du -sh "$images_dir" 2>/dev/null | cut -f1)
    echo -e "${WHITE}总大小:${NC} $total_size"
}

# 清理导出的镜像文件
clean_exported_images() {
    print_info "清理导出的镜像文件"
    
    local images_dir="$PROJECT_ROOT/docker/images"
    if [ ! -d "$images_dir" ]; then
        print_error "images目录不存在: $images_dir"
        return 1
    fi
    
    local image_files=($(find "$images_dir" -name "*.tar" -type f 2>/dev/null))
    
    if [ ${#image_files[@]} -eq 0 ]; then
        print_info "未找到可清理的镜像文件"
        return 0
    fi
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_clean_images$$
    
    # 构建文件选择菜单选项（支持多选）
    local menu_options=""
    for file in "${image_files[@]}"; do
        local filename=$(basename "$file")
        local filesize=$(du -h "$file" | cut -f1)
        menu_options="$menu_options \"$filename ($filesize)\" \"\" off"
    done
    
    # 显示文件选择菜单
    eval dialog --title "Select Images to Clean" \
         --backtitle "MineAdmin Management Tool" \
         --checklist "Please select image files to clean (space to select, enter to confirm):" 20 80 15 $menu_options 2> "$tempfile"
    
    # 读取选择结果
    local selected_files=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$selected_files" ]; then
        print_info "取消清理操作"
        return
    fi
    
    # 确认删除
    dialog --title "Confirm Delete" \
           --backtitle "MineAdmin Management Tool" \
           --yesno "Are you sure you want to delete the selected image files?\n\nThis action cannot be undone!" 8 60
    
    if [ $? -ne 0 ]; then
        print_info "取消删除操作"
        return
    fi
    
    # 执行删除
    local delete_count=0
    local success_count=0
    
    for file_display in $selected_files; do
        delete_count=$((delete_count + 1))
        
        # 找到对应的文件路径
        local file_path=""
        for file in "${image_files[@]}"; do
            local filename=$(basename "$file")
            local filesize=$(du -h "$file" | cut -f1)
            local display_name="$filename ($filesize)"
            
            if [[ "$display_name" == "$file_display" ]]; then
                file_path="$file"
                break
            fi
        done
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            print_error "未找到文件: $file_display"
            continue
        fi
        
        echo -e "${BLUE}[$delete_count] 删除:${NC} $(basename "$file_path")"
        
        if rm -f "$file_path"; then
            print_success "删除成功"
            success_count=$((success_count + 1))
        else
            print_error "删除失败"
        fi
    done
    
    echo ""
    print_success "清理完成！"
    echo -e "${WHITE}成功删除:${NC} $success_count/$delete_count"
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📖 MineAdmin 管理工具帮助${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}🚀 快速开始:${NC}"
    echo "1. 运行系统兼容性检测: hook check"
    echo "2. 执行一键安装部署: hook install"
    echo "3. 前端构建: hook build"
    echo "4. 启动服务: hook start"
    echo ""
    echo -e "${BLUE}⚙️  服务管理:${NC}"
    echo "- 启动所有服务: hook start"
    echo "- 选择性启动服务: hook sestart"
    echo "- 停止所有服务: hook stop"
    echo "- 重启所有服务: hook restart"
    echo "- 查看服务状态: hook status"
    echo "- 查看容器日志: hook logs"
    echo "- 查看系统资源: hook resources"
    echo ""
    echo -e "${BLUE}🔧 配置管理:${NC}"
    echo "- 重新生成配置: hook config"
    echo "- 交互式生成配置: hook generate-config"
    echo "- 修改密码: hook password"
    echo "- 查看配置信息: hook info"
    echo "- 查看已安装插件: hook plugins"
    echo "- 查看网络连接: hook network"
    echo ""
    echo -e "${BLUE}📦 容器管理:${NC}"
    echo "- 容器导出功能: hook export"
    echo "- 容器导入功能: hook import"
    echo "- 查看导入历史: hook import-history"
    echo "- 查看导出镜像: hook list-images"
    echo "- 清理导出镜像: hook clean-images"
    echo ""
    echo -e "${BLUE}🧹 清理维护:${NC}"
    echo "- 清理Docker缓存: hook clean"
    echo "- 完全卸载: hook uninstall"
    echo ""
    echo -e "${BLUE}🔗 全局命令:${NC}"
    echo "- 安装全局命令: hook setup"
    echo "- 卸载全局命令: hook remove"
    echo "- 检查命令状态: hook test"
    echo ""
    echo -e "${BLUE}📋 系统要求:${NC}"
    echo "- Ubuntu 24.04 LTS (推荐)"
    echo "- x86_64 或 ARM64 架构"
    echo "- 至少2GB内存"
    echo "- 至少10GB可用磁盘空间"
    echo "- Node.js 22.x"
    echo "- pnpm 10.x"
    echo ""
    echo -e "${BLUE}🌐 访问地址:${NC}"
    echo "- 后端API: http://服务器IP:9501"
    echo "- 前端生产: http://服务器IP:80"
    echo ""
    echo -e "${BLUE}💡 使用提示:${NC}"
    echo "- 直接使用 'hook' 命令进入交互式菜单"
    echo "- 使用 'hook <命令>' 直接执行对应功能"
    echo "- 使用 'hook help' 查看此帮助信息"
    echo "- 生产模式：只映射dist目录，性能更优"
    echo "- 开发建议：直接在宿主机运行 'pnpm run dev'"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 处理hook命令
handle_hook_command() {
    local command=$1
    
    case $command in
        check)
            check_system_compatibility
            ;;
        install)
            install_mineadmin
            ;;
        web)
            print_info "Web模式选择功能已移除，现在只支持生产模式"
            print_info "如需开发，请在宿主机运行: cd web && pnpm run dev"
            ;;
        build)
            build_frontend
            ;;
        start)
            start_services
            ;;
        sestart)
            selective_start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_service_status
            ;;
        logs)
            show_container_logs
            ;;
        resources)
            show_system_resources
            ;;
        network)
            show_network_connections
            ;;
        config)
            regenerate_config
            ;;
        generate-config)
            generate_config_interactive
            ;;
        password)
            change_passwords
            ;;
        info)
            show_config_info
            ;;
        plugins)
            show_installed_plugins
            ;;
        autostart)
            setup_autostart
            ;;
        export)
            export_containers
            ;;
        import)
            import_containers
            ;;
        import-history)
            show_import_history
            ;;
        list-images)
            list_exported_images
            ;;
        clean-images)
            clean_exported_images
            ;;
        clean)
            clean_docker_cache
            ;;
        uninstall)
            uninstall_mineadmin
            ;;
        setup)
            install_global_command
            ;;
        remove)
            uninstall_global_command
            ;;
        test)
            check_command_status
            ;;
        help)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo "使用 'hook help' 查看可用命令"
            ;;
    esac
}

# 主函数
main() {
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        exit 1
    fi
    
    # 检查项目路径
    if [ ! -d "$PROJECT_ROOT" ]; then
        print_error "项目路径不存在: $PROJECT_ROOT"
        exit 1
    fi
    
    # 如果提供了参数，直接执行对应的hook命令
    if [ $# -gt 0 ]; then
        handle_hook_command "$1"
        exit 0
    fi
    
    # 没有参数时，显示命令菜单
    show_command_menu
}

# 运行主函数
main "$@"
