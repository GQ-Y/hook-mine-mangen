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
    
    # 黑客科技风格的ASCII艺术标题
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}██╗   ██╗██╗███████╗███████╗██████╗  ██████╗ ███████╗██╗  ██╗${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}██║   ██║██║╚════██║╚════██║██╔══██╗██╔═══██╗██╔════╝╚██╗██╔╝${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}██║   ██║██║ █████╔╝ █████╔╝██║  ██║██║   ██║███████╗ ╚███╔╝ ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}╚██╗ ██╔╝██║ ╚═══██╗ ╚═══██╗ ██║  ██║██║   ██║╚════██║ ██╔██╗ ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN} ╚████╔╝ ██║██████╔╝██████╔╝ ██████╔╝╚██████╔╝███████║██╔╝ ██╗${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}  ╚═══╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}                    [ MINEADMIN 终端控制系统 v2.0 ]                    ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 系统状态栏
    echo -e "${BLUE}┌─ [ 系统状态 ] ──────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${CYAN}●${NC} ${WHITE}终端: ${GREEN}活跃${NC} ${BLUE}│${NC} ${CYAN}●${NC} ${WHITE}Docker: ${GREEN}就绪${NC} ${BLUE}│${NC} ${CYAN}●${NC} ${WHITE}网络: ${GREEN}在线${NC} ${BLUE}│${NC} ${CYAN}●${NC} ${WHITE}安全: ${GREEN}已启用${NC} ${BLUE}│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # 分割线
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # 主菜单区域
    echo -e "${MAGENTA}📦 部署管理${NC}"
    echo -e "${CYAN}[01]${NC} ${WHITE}./docker/mineadmin.sh check${NC}    ${GREEN}▶${NC} ${YELLOW}系统兼容性检测${NC}"
    echo -e "${CYAN}[02]${NC} ${WHITE}./docker/mineadmin.sh install${NC}  ${GREEN}▶${NC} ${YELLOW}一键安装部署${NC}"
    echo -e "${CYAN}[03]${NC} ${WHITE}./docker/mineadmin.sh build${NC}    ${GREEN}▶${NC} ${YELLOW}前端构建过程${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${BLUE}🚀 服务管理${NC}"
    echo -e "${CYAN}[04]${NC} ${WHITE}./docker/mineadmin.sh start${NC}    ${GREEN}▶${NC} ${YELLOW}启动所有服务${NC}"
    echo -e "${CYAN}[05]${NC} ${WHITE}./docker/mineadmin.sh sestart${NC}  ${GREEN}▶${NC} ${YELLOW}选择性启动服务${NC}"
    echo -e "${CYAN}[06]${NC} ${WHITE}./docker/mineadmin.sh stop${NC}     ${GREEN}▶${NC} ${YELLOW}停止所有服务${NC}"
    echo -e "${CYAN}[07]${NC} ${WHITE}./docker/mineadmin.sh restart${NC}  ${GREEN}▶${NC} ${YELLOW}重启所有服务${NC}"
    echo -e "${CYAN}[08]${NC} ${WHITE}./docker/mineadmin.sh status${NC}   ${GREEN}▶${NC} ${YELLOW}服务状态监控${NC}"
    echo -e "${CYAN}[09]${NC} ${WHITE}./docker/mineadmin.sh logs${NC}     ${GREEN}▶${NC} ${YELLOW}容器日志查看器${NC}"
    echo -e "${CYAN}[10]${NC} ${WHITE}./docker/mineadmin.sh resources${NC}${GREEN}▶${NC} ${YELLOW}系统资源监控${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${GREEN}⚙️  配置管理${NC}"
    echo -e "${CYAN}[11]${NC} ${WHITE}./docker/mineadmin.sh network${NC}  ${GREEN}▶${NC} ${YELLOW}网络连接分析${NC}"
    echo -e "${CYAN}[12]${NC} ${WHITE}./docker/mineadmin.sh config${NC}   ${GREEN}▶${NC} ${YELLOW}重新生成配置${NC}"
    echo -e "${CYAN}[13]${NC} ${WHITE}./docker/mineadmin.sh generate-config${NC} ${GREEN}▶${NC} ${YELLOW}交互式配置生成器${NC}"
    echo -e "${CYAN}[14]${NC} ${WHITE}./docker/mineadmin.sh password${NC} ${GREEN}▶${NC} ${YELLOW}密码修改${NC}"
    echo -e "${CYAN}[15]${NC} ${WHITE}./docker/mineadmin.sh info${NC}     ${GREEN}▶${NC} ${YELLOW}配置信息${NC}"
    echo -e "${CYAN}[16]${NC} ${WHITE}./docker/mineadmin.sh plugins${NC}  ${GREEN}▶${NC} ${YELLOW}插件管理${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${YELLOW}📦 容器管理${NC}"
    echo -e "${CYAN}[17]${NC} ${WHITE}./docker/mineadmin.sh export${NC}   ${GREEN}▶${NC} ${YELLOW}容器导出功能${NC}"
    echo -e "${CYAN}[18]${NC} ${WHITE}./docker/mineadmin.sh import${NC}   ${GREEN}▶${NC} ${YELLOW}容器导入功能${NC}"
    echo -e "${CYAN}[19]${NC} ${WHITE}./docker/mineadmin.sh import-history${NC} ${GREEN}▶${NC} ${YELLOW}导入历史查看器${NC}"
    echo -e "${CYAN}[20]${NC} ${WHITE}./docker/mineadmin.sh list-images${NC} ${GREEN}▶${NC} ${YELLOW}导出镜像列表${NC}"
    echo -e "${CYAN}[21]${NC} ${WHITE}./docker/mineadmin.sh clean-images${NC} ${GREEN}▶${NC} ${YELLOW}清理导出镜像${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${PURPLE}☸️  K8s集群管理${NC}"
    echo -e "${CYAN}[22]${NC} ${WHITE}./docker/mineadmin.sh k8s${NC}         ${GREEN}▶${NC} ${YELLOW}K8s集群管理菜单${NC}"
    echo -e "${CYAN}[23]${NC} ${WHITE}./docker/mineadmin.sh k8s-deploy${NC}  ${GREEN}▶${NC} ${YELLOW}部署K8s集群${NC}"
    echo -e "${CYAN}[24]${NC} ${WHITE}./docker/mineadmin.sh k8s-status${NC}  ${GREEN}▶${NC} ${YELLOW}查看集群状态${NC}"
    echo -e "${CYAN}[25]${NC} ${WHITE}./docker/mineadmin.sh k8s-logs${NC}    ${GREEN}▶${NC} ${YELLOW}查看组件日志${NC}"
    echo -e "${CYAN}[26]${NC} ${WHITE}./docker/mineadmin.sh k8s-config${NC}  ${GREEN}▶${NC} ${YELLOW}生成配置文件${NC}"
    echo -e "${CYAN}[27]${NC} ${WHITE}./docker/mineadmin.sh k8s-diagnose${NC}  ${GREEN}▶${NC} ${YELLOW}诊断初始化问题${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${RED}🚀 项目初始化${NC}"
    echo -e "${CYAN}[27]${NC} ${WHITE}./docker/mineadmin.sh init${NC}     ${GREEN}▶${NC} ${YELLOW}从官方仓库初始化项目${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${WHITE}🧹 维护清理${NC}"
    echo -e "${CYAN}[28]${NC} ${WHITE}./docker/mineadmin.sh clean${NC}    ${GREEN}▶${NC} ${YELLOW}Docker缓存清理${NC}"
    echo -e "${CYAN}[29]${NC} ${WHITE}./docker/mineadmin.sh uninstall${NC}${GREEN}▶${NC} ${YELLOW}完全卸载${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${CYAN}🌐 全局命令${NC}"
    echo -e "${CYAN}[30]${NC} ${WHITE}./docker/mineadmin.sh setup${NC}    ${GREEN}▶${NC} ${YELLOW}安装全局命令${NC}"
    echo -e "${CYAN}[31]${NC} ${WHITE}./docker/mineadmin.sh remove${NC}   ${GREEN}▶${NC} ${YELLOW}卸载全局命令${NC}"
    echo -e "${CYAN}[32]${NC} ${WHITE}./docker/mineadmin.sh test${NC}     ${GREEN}▶${NC} ${YELLOW}检查命令状态${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${MAGENTA}❓ 帮助信息${NC}"
    echo -e "${CYAN}[28]${NC} ${WHITE}./docker/mineadmin.sh help${NC}     ${GREEN}▶${NC} ${YELLOW}详细帮助信息${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # 底部信息栏
    echo -e "${BLUE}💡 使用提示${NC}"
    echo -e "${WHITE}• 直接输入命令立即执行${NC}"
    echo -e "${WHITE}• 全局安装后使用 'hook <命令>' 简化操作${NC}"
    echo -e "${WHITE}• 执行 'hook help' 查看完整帮助文档${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # 示例命令区域
    echo -e "${GREEN}⚡ 快速示例${NC}"
    echo -e "${CYAN}$ ${WHITE}./docker/mineadmin.sh check${NC}   ${GREEN}│${NC} ${CYAN}$ ${WHITE}./docker/mineadmin.sh install${NC}   ${GREEN}│${NC} ${CYAN}$ ${WHITE}./docker/mineadmin.sh status${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # 状态指示器
    echo -e "${GREEN}📊 系统状态${NC}"
    echo -e "${CYAN}●${NC} ${WHITE}命令模式: ${GREEN}已启用${NC} ${GREEN}│${NC} ${CYAN}●${NC} ${WHITE}图形界面: ${RED}已禁用${NC} ${GREEN}│${NC} ${CYAN}●${NC} ${WHITE}安全状态: ${GREEN}已激活${NC}"
    echo ""
    
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # 闪烁的提示信息
    echo -e "${YELLOW}⚠️   按任意键退出终端界面${NC}"
    echo ""
    
    # 添加一些动态效果
    for i in {1..3}; do
        echo -ne "${CYAN}正在加载系统界面${NC}"
        for j in {1..$i}; do echo -n "."; done
        echo -ne "\r"
        sleep 0.3
    done
    echo -e "${GREEN}系统界面已就绪！${NC}"
    echo ""
    
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
    echo "  hook plugins  - 插件管理（扫描/安装/卸载）"
    echo ""
    echo -e "${MAGENTA}📦 容器管理:${NC}"
    echo "  hook export   - 容器导出功能"
    echo "  hook import   - 容器导入功能"
    echo "  hook import-history - 查看导入历史"
    echo "  hook list-images - 查看导出镜像"
    echo "  hook clean-images - 清理导出镜像"
    echo ""
    echo -e "${MAGENTA}☸️  K8s集群管理:${NC}"
    echo "  hook k8s      - K8s集群管理菜单"
    echo "  hook k8s-deploy - 部署K8s集群"
    echo "  hook k8s-status - 查看集群状态"
    echo "  hook k8s-logs - 查看组件日志"
    echo "  hook k8s-config - 生成配置文件"
    echo "  hook k8s-diagnose - 诊断初始化问题"
    echo ""
    echo -e "${MAGENTA}📥 项目初始化:${NC}"
    echo "  hook init      - 从官方仓库初始化项目"
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
    echo -e "${BLUE}[1/8] 检测操作系统...${NC}"
    
    # 检测WSL环境
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        echo -e "${WHITE}环境:${NC} Windows Subsystem for Linux (WSL)"
        print_success "WSL环境 - 支持运行"
    fi
    
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
            print_warning "非Ubuntu系统，可能不兼容"
        fi
    else
        print_warning "无法检测操作系统信息"
    fi
    
    echo -e "${BLUE}[2/8] 检测系统架构...${NC}"
    echo -e "${WHITE}架构:${NC} $ARCH"
    
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
        print_success "x86_64 架构 - 完全兼容"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        print_success "ARM64 架构 - 完全兼容"
    else
        print_warning "未知架构 $ARCH - 可能不兼容"
    fi
    
    echo -e "${BLUE}[3/8] 检测内存...${NC}"
    local mem_total=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        mem_total=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
    else
        # Linux
        mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    fi
    echo -e "${WHITE}总内存:${NC} ${mem_total}GB"
    
    if [[ $mem_total -ge 2 ]]; then
        print_success "内存充足 (≥2GB)"
    else
        print_error "内存不足 (<2GB)，建议至少2GB内存"
    fi
    
    echo -e "${BLUE}[4/8] 检测磁盘空间...${NC}"
    local disk_free=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        disk_free=$(df -g / | awk 'NR==2{print $4}')
    else
        # Linux
        disk_free=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    fi
    echo -e "${WHITE}可用空间:${NC} ${disk_free}GB"
    
    if [[ $disk_free -ge 10 ]]; then
        print_success "磁盘空间充足 (≥10GB可用)"
    else
        print_error "磁盘空间不足 (<10GB可用)，建议至少10GB可用空间"
    fi
    
    echo -e "${BLUE}[5/8] 检测网络连接...${NC}"
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
    
    echo -e "${BLUE}[6/8] 检测必要工具...${NC}"
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
    
    echo -e "${BLUE}[7/8] 检测Dialog工具...${NC}"
    if command -v dialog &> /dev/null; then
        local dialog_version=$(dialog --version 2>/dev/null | head -1)
        print_success "Dialog - 已安装"
        echo -e "${WHITE}版本:${NC} $dialog_version"
    else
        print_error "Dialog - 未安装"
        echo -e "${YELLOW}安装命令:${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install dialog"
        elif [[ -f /etc/debian_version ]]; then
            echo "  sudo apt-get update && sudo apt-get install -y dialog"
        elif [[ -f /etc/redhat-release ]]; then
            echo "  sudo yum install -y dialog"
        else
            echo "  请根据您的系统手动安装dialog"
        fi
    fi
    
    echo -e "${BLUE}[8/8] 检测Docker环境...${NC}"
    
    # 检查Docker是否安装
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
        print_success "Docker - 已安装"
        echo -e "${WHITE}版本:${NC} $docker_version"
        
        # 检查Docker是否可用
        if docker info > /dev/null 2>&1; then
            print_success "Docker - 运行正常"
        else
            print_warning "Docker - 未运行或无法访问"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo -e "${YELLOW}解决方法:${NC} 启动Docker Desktop应用"
            elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
                echo -e "${YELLOW}解决方法:${NC} 在Windows中启动Docker Desktop"
            else
                echo -e "${YELLOW}解决方法:${NC} 启动Docker服务"
            fi
        fi
        
        # 只在原生Linux系统下进行详细的服务检查
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # 检查是否为WSL环境
            local is_wsl=false
            if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
                is_wsl=true
            fi
            
            # 只在非WSL的Linux环境下进行systemctl检查
            if [[ "$is_wsl" == "false" ]]; then
            # 检查Docker服务状态
            if systemctl is-active --quiet docker 2>/dev/null; then
                print_success "Docker服务 - 正在运行"
            else
                print_warning "Docker服务 - 未运行"
                echo -e "${YELLOW}启动命令:${NC} sudo systemctl start docker"
            fi
            
            # 检查Docker开机自启动
            if systemctl is-enabled docker &> /dev/null; then
                local docker_autostart=$(systemctl is-enabled docker)
                if [[ "$docker_autostart" == "enabled" ]]; then
                    print_success "Docker开机自启动 - 已启用"
                else
                    print_warning "Docker开机自启动 - 已禁用"
                    echo -e "${YELLOW}启用命令:${NC} sudo systemctl enable docker"
                fi
            else
                print_warning "Docker开机自启动 - 状态未知"
            fi
            
            # 检查当前用户是否在docker组
            if groups $USER | grep -q docker; then
                print_success "用户权限 - 已加入docker组"
            else
                print_warning "用户权限 - 未加入docker组"
                echo -e "${YELLOW}添加命令:${NC} sudo usermod -aG docker $USER"
                echo -e "${YELLOW}注意:${NC} 需要重新登录才能生效"
            fi
            fi
        fi
    else
        print_error "Docker - 未安装"
        echo -e "${YELLOW}安装命令:${NC}"
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
            echo "  WSL环境: 请在Windows中安装Docker Desktop"
        else
            echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
            echo "  sudo sh get-docker.sh"
            echo "  sudo usermod -aG docker $USER"
        fi
    fi
    
    # 检查Docker Compose是否安装
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
        print_success "Docker Compose - 已安装"
        echo -e "${WHITE}版本:${NC} $compose_version"
    elif docker compose version &> /dev/null; then
        local compose_version=$(docker compose version --short 2>/dev/null)
        print_success "Docker Compose (插件) - 已安装"
        echo -e "${WHITE}版本:${NC} $compose_version"
    else
        print_error "Docker Compose - 未安装"
        echo -e "${YELLOW}安装命令:${NC}"
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
            echo "  WSL环境: Docker Compose通常随Docker Desktop一起安装"
        else
            echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
            echo "  sudo chmod +x /usr/local/bin/docker-compose"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 建议:${NC}"
    echo "1. 如果所有检测都通过，可以安全运行安装"
    echo "2. 如果有警告，建议先解决问题再安装"
    echo "3. 如果有错误，必须解决问题后才能安装"
    echo "4. Dialog未安装时，脚本将使用命令行模式"
    echo "5. Docker未安装时，安装过程会自动安装Docker"
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
    
    print_info "检测到架构: $(uname -m)，使用构建平台: $build_arch"
    
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
        echo "前端生产: http://localhost:10000"
        echo ""
        echo -e "${WHITE}📡 监听端口:${NC}"
        echo "9501 - 后端API服务"
        echo "9502 - WebSocket服务"
        echo "9509 - 通知服务"
        echo "10000   - 前端生产服务"
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
    # 检查Dialog是否可用
    if ! command -v dialog &> /dev/null; then
        print_warning "Dialog不可用，使用命令行模式查看日志"
        show_container_logs_cli
        return
    fi
    
    local containers=("MySQL" "Redis" "Server App" "Web Prod")
    local services=("mysql" "redis" "server-app" "web-prod")
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_logs$$
    
    # 检查终端大小
    local term_height=$(tput lines 2>/dev/null || echo 24)
    local term_width=$(tput cols 2>/dev/null || echo 80)
    
    # 计算合适的菜单大小
    local menu_height=$((term_height - 4))
    local menu_width=$((term_width - 4))
    
    # 确保最小尺寸
    if [ $menu_height -lt 8 ]; then
        menu_height=8
    fi
    if [ $menu_width -lt 50 ]; then
        menu_width=50
    fi
    
    # 显示容器选择菜单
    if ! dialog --title "查看容器日志" \
               --backtitle "MineAdmin 管理工具" \
               --menu "请选择要查看的容器日志：" $menu_height $menu_width 8 \
               1 "MySQL" \
               2 "Redis" \
               3 "Server App" \
               4 "Web Prod" 2> "$tempfile"; then
        print_warning "Dialog菜单显示失败，使用命令行模式"
        show_container_logs_cli
        return
    fi
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -n "$choice" ]; then
        local idx=$((choice-1))
        local container_name="${containers[$idx]}"
        local service_name="${services[$idx]}"
        
        # 切换到项目目录
        cd "$PROJECT_ROOT"
        
        # 检查服务是否运行
        if ! docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "$service_name.*Up"; then
            dialog --title "错误" \
                   --backtitle "MineAdmin 管理工具" \
                   --msgbox "服务 $service_name 未运行，无法查看日志" 8 60
            return 1
        fi
        
        # 创建临时日志文件
        local log_tempfile=$(mktemp 2>/dev/null) || log_tempfile=/tmp/mineadmin_log_${service_name}$$
        
        # 获取容器日志并保存到临时文件
        print_info "正在获取 $container_name 的日志..."
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env logs "$service_name" > "$log_tempfile" 2>&1
        
        # 检查日志文件是否为空
        if [ ! -s "$log_tempfile" ]; then
            echo "暂无日志内容" > "$log_tempfile"
        fi
        
        # 检查终端大小
        local term_height=$(tput lines 2>/dev/null || echo 24)
        local term_width=$(tput cols 2>/dev/null || echo 80)
        
        # 计算合适的对话框大小
        local dialog_height=$((term_height - 4))
        local dialog_width=$((term_width - 4))
        
        # 确保最小尺寸
        if [ $dialog_height -lt 10 ]; then
            dialog_height=10
        fi
        if [ $dialog_width -lt 40 ]; then
            dialog_width=40
        fi
        
        # 显示日志
        if ! dialog --title "容器日志 - $container_name" \
                   --backtitle "MineAdmin 管理工具" \
                   --textbox "$log_tempfile" $dialog_height $dialog_width 2>/dev/null; then
            print_warning "Dialog显示失败，使用命令行模式显示日志"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            cat "$log_tempfile"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        fi
        
        # 清理临时文件
        rm -f "$log_tempfile"
    else
        # 如果没有选择（Dialog不可用或用户取消），显示命令行版本的日志查看
        show_container_logs_cli
    fi
}

