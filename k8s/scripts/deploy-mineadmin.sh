#!/bin/bash

# MineAdmin K8s 部署脚本
# 用于将 MineAdmin 部署到 Kubernetes 集群

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${WHITE}ℹ️  $1${NC}"
}

# 检查 kubectl 是否可用
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装，请先安装 Kubernetes"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "无法连接到 Kubernetes 集群"
        exit 1
    fi
    
    print_success "Kubernetes 集群连接正常"
}

# 创建命名空间
create_namespace() {
    print_info "创建 mineadmin 命名空间..."
    kubectl create namespace mineadmin --dry-run=client -o yaml | kubectl apply -f -
    print_success "命名空间创建完成"
}

# 部署 MySQL
deploy_mysql() {
    print_info "部署 MySQL..."
    kubectl apply -f manifests/mysql.yaml
    print_success "MySQL 部署完成"
}

# 部署 Redis
deploy_redis() {
    print_info "部署 Redis..."
    kubectl apply -f manifests/redis.yaml
    print_success "Redis 部署完成"
}

# 部署 MineAdmin 后端
deploy_server() {
    print_info "部署 MineAdmin 后端服务..."
    kubectl apply -f manifests/server-app.yaml
    print_success "MineAdmin 后端部署完成"
}

# 部署 MineAdmin 前端
deploy_web() {
    print_info "部署 MineAdmin 前端服务..."
    kubectl apply -f manifests/web.yaml
    print_success "MineAdmin 前端部署完成"
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务就绪..."
    
    # 等待 MySQL
    kubectl wait --for=condition=ready pod -l app=mysql -n mineadmin --timeout=300s
    print_success "MySQL 就绪"
    
    # 等待 Redis
    kubectl wait --for=condition=ready pod -l app=redis -n mineadmin --timeout=300s
    print_success "Redis 就绪"
    
    # 等待后端服务
    kubectl wait --for=condition=ready pod -l app=mineadmin-server -n mineadmin --timeout=300s
    print_success "MineAdmin 后端就绪"
    
    # 等待前端服务
    kubectl wait --for=condition=ready pod -l app=mineadmin-web -n mineadmin --timeout=300s
    print_success "MineAdmin 前端就绪"
}

# 显示部署状态
show_status() {
    print_info "部署状态:"
    echo ""
    echo -e "${WHITE}命名空间:${NC}"
    kubectl get namespaces | grep mineadmin
    
    echo ""
    echo -e "${WHITE}Pod 状态:${NC}"
    kubectl get pods -n mineadmin
    
    echo ""
    echo -e "${WHITE}服务状态:${NC}"
    kubectl get services -n mineadmin
    
    echo ""
    echo -e "${WHITE}Ingress 状态:${NC}"
    kubectl get ingress -n mineadmin
}

# 显示访问信息
show_access_info() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🎯 MineAdmin 访问信息:${NC}"
    echo ""
    echo -e "${WHITE}本地访问:${NC}"
    echo "kubectl port-forward -n mineadmin svc/mineadmin-web-service 8080:80"
    echo "然后访问: http://localhost:8080"
    echo ""
    echo -e "${WHITE}API 访问:${NC}"
    echo "kubectl port-forward -n mineadmin svc/mineadmin-server-service 8081:80"
    echo "然后访问: http://localhost:8081"
    echo ""
    echo -e "${WHITE}集群内访问:${NC}"
    echo "前端: http://mineadmin-web-service.mineadmin.svc.cluster.local"
    echo "后端: http://mineadmin-server-service.mineadmin.svc.cluster.local"
    echo ""
    echo -e "${WHITE}数据库连接:${NC}"
    echo "MySQL: mysql-service.mineadmin.svc.cluster.local:3306"
    echo "Redis: redis-service.mineadmin.svc.cluster.local:6379"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 主函数
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🚀 MineAdmin Kubernetes 部署脚本${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 检查 kubectl
    check_kubectl
    
    # 创建命名空间
    create_namespace
    
    # 部署服务
    deploy_mysql
    deploy_redis
    deploy_server
    deploy_web
    
    # 等待服务就绪
    wait_for_services
    
    # 显示状态
    show_status
    
    # 显示访问信息
    show_access_info
    
    print_success "MineAdmin 部署完成！"
}

# 运行主函数
main "$@"
