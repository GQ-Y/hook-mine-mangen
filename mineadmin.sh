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
NC='\033[0m'

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

# 显示主菜单
show_main_menu() {
    clear
    print_title
    echo ""
    echo -e "${WHITE}请选择操作:${NC}"
    echo ""
    echo -e "${BLUE}🚀 部署管理${NC}"
    echo "  1) 系统兼容性检测"
    echo "  2) 一键安装部署"
    echo "  3) 选择Web模式 (开发/生产)"
    echo ""
    echo -e "${BLUE}⚙️  服务管理${NC}"
    echo "  4) 启动所有服务"
    echo "  5) 停止所有服务"
    echo "  6) 重启所有服务"
    echo "  7) 查看服务状态"
    echo ""
    echo -e "${BLUE}📊 监控管理${NC}"
    echo "  8) 查看容器日志"
    echo "  9) 查看系统资源"
    echo "  10) 查看网络连接"
    echo ""
    echo -e "${BLUE}🔧 配置管理${NC}"
    echo "  11) 重新生成配置"
    echo "  12) 修改密码"
    echo "  13) 查看配置信息"
    echo ""
    echo -e "${BLUE}🧹 清理维护${NC}"
    echo "  14) 清理Docker缓存"
    echo "  15) 完全卸载"
    echo ""
    echo -e "${BLUE}🔗 全局命令${NC}"
    echo "  16) 安装全局命令"
    echo "  17) 卸载全局命令"
    echo "  18) 检查命令状态"
    echo ""
    echo -e "${BLUE}📖 帮助信息${NC}"
    echo "  19) 查看帮助"
    echo "  0) 退出"
    echo ""
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
    
    # 生成随机密码
    local mysql_root_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    local mysql_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    local redis_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    
    # 获取本机IP
    local host_ip=$(hostname -I | awk '{print $1}')
    
    # 创建.env文件
    print_info "正在生成配置文件..."
    
    # 后端配置
    cat > "$PROJECT_ROOT/server-app/.env" << EOF
APP_NAME=MineAdmin
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://$host_ip:9501
APP_TIMEZONE=Asia/Shanghai

# 数据库配置
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=mineadmin
DB_USERNAME=mineadmin
DB_PASSWORD=$mysql_password

# Redis配置
REDIS_HOST=redis
REDIS_PASSWORD=$redis_password
REDIS_PORT=6379
REDIS_DB=0

# JWT配置
JWT_SECRET=$(openssl rand -base64 32)

# 应用路径配置（容器内路径）
APP_RUNTIME_PATH=/runtime
APP_STORAGE_PATH=/storage
APP_LOG_PATH=/logs
APP_TEMP_PATH=/tmp
EOF
    
    # 前端开发配置
    cat > "$PROJECT_ROOT/web/.env.development" << EOF
VITE_APP_API_URL=http://$host_ip:9501
VITE_APP_BASE_API=/api
VITE_APP_UPLOAD_URL=http://$host_ip:9501/upload
EOF
    
    # 前端生产配置
    cat > "$PROJECT_ROOT/web/.env.production" << EOF
VITE_APP_API_URL=http://$host_ip:9501
VITE_APP_BASE_API=/api
VITE_APP_UPLOAD_URL=http://$host_ip:9501/upload
EOF
    
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
    
    # 构建前端开发镜像
    docker build --platform $build_arch -f docker/Dockerfile.web-dev -t mineadmin/web-dev:latest ./web
    
    # 构建前端生产镜像
    docker build --platform $build_arch -f docker/Dockerfile.web-prod -t mineadmin/web-prod:latest ./web
    
    # 启动服务
    print_info "正在启动服务..."
    docker-compose -f docker/docker-compose.yml up -d
    
    # 等待服务启动
    print_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    if docker-compose -f docker/docker-compose.yml ps | grep -q "Up"; then
        print_success "MineAdmin安装完成！"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}🎯 访问信息:${NC}"
        echo "后端API: http://$host_ip:9501"
        echo "前端开发: http://$host_ip:2888"
        echo "前端生产: http://$host_ip:80"
        echo ""
        echo -e "${WHITE}🔐 数据库信息:${NC}"
        echo "MySQL Root密码: $mysql_root_password"
        echo "MySQL 用户密码: $mysql_password"
        echo "Redis 密码: $redis_password"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # 安装全局命令
        install_global_command
    else
        print_error "服务启动失败，请检查日志"
        docker-compose -f docker/docker-compose.yml logs
    fi
}