# 命令行版本查看容器日志
show_container_logs_cli() {
    echo -e "${WHITE}容器日志查看${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # 检查容器是否运行
    if ! docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "Up"; then
        print_error "没有运行中的容器，无法查看日志"
        return 1
    fi
    
    local containers=("MySQL" "Redis" "Server App" "Web Prod")
    local services=("mysql" "redis" "server-app" "web-prod")
    
    echo -e "${WHITE}可用的容器服务:${NC}"
    echo ""
    for i in "${!containers[@]}"; do
        local service_name="${services[$i]}"
        local container_name="${containers[$i]}"
        
        # 检查服务是否运行
        if docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "$service_name.*Up"; then
            echo -e "${GREEN}  $((i+1))) $container_name (运行中)${NC}"
        else
            echo -e "${RED}  $((i+1))) $container_name (未运行)${NC}"
        fi
    done
    echo ""
    
    echo -e "${CYAN}请选择要查看的容器日志 (1-${#containers[@]})，或输入 'all' 查看所有日志:${NC}"
    read -r choice
    
    if [[ "$choice" == "all" ]]; then
        # 查看所有运行中的容器日志
        echo ""
        print_info "正在获取所有容器的日志..."
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env logs
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    elif [[ "$choice" =~ ^[1-4]$ ]]; then
        local idx=$((choice-1))
        local container_name="${containers[$idx]}"
        local service_name="${services[$idx]}"
        
        # 检查服务是否运行
        if ! docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "$service_name.*Up"; then
            print_error "服务 $service_name 未运行，无法查看日志"
            return 1
        fi
        
        echo ""
        print_info "正在获取 $container_name 的日志..."
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        docker-compose -f docker/docker-compose.yml --env-file server-app/.env logs "$service_name"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        print_info "取消查看日志"
        return 0
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
WEB_PORT=10000
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
    echo -e "${WHITE}插件管理${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # 检查容器是否运行
    if ! docker-compose -f docker/docker-compose.yml --env-file server-app/.env ps | grep -q "server-app.*Up"; then
        print_error "后端服务未运行，无法管理插件"
        return 1
    fi
    
    print_info "正在扫描本地插件目录..."
    
    # 扫描插件目录
    local plugin_dir="$PROJECT_ROOT/server-app/plugin"
    local plugins=()
    local installed_plugins=()
    local uninstalled_plugins=()
    
    # 检查插件目录是否存在
    if [ ! -d "$plugin_dir" ]; then
        print_warning "插件目录不存在: $plugin_dir"
        echo ""
        echo -e "${WHITE}创建插件目录:${NC}"
        mkdir -p "$plugin_dir"
        print_success "插件目录已创建"
        return 0
    fi
    
    # 扫描插件目录
    while IFS= read -r -d '' plugin_path; do
        if [ -d "$plugin_path" ]; then
            # 获取插件标识（作者/插件名）
            local relative_path="${plugin_path#$plugin_dir/}"
            if [[ "$relative_path" =~ ^[^/]+/[^/]+$ ]]; then
                plugins+=("$relative_path")
                
                # 检查是否已安装（存在install.lock文件）
                if [ -f "$plugin_path/install.lock" ]; then
                    installed_plugins+=("$relative_path")
                else
                    uninstalled_plugins+=("$relative_path")
                fi
            fi
        fi
    done < <(find "$plugin_dir" -mindepth 2 -maxdepth 2 -type d -print0 2>/dev/null)
    
    # 显示扫描结果
    echo -e "${WHITE}扫描结果:${NC}"
    echo -e "${GREEN}已安装插件:${NC} ${#installed_plugins[@]} 个"
    echo -e "${YELLOW}未安装插件:${NC} ${#uninstalled_plugins[@]} 个"
    echo -e "${BLUE}总插件数:${NC} ${#plugins[@]} 个"
    echo ""
    
    # 显示已安装插件
    if [ ${#installed_plugins[@]} -gt 0 ]; then
        echo -e "${GREEN}已安装的插件:${NC}"
        for plugin in "${installed_plugins[@]}"; do
            echo "  ✅ $plugin"
        done
        echo ""
    fi
    
    # 显示未安装插件
    if [ ${#uninstalled_plugins[@]} -gt 0 ]; then
        echo -e "${YELLOW}未安装的插件:${NC}"
        for plugin in "${uninstalled_plugins[@]}"; do
            echo "  ⏳ $plugin"
        done
        echo ""
    fi
    
    # 如果没有找到插件
    if [ ${#plugins[@]} -eq 0 ]; then
        print_warning "未找到任何插件"
        echo ""
        echo -e "${WHITE}插件目录结构示例:${NC}"
        echo "  $plugin_dir/"
        echo "  ├── author1/"
        echo "  │   └── plugin1/"
        echo "  │       ├── install.lock  (已安装)"
        echo "  │       └── ..."
        echo "  └── author2/"
        echo "      └── plugin2/"
        echo "          └── ...  (未安装)"
        return 0
    fi
    
    # 询问是否要管理插件
    echo -e "${CYAN}是否要安装/卸载插件？(y/N):${NC}"
    read -r manage_plugins
    
    if [[ ! "$manage_plugins" =~ ^[Yy]$ ]]; then
        print_info "插件管理已取消"
        return 0
    fi
    
    # 调用插件管理函数
    manage_plugins_dialog "${plugins[@]}"
}

# 插件管理对话框
manage_plugins_dialog() {
    local plugins=("$@")
    local plugin_dir="$PROJECT_ROOT/server-app/plugin"
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_plugins$$
    
    # 构建插件选择菜单选项
    local menu_options=()
    for plugin in "${plugins[@]}"; do
        local plugin_path="$plugin_dir/$plugin"
        local status=""
        local description=""
        
        # 检查安装状态
        if [ -f "$plugin_path/install.lock" ]; then
            status="[已安装]"
            description="✅ $plugin $status"
        else
            status="[未安装]"
            description="⏳ $plugin $status"
        fi
        
        menu_options+=("$plugin" "$description" "off")
    done
    
    # 显示插件选择菜单
    dialog --title "插件管理" \
           --backtitle "MineAdmin 管理工具" \
           --checklist "请选择要管理的插件（空格选择，回车确认）：\n\n✅ 已安装的插件\n⏳ 未安装的插件" 20 80 15 \
           "${menu_options[@]}" 2> "$tempfile"
    
    # 读取选择结果
    local selected_plugins=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$selected_plugins" ]; then
        print_info "取消插件管理"
        return
    fi
    
    # 处理选中的插件
    local install_plugins=()
    local uninstall_plugins=()
    
    for plugin in $selected_plugins; do
        local plugin_path="$plugin_dir/$plugin"
        
        if [ -f "$plugin_path/install.lock" ]; then
            # 已安装的插件，需要先卸载
            uninstall_plugins+=("$plugin")
        else
            # 未安装的插件，需要安装
            install_plugins+=("$plugin")
        fi
    done
    
    # 显示操作预览
    echo -e "${WHITE}操作预览:${NC}"
    echo ""
    
    if [ ${#uninstall_plugins[@]} -gt 0 ]; then
        echo -e "${RED}将要卸载的插件:${NC}"
        for plugin in "${uninstall_plugins[@]}"; do
            echo "  ❌ $plugin"
        done
        echo ""
    fi
    
    if [ ${#install_plugins[@]} -gt 0 ]; then
        echo -e "${GREEN}将要安装的插件:${NC}"
        for plugin in "${install_plugins[@]}"; do
            echo "  ✅ $plugin"
        done
        echo ""
    fi
    
    # 确认操作
    echo -e "${YELLOW}确认执行以上操作？(y/N):${NC}"
    read -r confirm_operation
    
    if [[ ! "$confirm_operation" =~ ^[Yy]$ ]]; then
        print_info "插件管理操作已取消"
        return
    fi
    
    # 执行卸载操作
    if [ ${#uninstall_plugins[@]} -gt 0 ]; then
        echo ""
        print_info "开始卸载插件..."
        
        for plugin in "${uninstall_plugins[@]}"; do
            echo -e "${BLUE}卸载插件:${NC} $plugin"
            
            # 执行卸载命令
            if docker-compose -f docker/docker-compose.yml --env-file server-app/.env exec -T server-app swoole-cli bin/hyperf.php mine-extension:uninstall "$plugin" -y 2>/dev/null; then
                print_success "插件卸载成功: $plugin"
            else
                print_error "插件卸载失败: $plugin"
            fi
        done
        echo ""
    fi
    
    # 执行安装操作
    if [ ${#install_plugins[@]} -gt 0 ]; then
        echo ""
        print_info "开始安装插件..."
        
        for plugin in "${install_plugins[@]}"; do
            echo -e "${BLUE}安装插件:${NC} $plugin"
            
            # 执行安装命令
            if docker-compose -f docker/docker-compose.yml --env-file server-app/.env exec -T server-app swoole-cli bin/hyperf.php mine-extension:install "$plugin" -y 2>/dev/null; then
                print_success "插件安装成功: $plugin"
            else
                print_error "插件安装失败: $plugin"
            fi
        done
        echo ""
    fi
    
    print_success "插件管理操作完成！"
    echo ""
    
    # 询问是否刷新插件状态
    echo -e "${CYAN}是否刷新插件状态？(y/N):${NC}"
    read -r refresh_status
    
    if [[ "$refresh_status" =~ ^[Yy]$ ]]; then
        echo ""
        show_installed_plugins
    fi
}

# 从官方仓库初始化项目
init_mineadmin_project() {
    echo -e "${WHITE}🚀 MineAdmin 项目初始化${NC}"
    echo ""
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        return 1
    fi
    
    # 第一步：检查Git是否安装
    echo -e "${BLUE}[1/5] 正在检测本机环境...${NC}"
    if ! command -v git &> /dev/null; then
        print_error "Git未安装，请先安装Git"
        echo -e "${YELLOW}安装命令:${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install git"
        elif [[ -f /etc/debian_version ]]; then
            echo "  sudo apt-get update && sudo apt-get install -y git"
        elif [[ -f /etc/redhat-release ]]; then
            echo "  sudo yum install -y git"
        else
            echo "  请根据您的系统手动安装Git"
        fi
        return 1
    fi
    
    local git_version=$(git --version 2>/dev/null | cut -d' ' -f3)
    print_success "Git已安装，版本: $git_version"
    
    # 第二步：检查网络连接
    echo -e "${BLUE}[2/5] 正在尝试访问GitHub...${NC}"
    local github_url="https://github.com"
    local gitee_url="https://gitee.com"
    local use_github=true
    
    if curl -s --connect-timeout 5 "$github_url" &> /dev/null; then
        print_success "GitHub访问正常，使用GitHub仓库"
        use_github=true
    else
        print_warning "GitHub访问失败，尝试使用Gitee仓库"
        if curl -s --connect-timeout 5 "$gitee_url" &> /dev/null; then
            print_success "Gitee访问正常，使用Gitee仓库"
            use_github=false
        else
            print_error "GitHub和Gitee都无法访问，请检查网络连接"
            return 1
        fi
    fi
    
    # 设置仓库地址
    local repo_url=""
    local repo_name=""
    if [ "$use_github" = true ]; then
        repo_url="https://github.com/mineadmin/MineAdmin.git"
        repo_name="MineAdmin-GitHub"
    else
        repo_url="https://gitee.com/mineadmin/mineadmin.git"
        repo_name="MineAdmin-Gitee"
    fi
    
    # 第三步：检查当前目录状态
    echo -e "${BLUE}[3/5] 检查当前目录状态...${NC}"
    local current_dir=$(pwd)
    local parent_dir=$(dirname "$current_dir")
    
    # 检查是否在正确的目录结构中
    if [[ "$current_dir" == */docker ]]; then
        print_info "当前在docker目录，切换到上级目录"
        cd "$parent_dir"
    fi
    
    # 检查是否已存在server-app或web目录
    if [ -d "server-app" ] || [ -d "web" ]; then
        print_warning "检测到已存在的server-app或web目录"
        echo -e "${YELLOW}是否继续？这将覆盖现有文件 (y/N):${NC}"
        read -r confirm_overwrite
        if [[ ! "$confirm_overwrite" =~ ^[Yy]$ ]]; then
            print_info "初始化已取消"
            return 0
        fi
        
        # 备份现有目录
        if [ -d "server-app" ]; then
            print_info "备份现有server-app目录..."
            mv server-app server-app-backup-$(date +%Y%m%d_%H%M%S)
        fi
        if [ -d "web" ]; then
            print_info "备份现有web目录..."
            mv web web-backup-$(date +%Y%m%d_%H%M%S)
        fi
    fi
    
    # 第四步：拉取最新源码
    echo -e "${BLUE}[4/5] 正在拉取最新源码...${NC}"
    print_info "从 $repo_url 拉取代码..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d 2>/dev/null) || temp_dir="/tmp/mineadmin_init_$$"
    
    if git clone "$repo_url" "$temp_dir/$repo_name" 2>/dev/null; then
        print_success "代码拉取成功"
    else
        print_error "代码拉取失败"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 第五步：初始化项目结构
    echo -e "${BLUE}[5/5] 正在初始化项目结构...${NC}"
    
    local cloned_dir="$temp_dir/$repo_name"
    
    # 检查克隆的目录结构
    if [ ! -d "$cloned_dir" ]; then
        print_error "克隆的目录不存在"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 重命名根目录为server-app
    print_info "重命名根目录为server-app..."
    mv "$cloned_dir" "server-app"
    
    # 检查web目录是否存在
    if [ ! -d "server-app/web" ]; then
        print_error "server-app/web目录不存在，请检查仓库结构"
        rm -rf "server-app"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 移动web目录到外层
    print_info "移动web目录到外层..."
    mv "server-app/web" "web"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    # 验证最终结构
    if [ -d "server-app" ] && [ -d "web" ] && [ -d "docker" ]; then
        print_success "项目结构初始化完成！"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}📁 项目结构:${NC}"
        echo "  ✅ server-app/ - 后端应用"
        echo "  ✅ web/        - 前端应用"
        echo "  ✅ docker/     - Docker配置"
        echo ""
        echo -e "${WHITE}🎯 下一步操作:${NC}"
        echo "  1. 运行 'hook check' 检查系统兼容性"
        echo "  2. 运行 'hook install' 安装部署"
        echo "  3. 运行 'hook build' 构建前端"
        echo "  4. 运行 'hook start' 启动服务"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # 显示仓库信息
        if [ -d "server-app/.git" ]; then
            echo ""
            echo -e "${WHITE}📋 仓库信息:${NC}"
            cd server-app
            echo "  远程仓库: $(git remote get-url origin 2>/dev/null || echo '未知')"
            echo "  当前分支: $(git branch --show-current 2>/dev/null || echo '未知')"
            echo "  最新提交: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo '未知')"
            cd ..
        fi
    else
        print_error "项目结构初始化失败"
        return 1
    fi
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
    dialog --title "选择要导出的容器" \
           --backtitle "MineAdmin 管理工具" \
           --checklist "请选择要导出的容器（空格选择，回车确认）：" 20 80 15 \
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

# =============================================================================
# K8s 集群管理功能
# =============================================================================

# K8s 管理菜单
show_k8s_menu() {
    # 检查Dialog是否可用
    if ! command -v dialog &> /dev/null; then
        print_warning "Dialog不可用，使用命令行模式"
        show_k8s_menu_cli
        return
    fi
    
    # 创建临时文件存储选择
    local tempfile=$(mktemp 2>/dev/null) || tempfile=/tmp/mineadmin_k8s_menu$$
    
    # 显示K8s管理菜单
    dialog --title "☸️  K8s 集群管理" \
           --backtitle "MineAdmin 管理工具" \
           --menu "请选择要执行的K8s操作：" 0 0 0 \
           1 "部署K8s集群" \
           2 "查看集群状态" \
           3 "查看组件日志" \
           4 "生成配置文件" \
           5 "添加工作节点" \
           6 "删除工作节点" \
           7 "升级集群版本" \
           8 "备份集群配置" \
           9 "恢复集群配置" \
           10 "卸载K8s集群" \
           0 "返回主菜单" 2> "$tempfile"
    
    # 读取选择结果
    local choice=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    # 处理选择
    case $choice in
        1)
            deploy_k8s_cluster
            ;;
        2)
            show_k8s_status
            ;;
        3)
            show_k8s_logs
            ;;
        4)
            generate_k8s_config
            ;;
        5)
            add_worker_node
            ;;
        6)
            remove_worker_node
            ;;
        7)
            upgrade_k8s_cluster
            ;;
        8)
            backup_k8s_config
            ;;
        9)
            restore_k8s_config
            ;;
        10)
            uninstall_k8s_cluster
            ;;
        0)
            print_info "返回主菜单"
            ;;
        *)
            print_info "取消操作"
            ;;
    esac
}

# K8s 命令行菜单
show_k8s_menu_cli() {
    clear
    print_title
    echo ""
    echo -e "${WHITE}☸️  K8s 集群管理菜单${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${MAGENTA}🚀 集群部署:${NC}"
    echo "  1. 部署K8s集群"
    echo "  2. 添加工作节点"
    echo "  3. 删除工作节点"
    echo ""
    echo -e "${MAGENTA}📊 集群监控:${NC}"
    echo "  4. 查看集群状态"
    echo "  5. 查看组件日志"
    echo "  6. 生成配置文件"
    echo ""
    echo -e "${MAGENTA}🔧 集群维护:${NC}"
    echo "  7. 升级集群版本"
    echo "  8. 备份集群配置"
    echo "  9. 恢复集群配置"
    echo "  10. 卸载K8s集群"
    echo ""
    echo -e "${MAGENTA}🔍 故障诊断:${NC}"
    echo "  11. 诊断初始化问题"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}请选择操作 (1-11):${NC}"
    read -r choice
    
    case $choice in
        1)
            deploy_k8s_cluster
            ;;
        2)
            add_worker_node
            ;;
        3)
            remove_worker_node
            ;;
        4)
            show_k8s_status
            ;;
        5)
            show_k8s_logs
            ;;
        6)
            generate_k8s_config
            ;;
        7)
            upgrade_k8s_cluster
            ;;
        8)
            backup_k8s_config
            ;;
        9)
            restore_k8s_config
            ;;
        10)
            uninstall_k8s_cluster
            ;;
        11)
            diagnose_k8s_init
            ;;
        *)
            print_info "取消操作"
            ;;
    esac
}

