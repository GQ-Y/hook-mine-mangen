# MineAdmin K8s 部署方案

## 概述
这是一个基于Kubernetes的MineAdmin模板项目标准化部署方案，支持一键部署完整的开发环境。

## 系统要求
- Ubuntu 24.04 LTS
- 至少2GB内存
- 至少10GB可用磁盘空间
- 网络连接（用于下载镜像和依赖）

## 部署架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Pod     │    │  Server App     │    │   Web Dev Pod   │
│   (生产模式)     │    │   (后端服务)     │    │   (开发模式)     │
│   端口: 80      │    │   端口: 9501     │    │   端口: 2888    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │   Redis Pod     │    │   MySQL Pod     │
                    │   端口: 6379     │    │   端口: 3306    │
                    └─────────────────┘    └─────────────────┘
```

## 快速开始

### 1. 准备环境
```bash
# 上传项目代码到服务器
# 进入项目根目录
cd /path/to/your/project

# 给脚本执行权限
chmod +x docker/install.sh
```

### 2. 执行安装脚本
```bash
./docker/install.sh
```

### 3. 选择部署模式
脚本会引导您选择：
- 单机部署（推荐开发环境）
- 主控节点部署
- 工作节点部署

### 4. 初始化配置
脚本会自动：
- 生成随机密码
- 配置环境变量
- 初始化数据库
- 启动所有服务

## 服务端口说明
- **Nginx**: 80 (生产模式前端)
- **Web Dev**: 2888 (开发模式前端)
- **Server App**: 9501 (后端API)
- **Redis**: 6379 (缓存服务)
- **MySQL**: 3306 (数据库服务)

## 常用命令

### 查看服务状态
```bash
kubectl get pods -n mineadmin
kubectl get services -n mineadmin
```

### 查看日志
```bash
# 查看后端服务日志
kubectl logs -f deployment/server-app -n mineadmin

# 查看前端服务日志
kubectl logs -f deployment/web-dev -n mineadmin
```

### 重启服务
```bash
./docker/restart.sh
```

### 停止服务
```bash
./docker/stop.sh
```

### 卸载服务
```bash
./docker/uninstall.sh
```

## 配置文件说明

### 环境变量文件
- `.env`: 后端服务配置
- `.env.development`: 前端开发环境配置
- `.env.production`: 前端生产环境配置

### 数据库配置
- 数据库名: mineadmin
- 用户名: mineadmin
- 密码: 自动生成（8-16位随机字符）

### Redis配置
- 密码: 自动生成（8-16位随机字符）

## 故障排除

### 常见问题
1. **服务启动失败**: 检查端口是否被占用
2. **数据库连接失败**: 确认MySQL Pod已启动
3. **前端无法访问**: 检查Nginx配置和端口映射

### 日志查看
```bash
# 查看所有Pod状态
kubectl get pods -n mineadmin

# 查看具体Pod日志
kubectl logs <pod-name> -n mineadmin
```

## 开发模式 vs 生产模式

### 开发模式
- 前端使用 `pnpm run dev` 启动
- 支持热重载
- 端口映射到宿主机2888
- 启用代理转发

### 生产模式
- 前端使用 `pnpm run build` 编译
- 通过Nginx提供静态文件服务
- 端口映射到宿主机80
- 无代理转发

## 安全说明
- 所有密码均为随机生成
- 数据库和Redis密码长度8-16位
- 生产环境建议修改默认密码
- 定期备份数据库数据

## 更新日志
- v1.0.0: 初始版本，支持基础部署功能