# 选择Web模式
select_web_mode() {
    echo -e "${WHITE}请选择Web模式:${NC}"
    echo "1) 开发模式 (pnpm run dev)"
    echo "2) 生产模式 (nginx)"
    echo ""
    read -p "请输入选择 (1-2): " choice
    
    case $choice in
        1)
            print_info "切换到开发模式..."
            docker-compose -f docker/docker-compose.yml stop web-prod
            docker-compose -f docker/docker-compose.yml up -d web-dev
            print_success "已切换到开发模式，访问地址: http://$(hostname -I | awk '{print $1}'):2888"
            ;;
        2)
            print_info "切换到生产模式..."
            docker-compose -f docker/docker-compose.yml stop web-dev
            docker-compose -f docker/docker-compose.yml up -d web-prod
            print_success "已切换到生产模式，访问地址: http://$(hostname -I | awk '{print $1}'):80"
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 启动所有服务
start_services() {
    print_info "正在启动所有服务..."
    cd "$PROJECT_ROOT"
    docker-compose -f docker/docker-compose.yml up -d
    print_success "所有服务已启动"
}

# 停止所有服务
stop_services() {
    print_info "正在停止所有服务..."
    cd "$PROJECT_ROOT"
    docker-compose -f docker/docker-compose.yml down
    print_success "所有服务已停止"
}

# 重启所有服务
restart_services() {
    print_info "正在重启所有服务..."
    cd "$PROJECT_ROOT"
    docker-compose -f docker/docker-compose.yml restart
    print_success "所有服务已重启"
}

# 查看服务状态
show_service_status() {
    print_info "服务状态:"
    cd "$PROJECT_ROOT"
    docker-compose -f docker/docker-compose.yml ps
    echo ""
    print_info "系统资源使用情况:"
    docker stats --no-stream
}

# 查看容器日志
show_container_logs() {
    echo -e "${WHITE}请选择要查看的容器日志:${NC}"
    echo "1) MySQL"
    echo "2) Redis"
    echo "3) Server App"
    echo "4) Web Dev"
    echo "5) Web Prod"
    echo ""
    read -p "请输入选择 (1-5): " choice
    
    case $choice in
        1)
            docker-compose -f docker/docker-compose.yml logs mysql
            ;;
        2)
            docker-compose -f docker/docker-compose.yml logs redis
            ;;
        3)
            docker-compose -f docker/docker-compose.yml logs server-app
            ;;
        4)
            docker-compose -f docker/docker-compose.yml logs web-dev
            ;;
        5)
            docker-compose -f docker/docker-compose.yml logs web-prod
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
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
    netstat -tlnp
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
    
    # 生成新的随机密码
    local mysql_root_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    local mysql_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    local redis_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    
    # 获取本机IP
    local host_ip=$(hostname -I | awk '{print $1}')
    
    # 更新后端配置
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$mysql_password/" "$PROJECT_ROOT/server-app/.env"
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$redis_password/" "$PROJECT_ROOT/server-app/.env"
    sed -i "s/APP_URL=.*/APP_URL=http:\/\/$host_ip:9501/" "$PROJECT_ROOT/server-app/.env"
    
    # 更新前端配置
    sed -i "s/VITE_APP_API_URL=.*/VITE_APP_API_URL=http:\/\/$host_ip:9501/" "$PROJECT_ROOT/web/.env.development"
    sed -i "s/VITE_APP_API_URL=.*/VITE_APP_API_URL=http:\/\/$host_ip:9501/" "$PROJECT_ROOT/web/.env.production"
    
    print_success "配置已重新生成"
    echo ""
    echo -e "${WHITE}新的密码信息:${NC}"
    echo "MySQL Root密码: $mysql_root_password"
    echo "MySQL 用户密码: $mysql_password"
    echo "Redis 密码: $redis_password"
}