# 检查K8s系统兼容性
check_k8s_compatibility() {
    echo -e "${BLUE}[1/7] 检测操作系统...${NC}"
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo -e "${WHITE}操作系统:${NC} $PRETTY_NAME"
        echo -e "${WHITE}版本:${NC} $VERSION_ID"
        
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "24.04" ]] || [[ "$VERSION_ID" == "22.04" ]]; then
                print_success "Ubuntu $VERSION_ID - 兼容K8s"
            else
                print_warning "Ubuntu $VERSION_ID - 可能兼容，建议使用24.04或22.04"
            fi
        else
            print_warning "非Ubuntu系统，可能不兼容"
        fi
    else
        print_warning "无法检测操作系统信息"
    fi
    
    echo -e "${BLUE}[2/7] 检测系统架构...${NC}"
    echo -e "${WHITE}架构:${NC} $ARCH"
    
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        print_success "$ARCH 架构 - 兼容K8s"
    else
        print_error "未知架构 $ARCH - 不兼容K8s"
        return 1
    fi
    
    echo -e "${BLUE}[3/7] 检测内存...${NC}"
    local mem_total=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mem_total=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
    else
        mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    fi
    echo -e "${WHITE}总内存:${NC} ${mem_total}GB"
    
    if [[ $mem_total -ge 4 ]]; then
        print_success "内存充足 (≥4GB)"
    elif [[ $mem_total -ge 2 ]]; then
        print_warning "内存基本满足 (≥2GB)，建议4GB以上"
    else
        print_error "内存不足 (<2GB)，无法运行K8s"
        return 1
    fi
    
    echo -e "${BLUE}[4/7] 检测磁盘空间...${NC}"
    local disk_free=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        disk_free=$(df -g / | awk 'NR==2{print $4}')
    else
        disk_free=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    fi
    echo -e "${WHITE}可用空间:${NC} ${disk_free}GB"
    
    if [[ $disk_free -ge 20 ]]; then
        print_success "磁盘空间充足 (≥20GB可用)"
    elif [[ $disk_free -ge 10 ]]; then
        print_warning "磁盘空间基本满足 (≥10GB可用)，建议20GB以上"
    else
        print_error "磁盘空间不足 (<10GB可用)，无法运行K8s"
        return 1
    fi
    
    echo -e "${BLUE}[5/7] 检测网络连接...${NC}"
    if curl -s --connect-timeout 5 https://www.google.com &> /dev/null; then
        print_success "外网连接正常"
    else
        print_warning "外网连接可能有问题"
    fi
    
    if curl -s --connect-timeout 5 https://packages.cloud.google.com &> /dev/null; then
        print_success "Google Cloud连接正常"
    else
        print_warning "Google Cloud连接可能有问题"
    fi
    
    echo -e "${BLUE}[6/7] 检测必要工具...${NC}"
    local tools=("curl" "wget" "grep" "sed" "awk" "systemctl")
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
    
    echo -e "${BLUE}[7/7] 检测系统配置...${NC}"
    
    # 检查swap状态
    if swapon --show | grep -q "/"; then
        print_warning "检测到swap已启用，K8s建议禁用swap"
        echo "建议运行: sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
    else
        print_success "swap已禁用"
    fi
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "Status: active"; then
            print_warning "UFW防火墙已启用，可能需要配置K8s端口"
        else
            print_success "UFW防火墙未启用"
        fi
    fi
    
    # 检查SELinux状态（如果存在）
    if command -v sestatus &> /dev/null; then
        if sestatus | grep -q "SELinux status: enabled"; then
            print_warning "SELinux已启用，可能需要配置"
        else
            print_success "SELinux未启用"
        fi
    fi
    
    # 检查cgroup版本
    if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
        print_success "cgroup v2已启用"
    else
        print_warning "cgroup v1检测到，建议升级到v2"
    fi
    
    # 检查现有K8s安装
    if command -v kubeadm &> /dev/null || command -v kubectl &> /dev/null || command -v kubelet &> /dev/null; then
        print_warning "检测到现有K8s组件，安装过程中将自动清理"
    fi
    
    if [[ -d /etc/kubernetes ]] || [[ -d /var/lib/kubelet ]]; then
        print_warning "检测到现有K8s配置，安装过程中将自动清理"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 K8s兼容性检测结果:${NC}"
    echo "✅ 系统兼容K8s部署"
    echo "📋 建议配置: 4GB+ 内存, 20GB+ 磁盘空间"
    echo "🌐 需要稳定的网络连接"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 部署K8s集群