# 修改密码
change_passwords() {
    echo -e "${WHITE}请选择要修改的密码:${NC}"
    echo "1) MySQL Root密码"
    echo "2) MySQL 用户密码"
    echo "3) Redis 密码"
    echo ""
    read -p "请输入选择 (1-3): " choice
    
    case $choice in
        1)
            read -s -p "请输入新的MySQL Root密码: " new_password
            echo ""
            # 这里需要实现修改MySQL Root密码的逻辑
            print_info "MySQL Root密码修改功能待实现"
            ;;
        2)
            read -s -p "请输入新的MySQL用户密码: " new_password
            echo ""
            # 这里需要实现修改MySQL用户密码的逻辑
            print_info "MySQL用户密码修改功能待实现"
            ;;
        3)
            read -s -p "请输入新的Redis密码: " new_password
            echo ""
            # 这里需要实现修改Redis密码的逻辑
            print_info "Redis密码修改功能待实现"
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
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
        docker-compose -f docker/docker-compose.yml down -v
        
        # 删除镜像
        docker rmi mineadmin/server-app:latest mineadmin/web-dev:latest mineadmin/web-prod:latest 2>/dev/null || true
        
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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📖 MineAdmin 管理工具帮助${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}🚀 快速开始:${NC}"
    echo "1. 运行系统兼容性检测"
    echo "2. 执行一键安装部署"
    echo "3. 选择Web模式 (开发/生产)"
    echo ""
    echo -e "${BLUE}⚙️  服务管理:${NC}"
    echo "- 启动/停止/重启所有服务"
    echo "- 查看服务状态和资源使用"
    echo "- 查看容器日志"
    echo ""
    echo -e "${BLUE}🔧 配置管理:${NC}"
    echo "- 重新生成配置文件"
    echo "- 修改数据库密码"
    echo "- 查看当前配置"
    echo ""
    echo -e "${BLUE}🔗 全局命令:${NC}"
    echo "- 安装后可在任何目录使用 'hook' 命令"
    echo "- 支持Bash和Zsh"
    echo ""
    echo -e "${BLUE}📋 系统要求:${NC}"
    echo "- Ubuntu 24.04 LTS (推荐)"
    echo "- x86_64 或 ARM64 架构"
    echo "- 至少2GB内存"
    echo "- 至少10GB可用磁盘空间"
    echo ""
    echo -e "${BLUE}🌐 访问地址:${NC}"
    echo "- 后端API: http://服务器IP:9501"
    echo "- 前端开发: http://服务器IP:2888"
    echo "- 前端生产: http://服务器IP:80"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    
    # 主循环
    while true; do
        show_main_menu
        read -p "请输入选择 (0-19): " choice
        
        case $choice in
            0)
                print_info "退出程序"
                exit 0
                ;;
            1)
                check_system_compatibility
                ;;
            2)
                install_mineadmin
                ;;
            3)
                select_web_mode
                ;;
            4)
                start_services
                ;;
            5)
                stop_services
                ;;
            6)
                restart_services
                ;;
            7)
                show_service_status
                ;;
            8)
                show_container_logs
                ;;
            9)
                show_system_resources
                ;;
            10)
                show_network_connections
                ;;
            11)
                regenerate_config
                ;;
            12)
                change_passwords
                ;;
            13)
                show_config_info
                ;;
            14)
                clean_docker_cache
                ;;
            15)
                uninstall_mineadmin
                ;;
            16)
                install_global_command
                ;;
            17)
                uninstall_global_command
                ;;
            18)
                check_command_status
                ;;
            19)
                show_help
                ;;
            *)
                print_error "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
    done
}

# 运行主函数
main "$@"