deploy_k8s_cluster() {
    print_info "开始部署K8s集群..."
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        return 1
    fi
    
    # 检查系统兼容性
    echo -e "${BLUE}[1/8] 检查系统兼容性...${NC}"
    if ! check_k8s_compatibility; then
        print_error "系统不兼容K8s，部署终止"
        return 1
    fi
    
    # 选择部署模式
    echo -e "${BLUE}[2/8] 选择部署模式...${NC}"
    echo ""
    echo -e "${WHITE}请选择部署模式:${NC}"
    echo "1. 单机模式 - 主控和节点都在一台服务器"
    echo "2. 集群模式 - 主控和节点分布在不同服务器"
    echo ""
    echo -e "${CYAN}请输入选择 (1-2):${NC}"
    read -r deploy_mode
    
    case $deploy_mode in
        1)
            deploy_single_node_k8s
            ;;
        2)
            deploy_multi_node_k8s
            ;;
        *)
            print_info "取消部署"
            return
            ;;
    esac
}

# 部署单节点K8s
deploy_single_node_k8s() {
    print_info "开始部署单节点K8s集群..."
    
    # 安装Docker和containerd
    echo -e "${BLUE}[3/9] 安装Docker和containerd...${NC}"
    install_docker_containerd
    
    # 安装K8s组件
    echo -e "${BLUE}[4/9] 安装K8s组件...${NC}"
    install_k8s_components
    
    # 初始化集群
    echo -e "${BLUE}[5/9] 初始化K8s集群...${NC}"
    init_k8s_cluster
    
    # 配置网络插件
    echo -e "${BLUE}[6/9] 配置网络插件...${NC}"
    install_network_plugin
    
    # 部署MineAdmin到K8s
    echo -e "${BLUE}[7/9] 部署MineAdmin到K8s...${NC}"
    deploy_mineadmin_to_k8s
    
    # 验证部署
    echo -e "${BLUE}[8/9] 验证部署结果...${NC}"
    verify_k8s_deployment
    
    # 显示访问信息
    echo -e "${BLUE}[9/9] 显示访问信息...${NC}"
    show_k8s_access_info
    
    print_success "单节点K8s集群部署完成！"
    show_k8s_access_info
}

# 部署多节点K8s
deploy_multi_node_k8s() {
    print_info "开始部署多节点K8s集群..."
    
    # 选择角色
    echo ""
    echo -e "${WHITE}请选择当前服务器的角色:${NC}"
    echo "1. 主控节点 (Master Node)"
    echo "2. 工作节点 (Worker Node)"
    echo ""
    echo -e "${CYAN}请输入选择 (1-2):${NC}"
    read -r node_role
    
    case $node_role in
        1)
            deploy_master_node
            ;;
        2)
            deploy_worker_node
            ;;
        *)
            print_info "取消部署"
            return
            ;;
    esac
}

# 部署主控节点
deploy_master_node() {
    print_info "开始部署主控节点..."
    
    # 安装Docker和containerd
    echo -e "${BLUE}[1/7] 安装Docker和containerd...${NC}"
    install_docker_containerd
    
    # 安装K8s组件
    echo -e "${BLUE}[2/7] 安装K8s组件...${NC}"
    install_k8s_components
    
    # 初始化主控节点
    echo -e "${BLUE}[3/7] 初始化主控节点...${NC}"
    init_master_node
    
    # 配置网络插件
    echo -e "${BLUE}[4/7] 配置网络插件...${NC}"
    install_network_plugin
    
    # 部署MineAdmin到K8s
    echo -e "${BLUE}[5/7] 部署MineAdmin到K8s...${NC}"
    deploy_mineadmin_to_k8s
    
    # 生成节点加入信息
    echo -e "${BLUE}[6/7] 生成节点加入信息...${NC}"
    generate_join_info
    
    # 显示主控节点信息
    echo -e "${BLUE}[7/7] 显示主控节点信息...${NC}"
    show_master_node_info
    
    print_success "主控节点部署完成！"
    show_master_node_info
}

# 部署工作节点
deploy_worker_node() {
    print_info "开始部署工作节点..."
    
    # 获取主控节点信息
    echo -e "${BLUE}[1/6] 获取主控节点信息...${NC}"
    get_master_node_info
    
    # 安装Docker和containerd
    echo -e "${BLUE}[2/6] 安装Docker和containerd...${NC}"
    install_docker_containerd
    
    # 安装K8s组件
    echo -e "${BLUE}[3/6] 安装K8s组件...${NC}"
    install_k8s_components
    
    # 加入集群
    echo -e "${BLUE}[4/6] 加入K8s集群...${NC}"
    join_cluster
    
    # 验证节点状态
    echo -e "${BLUE}[5/6] 验证节点状态...${NC}"
    verify_worker_node
    
    # 显示工作节点信息
    echo -e "${BLUE}[6/6] 显示工作节点信息...${NC}"
    show_worker_node_info
    
    print_success "工作节点部署完成！"
    show_worker_node_info
}

# 安装Docker和containerd
install_docker_containerd() {
    print_info "安装Docker和containerd..."
    
    # 环境清理
    print_info "清理旧的Docker和containerd配置..."
    
    # 停止现有服务
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl stop containerd 2>/dev/null || true
    
    # 清理旧的Docker数据（可选，保留镜像）
    # sudo rm -rf /var/lib/docker/ 2>/dev/null || true
    
    # 检查Docker是否已安装
    if command -v docker &> /dev/null; then
        print_success "Docker已安装"
    else
        print_info "安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_success "Docker安装完成"
    fi
    
    # 检查containerd是否已安装
    if command -v containerd &> /dev/null; then
        print_success "containerd已安装"
    else
        print_info "安装containerd..."
        sudo apt-get update
        sudo apt-get install -y containerd
        print_success "containerd安装完成"
    fi
    
    # 配置containerd
    print_info "配置containerd..."
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
    print_success "containerd配置完成"
}

# 安装K8s组件
install_k8s_components() {
    print_info "安装K8s组件..."
    
    # 环境检查和清理
    print_info "执行环境检查和清理..."
    
    # 1. 停止并清理现有的K8s服务
    print_info "停止现有K8s服务..."
    sudo systemctl stop kubelet 2>/dev/null || true
    sudo systemctl stop containerd 2>/dev/null || true
    
    # 2. 重置kubeadm（如果存在）
    if command -v kubeadm &> /dev/null; then
        print_info "重置现有kubeadm配置..."
        sudo kubeadm reset -f 2>/dev/null || true
    fi
    
    # 3. 清理旧的K8s文件和配置
    print_info "清理旧的K8s文件和配置..."
    sudo rm -rf /etc/kubernetes/ 2>/dev/null || true
    sudo rm -rf /var/lib/kubelet/ 2>/dev/null || true
    sudo rm -rf /var/lib/etcd/ 2>/dev/null || true
    sudo rm -rf $HOME/.kube/ 2>/dev/null || true
    sudo rm -rf /etc/cni/ 2>/dev/null || true
    sudo rm -rf /opt/cni/ 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/kubernetes.list 2>/dev/null || true
    sudo rm -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg 2>/dev/null || true
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || true
    
    # 4. 检查并释放被占用的端口
    print_info "检查并释放被占用的端口..."
    local ports=(6443 10250 10251 10252 10255 10257 10259 2379 2380 179 4789 5473)
    for port in "${ports[@]}"; do
        local pid=$(sudo lsof -ti:$port 2>/dev/null)
        if [[ -n "$pid" ]]; then
            print_warning "端口 $port 被进程 $pid 占用，正在终止..."
            sudo kill -9 "$pid" 2>/dev/null || true
        fi
    done
    
    # 额外清理：终止所有kubelet相关进程
    print_info "清理kubelet相关进程..."
    sudo pkill -f kubelet 2>/dev/null || true
    sudo pkill -f kube-apiserver 2>/dev/null || true
    sudo pkill -f kube-controller-manager 2>/dev/null || true
    sudo pkill -f kube-scheduler 2>/dev/null || true
    sudo pkill -f etcd 2>/dev/null || true
    
    # 5. 清理网络配置
    print_info "清理网络配置..."
    sudo ip link delete cni0 2>/dev/null || true
    sudo ip link delete flannel.1 2>/dev/null || true
    sudo ip link delete calico-* 2>/dev/null || true
    sudo iptables -F 2>/dev/null || true
    sudo iptables -t nat -F 2>/dev/null || true
    sudo iptables -t mangle -F 2>/dev/null || true
    sudo iptables -X 2>/dev/null || true
    
    # 6. 配置防火墙（允许K8s端口）
    print_info "配置防火墙..."
    # 禁用UFW（如果启用）
    if sudo ufw status | grep -q "Status: active"; then
        print_warning "UFW防火墙已启用，正在禁用..."
        sudo ufw disable
    fi
    
    # 配置iptables规则
    sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 10250 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 10251 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 10252 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 10255 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 2379 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 2380 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 179 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 4789 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p udp --dport 4789 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 5473 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p udp --dport 5473 -j ACCEPT 2>/dev/null || true
    
    # 7. 清理旧的systemd服务文件
    print_info "清理旧的systemd服务文件..."
    sudo rm -f /etc/systemd/system/kubelet.service 2>/dev/null || true
    sudo rm -rf /etc/systemd/system/kubelet.service.d/ 2>/dev/null || true
    
    # 7. 禁用swap（K8s要求）
    print_info "检查并禁用swap..."
    if swapon --show | grep -q "/"; then
        print_warning "检测到swap已启用，正在禁用..."
        sudo swapoff -a
        sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
        print_success "swap已禁用"
    else
        print_success "swap未启用"
    fi
    
    # 8. 确保containerd配置正确
    print_info "配置containerd..."
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
    
    # 9. 更新包列表
    sudo apt-get update
    
    # 10. 安装必要的工具
    sudo apt-get install -y apt-transport-https ca-certificates curl
    
    # 11. 检测架构
    local arch=""
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
        arch="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        arch="arm64"
    else
        print_error "不支持的架构: $ARCH"
        return 1
    fi
    
    print_info "检测到架构: $arch"
    
    # 12. 下载K8s组件
    print_info "下载K8s组件..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$arch/kubeadm"
    sudo install -o root -g root -m 0755 kubeadm /usr/local/bin/kubeadm
    
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$arch/kubelet"
    sudo install -o root -g root -m 0755 kubelet /usr/local/bin/kubelet
    
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$arch/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # 清理下载文件
    rm -f kubeadm kubelet kubectl
    
    # 13. 创建kubelet服务文件
    print_info "创建kubelet服务文件..."
    sudo tee /etc/systemd/system/kubelet.service << EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"

[Install]
WantedBy=multi-user.target
EOF
    
    # 14. 创建kubelet服务配置目录
    sudo mkdir -p /etc/systemd/system/kubelet.service.d
    sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf << EOF
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"
ExecStart=
ExecStart=/usr/local/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
EOF
    
    # 15. 重新加载systemd配置
    sudo systemctl daemon-reload
    
    # 16. 启用kubelet服务
    sudo systemctl enable kubelet
    
    print_success "K8s组件安装完成"
}

# 初始化K8s集群
init_k8s_cluster() {
    print_info "初始化K8s集群..."
    
    # 获取本机IP（单机模式使用内网IP，排除Docker容器IP）
    local node_ip=""
    
    # 方法1: 获取真正的宿主机IP（排除所有Docker网络）
    node_ip=""
    
    # 尝试获取默认路由的出接口IP
    local default_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$default_interface" ]]; then
        node_ip=$(ip addr show "$default_interface" | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | head -1)
    fi
    
    # 如果还是Docker IP，尝试其他方法
    if [[ -z "$node_ip" || "$node_ip" == "172."* ]]; then
        # 获取所有非Docker的IP
        node_ip=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | grep -v "172.1[6-9]." | grep -v "172.2[0-9]." | grep -v "172.3[01]." | awk '{print $2}' | cut -d'/' -f1 | head -1)
    fi
    
    # 如果还是没找到，尝试hostname -I
    if [[ -z "$node_ip" || "$node_ip" == "172."* ]]; then
        node_ip=$(hostname -I | tr ' ' '\n' | grep -v "127.0.0.1" | grep -v "172.1[6-9]." | grep -v "172.2[0-9]." | grep -v "172.3[01]." | head -1)
    fi
    
    # 尝试获取外部IP（通过公网服务）
    if [[ -z "$node_ip" || "$node_ip" == "172."* ]]; then
        print_info "尝试获取外部IP地址..."
        local external_ip=$(curl -s --connect-timeout 5 https://ipinfo.io/ip 2>/dev/null || curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 https://icanhazip.com 2>/dev/null)
        if [[ -n "$external_ip" && "$external_ip" != "127.0.0.1" ]]; then
            node_ip="$external_ip"
            print_info "使用外部IP: $node_ip"
        fi
    fi
    
    # 如果还是没找到有效IP，尝试手动配置
    if [[ -z "$node_ip" || "$node_ip" == "127.0.0.1" || "$node_ip" == "172."* ]]; then
        print_warning "无法自动获取有效IP地址，需要手动配置"
        echo ""
        echo -e "${YELLOW}请手动输入服务器的IP地址:${NC}"
        echo "1. 如果是单机部署，请输入服务器的内网IP地址"
        echo "2. 如果是云服务器，请输入公网IP地址"
        echo "3. 如果是本地开发，请输入 0.0.0.0"
        echo ""
        echo -e "${CYAN}请输入IP地址:${NC}"
        read -r node_ip
        
        if [[ -z "$node_ip" ]]; then
            print_error "未输入IP地址，使用默认配置"
            node_ip="0.0.0.0"
        fi
    else
        print_info "使用检测到的IP: $node_ip"
    fi
    
    # 验证IP地址格式
    if [[ ! "$node_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "无效的IP地址格式: $node_ip"
        return 1
    fi
    
    # 初始化集群（添加必要的参数）
    print_info "使用IP: $node_ip 初始化集群..."
    
    # 强制重置kubeadm（确保完全清理）
    print_info "强制重置kubeadm..."
    sudo kubeadm reset -f 2>/dev/null || true
    
    # 等待进程完全清理
    sleep 5
    
    # 尝试初始化集群
    print_info "开始初始化K8s集群..."
    
    # 检查防火墙状态
    print_info "检查防火墙状态..."
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "Status: active"; then
            print_warning "UFW防火墙已启用，正在配置K8s端口..."
            sudo ufw allow 6443/tcp
            sudo ufw allow 10250/tcp
            sudo ufw allow 10251/tcp
            sudo ufw allow 10252/tcp
            sudo ufw allow 2379/tcp
            sudo ufw allow 2380/tcp
            print_success "防火墙端口已开放"
        fi
    fi
    
    # 尝试使用0.0.0.0绑定所有接口
    print_info "尝试使用0.0.0.0绑定所有接口..."
    if sudo kubeadm init \
        --pod-network-cidr=10.244.0.0/16 \
        --apiserver-advertise-address="0.0.0.0" \
        --cri-socket=unix:///var/run/containerd/containerd.sock \
        --upload-certs \
        --control-plane-endpoint="$node_ip" \
        --ignore-preflight-errors=all; then
        
        print_success "K8s集群初始化成功"
        
        # 配置kubectl
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        
        print_success "kubectl配置完成"
    else
        print_error "K8s集群初始化失败"
        echo ""
        echo -e "${YELLOW}可能的解决方案:${NC}"
        echo "1. 检查网络配置和防火墙设置"
        echo "2. 确保端口 6443, 10250, 10251, 10252 未被占用"
        echo "3. 检查系统资源是否充足"
        echo "4. 运行诊断命令: ./docker/mineadmin.sh k8s-diagnose"
        echo ""
        
        # 自动运行诊断
        print_info "自动运行诊断..."
        diagnose_k8s_init
        return 1
    fi
}

# 诊断K8s初始化问题
diagnose_k8s_init() {
    print_info "诊断K8s初始化问题..."
    
    echo -e "${YELLOW}📊 系统信息:${NC}"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    
    echo -e "${YELLOW}🌐 网络信息:${NC}"
    echo "所有IP地址:"
    hostname -I
    echo ""
    echo "网络接口:"
    ip addr show | grep -E "inet.*scope global" | awk '{print $2, $7}'
    
    echo -e "${YELLOW}🔧 服务状态:${NC}"
    echo "containerd状态:"
    sudo systemctl status containerd --no-pager | head -10
    echo ""
    echo "kubelet状态:"
    sudo systemctl status kubelet --no-pager | head -10
    
    echo -e "${YELLOW}📋 kubelet日志:${NC}"
    sudo journalctl -u kubelet --no-pager | tail -20
    
    echo -e "${YELLOW}💾 磁盘空间:${NC}"
    df -h /
    
    echo -e "${YELLOW}🧠 内存使用:${NC}"
    free -h
    
    echo -e "${YELLOW}🌡️  CPU使用:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
}

# 初始化主控节点
init_master_node() {
    print_info "初始化主控节点..."
    
    # 获取本机IP（集群模式优先使用公网IP，排除Docker容器IP）
    local node_ip=""
    
    # 方法1: 尝试获取公网IP（集群模式需要）
    if command -v curl &> /dev/null; then
        node_ip=$(curl -s --connect-timeout 5 https://ipinfo.io/ip 2>/dev/null)
        if [[ -n "$node_ip" && "$node_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_info "检测到公网IP: $node_ip"
        else
            node_ip=""
        fi
    fi
    
    # 方法2: 如果没有公网IP，获取内网IP（排除Docker容器IP）
    if [[ -z "$node_ip" ]]; then
        node_ip=$(ip route get 8.8.8.8 | awk '{print $7}' | head -1)
        if [[ -z "$node_ip" || "$node_ip" == "172."* ]]; then
            # 如果还是Docker IP，尝试其他方法
            node_ip=$(ip addr show | grep -E "inet.*scope global" | grep -v "172.1[7-9]." | grep -v "172.2[0-9]." | grep -v "172.3[01]." | awk '{print $2}' | cut -d'/' -f1 | head -1)
        fi
        if [[ -z "$node_ip" ]]; then
            # 最后尝试：使用默认网关的接口IP
            node_ip=$(ip route | grep default | awk '{print $3}' | head -1)
        fi
        if [[ -z "$node_ip" ]]; then
            # 如果还是没找到，使用第一个非Docker的IP
            node_ip=$(hostname -I | tr ' ' '\n' | grep -v '^172\.1[7-9]\.' | grep -v '^172\.2[0-9]\.' | grep -v '^172\.3[01]\.' | head -1)
        fi
        print_info "使用内网IP: $node_ip"
    fi
    
    # 如果还是没找到，使用默认方法
    if [[ -z "$node_ip" ]]; then
        node_ip=$(hostname -I | awk '{print $1}')
        print_warning "使用默认IP: $node_ip"
    fi
    
    # 验证IP地址格式
    if [[ ! "$node_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "无效的IP地址: $node_ip"
        return 1
    fi
    
    # 完全重置K8s环境
    print_info "完全重置K8s环境..."
    sudo kubeadm reset --force
    sudo rm -rf /etc/kubernetes/
    sudo rm -rf /var/lib/kubelet/
    sudo rm -rf /var/lib/etcd/
    sudo rm -rf ~/.kube/
    
    # 检查端口占用并清理
    print_info "检查并清理端口占用..."
    local ports=(6443 10250 10251 10252 10255 2379 2380)
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            print_warning "端口 $port 被占用，正在释放..."
            sudo fuser -k $port/tcp 2>/dev/null || true
            sleep 2
        fi
    done
    
    # 确保containerd配置正确
    print_info "配置containerd..."
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
    
    # 修改containerd配置，使用正确的pause镜像和更保守的设置
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo sed -i 's/sandbox_image = "registry.k8s.io\/pause:3.8"/sandbox_image = "registry.k8s.io\/pause:3.10"/' /etc/containerd/config.toml
    
    # 添加更保守的资源限制
    sudo sed -i '/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/a\  SystemdCgroup = true' /etc/containerd/config.toml
    
    # 重启containerd
    sudo systemctl restart containerd
    sleep 5
    
    # 确保kubelet配置正确
    print_info "配置kubelet..."
    sudo mkdir -p /var/lib/kubelet
    cat > /tmp/kubelet-config.yaml << EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
failSwapOn: false
maxPods: 110
memorySwap: {}
kubeReserved:
  memory: "256Mi"
  cpu: "100m"
systemReserved:
  memory: "256Mi"
  cpu: "100m"
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
evictionSoft:
  memory.available: "200Mi"
  nodefs.available: "15%"
evictionSoftGracePeriod:
  memory.available: "1m30s"
  nodefs.available: "1m30s"
EOF
    
    sudo cp /tmp/kubelet-config.yaml /var/lib/kubelet/config.yaml
    rm -f /tmp/kubelet-config.yaml
    
    # 重启kubelet
    sudo systemctl restart kubelet
    sleep 5
    
    # 显示配置信息
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📋 K8s初始化配置:${NC}"
    echo -e "${BLUE}节点IP:${NC} $node_ip"
    echo -e "${BLUE}Pod网段:${NC} 10.244.0.0/16"
    echo -e "${BLUE}Service网段:${NC} 10.96.0.0/12"
    echo -e "${BLUE}K8s版本:${NC} v1.33.4"
    echo -e "${BLUE}容器运行时:${NC} containerd"
    echo -e "${BLUE}Pause镜像:${NC} registry.k8s.io/pause:3.10"
    echo -e "${BLUE}最大Pod数:${NC} 110"
    echo -e "${BLUE}内存预留:${NC} 512Mi (kube + system)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 使用更保守的初始化命令
    print_info "使用IP: $node_ip 初始化主控节点..."
    
    # 执行初始化（使用更保守的设置）
    if timeout 900 sudo kubeadm init \
        --pod-network-cidr=10.244.0.0/16 \
        --apiserver-advertise-address=$node_ip \
        --control-plane-endpoint=$node_ip \
        --cri-socket=unix:///var/run/containerd/containerd.sock \
        --upload-certs \
        --ignore-preflight-errors=all \
        --kubernetes-version=v1.33.4; then
        
        print_success "主控节点初始化成功"
        
        # 配置kubectl
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        
        # 验证集群状态
        print_info "验证集群状态..."
        sleep 20
        
        if kubectl get nodes; then
            print_success "集群状态正常"
        else
            print_warning "集群状态检查失败，请手动检查"
        fi
        
    else
        print_error "主控节点初始化失败"
        
        # 诊断信息
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}🔍 诊断信息:${NC}"
        echo ""
        
        # 检查kubelet状态
        echo -e "${BLUE}检查kubelet状态:${NC}"
        sudo systemctl status kubelet --no-pager -l || true
        echo ""
        
        # 检查containerd状态
        echo -e "${BLUE}检查containerd状态:${NC}"
        sudo systemctl status containerd --no-pager -l || true
        echo ""
        
        # 检查容器状态（使用docker命令作为备选）
        echo -e "${BLUE}检查K8s容器状态:${NC}"
        if command -v crictl &> /dev/null; then
            sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube || true
        else
            echo "crictl未安装，尝试使用docker命令..."
            sudo docker ps -a | grep kube || true
        fi
        echo ""
        
        # 检查kube-apiserver日志
        echo -e "${BLUE}检查kube-apiserver日志:${NC}"
        if command -v crictl &> /dev/null; then
            local api_server_id=$(sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube-apiserver | awk '{print $1}' | head -1)
            if [[ -n "$api_server_id" ]]; then
                sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs "$api_server_id" 2>/dev/null | tail -30 || true
            else
                echo "未找到kube-apiserver容器"
            fi
        else
            echo "crictl未安装，无法查看容器日志"
        fi
        echo ""
        
        # 检查kubelet日志
        echo -e "${BLUE}检查kubelet日志:${NC}"
        sudo journalctl -u kubelet --no-pager -l | tail -30 || true
        echo ""
        
        # 检查系统资源
        echo -e "${BLUE}检查系统资源:${NC}"
        echo "内存使用:"
        free -h
        echo ""
        echo "磁盘使用:"
        df -h
        echo ""
        echo "CPU使用:"
        top -bn1 | head -20
        echo ""
        
        # 提供解决建议
        echo -e "${YELLOW}💡 解决建议:${NC}"
        echo "1. 检查系统资源是否充足"
        echo "2. 确保网络连接正常"
        echo "3. 检查防火墙设置"
        echo "4. 尝试使用单节点模式: 选择部署模式时选择1"
        echo "5. 运行诊断命令: hook k8s-diagnose"
        echo ""
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        return 1
    fi
}

# 安装网络插件
install_network_plugin() {
    print_info "安装网络插件 (Flannel)..."
    
    # 安装Flannel网络插件（更稳定，兼容性更好）
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    
    # 等待网络插件就绪
    print_info "等待网络插件就绪..."
    
    # 等待DaemonSet创建完成
    sleep 10
    
    # 检查DaemonSet状态
    print_info "检查Flannel DaemonSet状态..."
    kubectl get daemonset -n kube-flannel
    
    # 等待Pod启动
    print_info "等待Flannel Pod启动..."
    kubectl wait --for=condition=available daemonset/kube-flannel-ds -n kube-flannel --timeout=300s || true
    
    # 检查Pod状态
    print_info "检查Flannel Pod状态..."
    kubectl get pods -n kube-flannel
    
    # 等待所有Pod就绪
    print_info "等待所有Flannel Pod就绪..."
    kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s || \
    kubectl wait --for=condition=ready pod -l k8s-app=flannel -n kube-flannel --timeout=300s || \
    kubectl wait --for=condition=ready pod -l name=flannel -n kube-flannel --timeout=300s || \
    kubectl wait --for=condition=ready pod -l app=flannel -n kube-system --timeout=300s || \
    kubectl wait --for=condition=ready pod -l k8s-app=flannel -n kube-system --timeout=300s || \
    kubectl wait --for=condition=ready pod -l name=flannel -n kube-system --timeout=300s
    
    # 检查网络插件状态
    print_info "检查网络插件状态..."
    kubectl get pods -A | grep flannel || true
    
    # 验证网络连通性
    print_info "验证网络连通性..."
    if kubectl get nodes | grep -q "Ready"; then
        print_success "Flannel网络插件安装完成"
    else
        print_warning "网络插件可能未完全就绪，但安装已完成"
    fi
}

# 部署MineAdmin到K8s
deploy_mineadmin_to_k8s() {
    print_info "部署MineAdmin到K8s..."
    
    # 创建命名空间
    kubectl create namespace mineadmin --dry-run=client -o yaml | kubectl apply -f -
    
    # 创建配置文件目录
    local k8s_dir="$PROJECT_ROOT/docker/k8s/manifests"
    mkdir -p "$k8s_dir"
    
    # 1. 部署MySQL
    print_info "部署MySQL数据库..."
    cat > "$k8s_dir/mysql.yaml" << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: mineadmin
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: mineadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "root123"
        - name: MYSQL_DATABASE
          value: "mineadmin"
        - name: MYSQL_USER
          value: "mineadmin"
        - name: MYSQL_PASSWORD
          value: "mineadmin123"
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: mineadmin
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
EOF
    
    # 2. 部署Redis
    print_info "部署Redis缓存..."
    cat > "$k8s_dir/redis.yaml" << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: mineadmin
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: mineadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - --requirepass
        - "root123"
        volumeMounts:
        - name: redis-storage
          mountPath: /data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: mineadmin
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF
    
    # 3. 部署MineAdmin后端
    print_info "部署MineAdmin后端服务..."
    cat > "$k8s_dir/server-app.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mineadmin-server
  namespace: mineadmin
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mineadmin-server
  template:
    metadata:
      labels:
        app: mineadmin-server
    spec:
      containers:
      - name: mineadmin-server
        image: mineadmin/server-app:latest
        ports:
        - containerPort: 9501
          name: http
        - containerPort: 9502
          name: websocket
        - containerPort: 9509
          name: grpc
        env:
        - name: APP_NAME
          value: "MineAdmin"
        - name: APP_ENV
          value: "production"
        - name: APP_DEBUG
          value: "false"
        - name: DB_DRIVER
          value: "mysql"
        - name: DB_HOST
          value: "mysql-service"
        - name: DB_PORT
          value: "3306"
        - name: DB_DATABASE
          value: "mineadmin"
        - name: DB_USERNAME
          value: "mineadmin"
        - name: DB_PASSWORD
          value: "mineadmin123"
        - name: REDIS_HOST
          value: "redis-service"
        - name: REDIS_PORT
          value: "6379"
        - name: REDIS_AUTH
          value: "root123"
        - name: REDIS_DB
          value: "3"
        - name: JWT_SECRET
          value: "azOVxsOWt3r0ozZNz8Ss429ht0T8z6OpeIJAIwNp6X0xqrbEY2epfIWyxtC1qSNM8eD6/LQ/SahcQi2ByXa/2A=="
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 9501
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 9501
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: mineadmin-server-service
  namespace: mineadmin
spec:
  selector:
    app: mineadmin-server
  ports:
  - name: http
    port: 80
    targetPort: 9501
  - name: websocket
    port: 9502
    targetPort: 9502
  - name: grpc
    port: 9509
    targetPort: 9509
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mineadmin-ingress
  namespace: mineadmin
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: mineadmin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mineadmin-server-service
            port:
              number: 80
EOF
    
    # 4. 部署MineAdmin前端
    print_info "部署MineAdmin前端服务..."
    cat > "$k8s_dir/web.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mineadmin-web
  namespace: mineadmin
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mineadmin-web
  template:
    metadata:
      labels:
        app: mineadmin-web
    spec:
      containers:
      - name: mineadmin-web
        image: mineadmin/web-prod:latest
        ports:
        - containerPort: 80
        env:
        - name: VITE_API_URL
          value: "http://mineadmin-server-service:80"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: mineadmin-web-service
  namespace: mineadmin
spec:
  selector:
    app: mineadmin-web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mineadmin-web-ingress
  namespace: mineadmin
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: mineadmin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mineadmin-web-service
            port:
              number: 80
EOF
    
    # 按顺序应用配置
    print_info "应用K8s配置..."
    kubectl apply -f "$k8s_dir/mysql.yaml"
    kubectl apply -f "$k8s_dir/redis.yaml"
    kubectl apply -f "$k8s_dir/server-app.yaml"
    kubectl apply -f "$k8s_dir/web.yaml"
    
    print_success "MineAdmin完整栈部署到K8s完成"
}

# 验证K8s部署
verify_k8s_deployment() {
    print_info "验证K8s部署..."
    
    # 等待服务启动
    print_info "等待服务启动..."
    sleep 30
    
    # 检查节点状态
    echo -e "${WHITE}📊 节点状态:${NC}"
    kubectl get nodes -o wide
    
    # 检查命名空间
    echo -e "${WHITE}📁 命名空间:${NC}"
    kubectl get namespaces
    
    # 检查MineAdmin命名空间中的Pod状态
    echo -e "${WHITE}🐳 MineAdmin Pod状态:${NC}"
    kubectl get pods -n mineadmin -o wide
    
    # 检查MineAdmin命名空间中的服务状态
    echo -e "${WHITE}🔗 MineAdmin服务状态:${NC}"
    kubectl get services -n mineadmin
    
    # 检查MineAdmin命名空间中的Ingress状态
    echo -e "${WHITE}🌐 MineAdmin Ingress状态:${NC}"
    kubectl get ingress -n mineadmin
    
    # 检查所有命名空间的Pod状态
    echo -e "${WHITE}🐳 所有Pod状态:${NC}"
    kubectl get pods --all-namespaces -o wide
    
    # 检查存储卷
    echo -e "${WHITE}💾 存储卷状态:${NC}"
    kubectl get pvc -n mineadmin
    
    # 检查事件
    echo -e "${WHITE}📋 最近事件:${NC}"
    kubectl get events -n mineadmin --sort-by='.lastTimestamp' | tail -10
    
    # 检查服务健康状态
    print_info "检查服务健康状态..."
    local mysql_pod=$(kubectl get pods -n mineadmin -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    local redis_pod=$(kubectl get pods -n mineadmin -l app=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    local server_pod=$(kubectl get pods -n mineadmin -l app=mineadmin-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    local web_pod=$(kubectl get pods -n mineadmin -l app=mineadmin-web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$mysql_pod" ]; then
        echo -e "${WHITE}🗄️  MySQL状态:${NC}"
        kubectl describe pod "$mysql_pod" -n mineadmin | grep -E "(Status|Ready|Restart Count)"
    fi
    
    if [ -n "$redis_pod" ]; then
        echo -e "${WHITE}🔴 Redis状态:${NC}"
        kubectl describe pod "$redis_pod" -n mineadmin | grep -E "(Status|Ready|Restart Count)"
    fi
    
    if [ -n "$server_pod" ]; then
        echo -e "${WHITE}⚙️  后端服务状态:${NC}"
        kubectl describe pod "$server_pod" -n mineadmin | grep -E "(Status|Ready|Restart Count)"
    fi
    
    if [ -n "$web_pod" ]; then
        echo -e "${WHITE}🌐 前端服务状态:${NC}"
        kubectl describe pod "$web_pod" -n mineadmin | grep -E "(Status|Ready|Restart Count)"
    fi
    
    print_success "K8s部署验证完成"
}

# 显示K8s访问信息
show_k8s_access_info() {
    local node_ip=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 K8s集群访问信息:${NC}"
    echo ""
    echo -e "${YELLOW}📊 集群状态检查:${NC}"
    echo "  kubectl get nodes"
    echo "  kubectl get pods --all-namespaces"
    echo "  kubectl get services --all-namespaces"
    echo "  kubectl get ingress --all-namespaces"
    echo ""
    echo -e "${YELLOW}🌐 MineAdmin服务访问:${NC}"
    echo "  后端API: kubectl port-forward -n mineadmin svc/mineadmin-server-service 8080:80"
    echo "  前端Web: kubectl port-forward -n mineadmin svc/mineadmin-web-service 8081:80"
    echo "  数据库: kubectl port-forward -n mineadmin svc/mysql-service 3306:3306"
    echo "  Redis: kubectl port-forward -n mineadmin svc/redis-service 6379:6379"
    echo ""
    echo -e "${YELLOW}🔗 本地访问地址:${NC}"
    echo "  后端API: http://localhost:8080"
    echo "  前端Web: http://localhost:8081"
    echo "  数据库: localhost:3306 (用户名: mineadmin, 密码: mineadmin123)"
    echo "  Redis: localhost:6379 (密码: root123)"
    echo ""
    echo -e "${YELLOW}🌍 外部访问配置:${NC}"
    echo "  节点IP: $node_ip"
    echo "  如需外部访问，请配置Ingress或LoadBalancer"
    echo "  或使用: kubectl expose deployment mineadmin-server --type=NodePort --port=80"
    echo ""
    echo -e "${YELLOW}📝 默认登录信息:${NC}"
    echo "  用户名: admin"
    echo "  密码: 123456"
    echo ""
    echo -e "${YELLOW}🔧 常用命令:${NC}"
    echo "  查看Pod日志: kubectl logs -n mineadmin <pod-name>"
    echo "  进入Pod: kubectl exec -it -n mineadmin <pod-name> -- /bin/bash"
    echo "  重启服务: kubectl rollout restart deployment -n mineadmin mineadmin-server"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 生成节点加入信息
generate_join_info() {
    print_info "生成节点加入信息..."
    
    # 生成加入命令
    local join_command=$(kubeadm token create --print-join-command)
    
    # 保存到文件
    local join_file="$PROJECT_ROOT/docker/k8s/join-command.txt"
    echo "$join_command" > "$join_file"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 工作节点加入命令:${NC}"
    echo "$join_command"
    echo ""
    echo -e "${WHITE}📁 命令已保存到:${NC} $join_file"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 显示主控节点信息
show_master_node_info() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 主控节点信息:${NC}"
    echo "节点IP: $(hostname -I | awk '{print $1}')"
    echo "集群状态: kubectl get nodes"
    echo "加入命令已保存到: $PROJECT_ROOT/docker/k8s/join-command.txt"
    echo ""
    echo -e "${YELLOW}下一步:${NC}"
    echo "1. 在其他服务器上运行工作节点部署"
    echo "2. 使用生成的加入命令将工作节点加入集群"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 获取主控节点信息
get_master_node_info() {
    echo -e "${WHITE}请输入主控节点信息:${NC}"
    echo ""
    echo -e "${CYAN}主控节点IP地址:${NC}"
    read -r master_ip
    
    echo -e "${CYAN}加入命令 (从主控节点获取):${NC}"
    read -r join_command
    
    # 保存到临时文件
    local temp_file="$PROJECT_ROOT/docker/k8s/temp-join-command.txt"
    echo "$join_command" > "$temp_file"
    
    print_success "主控节点信息已保存"
}

# 加入集群
join_cluster() {
    print_info "加入K8s集群..."
    
    local temp_file="$PROJECT_ROOT/docker/k8s/temp-join-command.txt"
    if [ -f "$temp_file" ]; then
        local join_command=$(cat "$temp_file")
        sudo $join_command
        rm -f "$temp_file"
        print_success "已加入K8s集群"
    else
        print_error "未找到加入命令"
        return 1
    fi
}

# 验证工作节点
verify_worker_node() {
    print_info "验证工作节点状态..."
    
    # 等待节点就绪
    sleep 10
    
    # 检查节点状态
    echo -e "${WHITE}节点状态:${NC}"
    kubectl get nodes
    
    print_success "工作节点验证完成"
}

# 显示工作节点信息
show_worker_node_info() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 工作节点信息:${NC}"
    echo "节点IP: $(hostname -I | awk '{print $1}')"
    echo "节点状态: kubectl get nodes"
    echo ""
    echo -e "${YELLOW}注意:${NC}"
    echo "工作节点已成功加入集群"
    echo "在主控节点上运行 'kubectl get nodes' 查看所有节点"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 查看K8s集群状态
show_k8s_status() {
    print_info "查看K8s集群状态..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl未安装，请先部署K8s集群"
        return 1
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 K8s集群状态概览${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 集群信息
    echo -e "${YELLOW}📊 集群信息:${NC}"
    kubectl cluster-info 2>/dev/null || echo "集群信息获取失败"
    
    # 节点状态
    echo -e "${YELLOW}🖥️  节点状态:${NC}"
    kubectl get nodes -o wide
    
    # 命名空间
    echo -e "${YELLOW}📁 命名空间:${NC}"
    kubectl get namespaces
    
    # 系统Pod状态
    echo -e "${YELLOW}⚙️  系统Pod状态:${NC}"
    kubectl get pods -n kube-system -o wide
    
    # MineAdmin Pod状态
    echo -e "${YELLOW}🐳 MineAdmin Pod状态:${NC}"
    kubectl get pods -n mineadmin -o wide 2>/dev/null || echo "MineAdmin命名空间不存在"
    
    # 所有Pod状态
    echo -e "${YELLOW}🐳 所有Pod状态:${NC}"
    kubectl get pods --all-namespaces -o wide
    
    # 服务状态
    echo -e "${YELLOW}🔗 服务状态:${NC}"
    kubectl get services --all-namespaces
    
    # Ingress状态
    echo -e "${YELLOW}🌐 Ingress状态:${NC}"
    kubectl get ingress --all-namespaces 2>/dev/null || echo "Ingress控制器未安装"
    
    # 存储卷状态
    echo -e "${YELLOW}💾 存储卷状态:${NC}"
    kubectl get pvc --all-namespaces 2>/dev/null || echo "无存储卷"
    
    # 资源使用情况
    echo -e "${YELLOW}📈 资源使用情况:${NC}"
    kubectl top nodes 2>/dev/null || echo "metrics-server未安装"
    kubectl top pods --all-namespaces 2>/dev/null || echo "metrics-server未安装"
    
    # 最近事件
    echo -e "${YELLOW}📋 最近事件:${NC}"
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 查看K8s组件日志
show_k8s_logs() {
    print_info "查看K8s组件日志..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl未安装，请先部署K8s集群"
        return 1
    fi
    
    echo -e "${WHITE}请选择要查看的组件:${NC}"
    echo "1. kube-apiserver"
    echo "2. kube-controller-manager"
    echo "3. kube-scheduler"
    echo "4. kubelet"
    echo "5. kube-proxy"
    echo "6. flannel"
    echo "7. mineadmin-server"
    echo "8. mineadmin-web"
    echo "9. mysql"
    echo "10. redis"
    echo "11. 所有MineAdmin Pod"
    echo "12. 所有系统Pod"
    echo ""
    echo -e "${CYAN}请输入选择 (1-12):${NC}"
    read -r component_choice
    
    case $component_choice in
        1)
            kubectl logs -n kube-system kube-apiserver-$(hostname) --tail=100
            ;;
        2)
            kubectl logs -n kube-system kube-controller-manager-$(hostname) --tail=100
            ;;
        3)
            kubectl logs -n kube-system kube-scheduler-$(hostname) --tail=100
            ;;
        4)
            sudo journalctl -u kubelet -f --no-pager | tail -100
            ;;
        5)
            kubectl logs -n kube-system kube-proxy-$(hostname) --tail=100
            ;;
        6)
            kubectl logs -n kube-system -l app=flannel --tail=100 2>/dev/null || \
            kubectl logs -n kube-system -l k8s-app=flannel --tail=100 2>/dev/null || \
            kubectl logs -n kube-system -l name=flannel --tail=100 2>/dev/null || \
            echo "未找到Flannel日志，请检查Flannel Pod状态"
            ;;
        7)
            kubectl logs -n mineadmin -l app=mineadmin-server --tail=100
            ;;
        8)
            kubectl logs -n mineadmin -l app=mineadmin-web --tail=100
            ;;
        9)
            kubectl logs -n mineadmin -l app=mysql --tail=100
            ;;
        10)
            kubectl logs -n mineadmin -l app=redis --tail=100
            ;;
        11)
            kubectl logs -n mineadmin --all-containers=true --tail=50
            ;;
        12)
            kubectl logs -n kube-system --all-containers=true --tail=50
            ;;
        *)
            print_info "取消查看日志"
            ;;
    esac
}

# 生成K8s配置文件
generate_k8s_config() {
    print_info "生成K8s配置文件..."
    
    local k8s_dir="$PROJECT_ROOT/docker/k8s"
    mkdir -p "$k8s_dir"
    
    # 生成基础配置文件
    cat > "$k8s_dir/kubeadm-config.yaml" << EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
apiServer:
  extraArgs:
    advertise-address: $(hostname -I | awk '{print $1}')
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
EOF
    
    print_success "K8s配置文件已生成: $k8s_dir/kubeadm-config.yaml"
}

# 添加工作节点
add_worker_node() {
    print_info "添加工作节点功能待实现"
    echo "此功能将在后续版本中实现"
}

# 删除工作节点
remove_worker_node() {
    print_info "删除工作节点功能待实现"
    echo "此功能将在后续版本中实现"
}

# 升级K8s集群
upgrade_k8s_cluster() {
    print_info "升级K8s集群功能待实现"
    echo "此功能将在后续版本中实现"
}

# 备份K8s配置
backup_k8s_config() {
    print_info "备份K8s配置..."
    
    local backup_dir="$PROJECT_ROOT/docker/k8s/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份kubeconfig
    if [ -f "$HOME/.kube/config" ]; then
        cp "$HOME/.kube/config" "$backup_dir/"
    fi
    
    # 备份集群配置
    if command -v kubectl &> /dev/null; then
        kubectl get all --all-namespaces -o yaml > "$backup_dir/cluster-backup.yaml"
    fi
    
    print_success "K8s配置已备份到: $backup_dir"
}

# 恢复K8s配置
restore_k8s_config() {
    print_info "恢复K8s配置功能待实现"
    echo "此功能将在后续版本中实现"
}

# 卸载K8s集群
uninstall_k8s_cluster() {
    print_info "卸载K8s集群..."
    
    echo -e "${RED}⚠️  警告: 此操作将完全删除K8s集群及其所有数据！${NC}"
    echo -e "${YELLOW}包括:${NC}"
    echo "  - 所有Pod、Service、Deployment"
    echo "  - 所有命名空间和数据"
    echo "  - 所有存储卷"
    echo "  - K8s组件和配置"
    echo ""
    read -p "确认要卸载K8s集群吗？(输入 'yes' 确认): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        print_info "开始卸载K8s集群..."
        
        # 1. 停止所有服务
        print_info "停止K8s服务..."
        sudo systemctl stop kubelet 2>/dev/null || true
        sudo systemctl stop containerd 2>/dev/null || true
        
        # 2. 删除所有MineAdmin资源
        if command -v kubectl &> /dev/null; then
            print_info "删除MineAdmin资源..."
            kubectl delete namespace mineadmin --ignore-not-found=true 2>/dev/null || true
            kubectl delete namespace kube-system --ignore-not-found=true 2>/dev/null || true
        fi
        
        # 3. 重置kubeadm
        print_info "重置kubeadm..."
        sudo kubeadm reset -f 2>/dev/null || true
        
        # 4. 删除kubeconfig
        print_info "删除kubeconfig..."
        rm -rf $HOME/.kube 2>/dev/null || true
        
        # 5. 卸载K8s组件
        print_info "卸载K8s组件..."
        sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni kube* 2>/dev/null || true
        sudo apt-get autoremove -y 2>/dev/null || true
        
        # 6. 删除K8s相关文件和目录
        print_info "删除K8s相关文件..."
        sudo rm -rf /etc/kubernetes/ 2>/dev/null || true
        sudo rm -rf ~/.kube/ 2>/dev/null || true
        sudo rm -rf /var/lib/kubelet/ 2>/dev/null || true
        sudo rm -rf /var/lib/etcd/ 2>/dev/null || true
        sudo rm -rf /etc/cni/ 2>/dev/null || true
        sudo rm -rf /opt/cni/ 2>/dev/null || true
        sudo rm -rf /var/lib/cni/ 2>/dev/null || true
        sudo rm -rf /var/run/kubernetes/ 2>/dev/null || true
        
        # 7. 删除systemd服务文件
        print_info "删除systemd服务文件..."
        sudo rm -f /etc/systemd/system/kubelet.service 2>/dev/null || true
        sudo rm -rf /etc/systemd/system/kubelet.service.d/ 2>/dev/null || true
        sudo systemctl daemon-reload 2>/dev/null || true
        
        # 8. 清理网络配置
        print_info "清理网络配置..."
        sudo ip link delete cni0 2>/dev/null || true
        sudo ip link delete flannel.1 2>/dev/null || true
        sudo ip link delete calico-* 2>/dev/null || true
        
        # 9. 清理iptables规则
        print_info "清理iptables规则..."
        sudo iptables -F 2>/dev/null || true
        sudo iptables -t nat -F 2>/dev/null || true
        sudo iptables -t mangle -F 2>/dev/null || true
        sudo iptables -X 2>/dev/null || true
        
        # 10. 清理项目中的K8s文件
        print_info "清理项目K8s文件..."
        rm -rf "$PROJECT_ROOT/docker/k8s" 2>/dev/null || true
        
        print_success "K8s集群已完全卸载"
        echo ""
        echo -e "${YELLOW}💡 提示:${NC}"
        echo "  - 如需重新安装，请运行: bash docker/mineadmin.sh k8s-deploy"
        echo "  - 如需清理Docker镜像，请运行: docker system prune -a"
    else
        print_info "卸载已取消"
    fi
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
    eval dialog --title "选择要清理的镜像" \
         --backtitle "MineAdmin 管理工具" \
         --checklist "请选择要清理的镜像文件（空格选择，回车确认）：" 20 80 15 $menu_options 2> "$tempfile"
    
    # 读取选择结果
    local selected_files=$(cat "$tempfile" 2>/dev/null)
    rm -f "$tempfile"
    
    if [ -z "$selected_files" ]; then
        print_info "取消清理操作"
        return
    fi
    
    # 确认删除
    dialog --title "确认删除" \
           --backtitle "MineAdmin 管理工具" \
           --yesno "您确定要删除选中的镜像文件吗？\n\n此操作无法撤销！" 8 60
    
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
    echo "- 插件管理（扫描/安装/卸载）: hook plugins"
    echo "- 查看网络连接: hook network"
    echo ""
    echo -e "${BLUE}📦 容器管理:${NC}"
    echo "- 容器导出功能: hook export"
    echo "- 容器导入功能: hook import"
    echo "- 查看导入历史: hook import-history"
    echo "- 查看导出镜像: hook list-images"
    echo "- 清理导出镜像: hook clean-images"
    echo ""
    echo -e "${BLUE}☸️  K8s集群管理:${NC}"
    echo "- K8s集群管理菜单: hook k8s"
    echo "- 部署K8s集群: hook k8s-deploy"
    echo "- 查看集群状态: hook k8s-status"
    echo "- 查看组件日志: hook k8s-logs"
    echo "- 生成配置文件: hook k8s-config"
    echo ""
    echo -e "${BLUE}📥 项目初始化:${NC}"
    echo "- 从官方仓库初始化项目: hook init"
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
    echo "- 至少2GB内存 (K8s建议4GB+)"
    echo "- 至少10GB可用磁盘空间 (K8s建议20GB+)"
    echo "- Docker 24.x+"
    echo "- Docker Compose 2.x+"
    echo "- Dialog (可选，用于图形化界面)"
    echo "- Node.js 22.x (前端构建)"
    echo "- pnpm 10.x (前端构建)"
    echo "- Kubernetes 1.28+ (K8s部署)"
    echo "- containerd (K8s容器运行时)"
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
        init)
            init_mineadmin_project
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
        k8s)
            show_k8s_menu
            ;;
        k8s-deploy)
            deploy_k8s_cluster
            ;;
        k8s-status)
            show_k8s_status
            ;;
        k8s-logs)
            show_k8s_logs
            ;;
        k8s-config)
            generate_k8s_config
            ;;
        k8s-diagnose)
            diagnose_k8s_init
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
