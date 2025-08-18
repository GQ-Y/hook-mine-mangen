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

### 方法一：使用统一管理工具（推荐）

```bash
# 进入项目根目录
cd /path/to/your/project

# 启动统一管理工具
./docker/mineadmin.sh
# 或者使用项目根目录的启动脚本
./start.sh

# 直接使用hook命令（安装全局命令后）
hook install    # 一键安装
hook start      # 启动服务
hook status     # 查看状态
hook help       # 查看帮助
```

统一管理工具提供以下功能：
- 🔍 系统兼容性检测
- 🚀 一键安装部署
- ⚙️ 服务管理（启动/停止/重启）
- 📊 状态监控和日志查看
- 🔧 配置管理
- 🧹 清理维护
- 🔗 全局命令管理
- 📖 帮助信息

### 方法二：使用全局命令（安装后）

安装完成后，系统会自动创建全局命令 `hook`，您可以在任何目录下使用：

```bash
# 在任何目录下启动管理工具
hook
```

### 方法三：直接使用Docker Compose

```bash
# 上传项目代码到服务器
# 进入项目根目录
cd /path/to/your/project

# 给脚本执行权限
chmod +x docker/*.sh

# 使用统一管理工具进行安装
./docker/mineadmin.sh
```

### 系统兼容性

本方案支持以下系统：
- **Ubuntu 24.04 LTS** (推荐)
- **架构支持**: x86_64 (Intel/AMD)、ARM64 (Apple Silicon/ARM) 和 macOS
- **Shell支持**: Bash 和 Zsh

### 特殊功能

- **swoole-cli 支持**: 自动检测系统架构并使用对应的 swoole-cli 库
- **Root 权限**: 容器以 root 用户运行，避免权限问题
- **根目录存储**: 使用根目录下的 `/storage`、`/runtime`、`/logs` 等目录，确保写入权限

## 统一管理工具功能详解

### 🚀 部署管理
- **1) 系统兼容性检测**: 检测系统架构、内存、磁盘空间等
- **2) 一键安装部署**: 首次使用，完整安装Docker和MineAdmin
- **3) 选择Web模式**: 在开发模式和生产模式间切换

### ⚙️ 服务管理
- **4) 启动所有服务**: 启动所有MineAdmin服务
- **5) 停止所有服务**: 停止所有MineAdmin服务
- **6) 重启所有服务**: 重启所有MineAdmin服务
- **7) 查看服务状态**: 显示所有容器状态和资源使用情况

### 📊 监控管理
- **7) 查看服务状态**: 显示所有容器状态和资源使用情况
- **8) 查看容器日志**: 查看各服务的详细日志
- **9) 查看系统资源**: 显示CPU、内存、磁盘使用情况

### 🔧 配置管理
- **10) 查看网络连接**: 显示网络连接和Docker网络信息
- **11) 重新生成配置**: 重新生成随机密码和配置文件
- **12) 修改密码**: 修改数据库、Redis或管理员密码
- **13) 查看配置信息**: 显示当前配置文件内容
- **14) 查看已安装插件**: 显示已安装的插件列表

### 🧹 清理维护
- **15) 清理Docker缓存**: 清理Docker镜像和缓存
- **16) 完全卸载**: 完全删除所有服务和数据

### 🔗 全局命令
- **17) 安装全局命令**: 安装 `hook` 全局命令
- **18) 卸载全局命令**: 卸载 `hook` 全局命令
- **19) 检查命令状态**: 检查全局命令安装状态

### 📖 帮助信息
- **20) 查看帮助**: 显示详细使用说明

## 服务端口说明
- **Nginx**: 80 (生产模式前端)
- **Web Dev**: 2888 (开发模式前端)
- **Server App**: 9501 (后端API)
- **Redis**: 6379 (缓存服务)
- **MySQL**: 3306 (数据库服务)

## 常用命令

### Hook命令使用（推荐）

安装全局命令后，您可以在任何目录使用 `hook` 命令：

```bash
# 系统管理
hook check        # 系统兼容性检测
hook install      # 一键安装部署
hook web          # 选择Web模式

# 服务管理
hook start        # 启动所有服务
hook stop         # 停止所有服务
hook restart      # 重启所有服务
hook status       # 查看服务状态
hook logs         # 查看容器日志
hook resources    # 查看系统资源

# 配置管理
hook config       # 重新生成配置
hook password     # 修改密码
hook info         # 查看配置信息
hook plugins      # 查看已安装插件
hook network      # 查看网络连接

# 维护管理
hook clean        # 清理Docker缓存
hook uninstall    # 完全卸载

# 全局命令
hook setup        # 安装全局命令
hook remove       # 卸载全局命令
hook test         # 检查命令状态
hook help         # 查看帮助信息
```

### 交互式菜单

```bash
# 使用统一管理工具
./docker/mineadmin.sh
# 选择选项 7) 查看服务状态

# 或使用全局命令
hook
# 选择选项 7) 查看服务状态
```

### 查看日志
```bash
# 使用统一管理工具
./docker/mineadmin.sh
# 选择选项 8) 查看容器日志

# 或使用全局命令
hook
# 选择选项 8) 查看容器日志
```

### 重启服务
```bash
# 使用统一管理工具
./docker/mineadmin.sh
# 选择选项 6) 重启所有服务

# 或使用全局命令
hook
# 选择选项 6) 重启所有服务
```

### 停止服务
```bash
# 使用统一管理工具
./docker/mineadmin.sh
# 选择选项 5) 停止所有服务

# 或使用全局命令
hook
# 选择选项 5) 停止所有服务
```

### 卸载服务
```bash
# 使用统一管理工具
./docker/mineadmin.sh
# 选择选项 15) 完全卸载

# 或使用全局命令
hook
# 选择选项 15) 完全卸载
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
# 使用统一管理工具查看日志
./docker/mineadmin.sh
# 选择选项 8) 查看容器日志

# 或使用全局命令
hook
# 选择选项 8) 查看容器日志
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

## 文件结构
```
docker/
├── README.md                 # 说明文档
├── mineadmin.sh              # 统一管理脚本（主要入口）
├── docker-compose.yml        # Docker Compose配置
├── cli/                      # swoole-cli 库文件
│   ├── x64/swoole-cli       # x86_64 架构
│   ├── arm64/swoole-cli     # ARM64 架构
│   └── macos/swoole-cli     # macOS 架构
├── k8s/                      # Kubernetes配置文件
│   ├── namespace.yaml        # 命名空间和配置映射
│   ├── secrets.yaml          # 密钥配置
│   ├── mysql.yaml           # MySQL服务配置
│   ├── redis.yaml           # Redis服务配置
│   ├── server-app.yaml      # 后端服务配置
│   └── web.yaml             # 前端服务配置
├── scripts/                  # 容器启动脚本
│   ├── start-server.sh      # 后端启动脚本
│   └── start-web-dev.sh     # 前端开发启动脚本
├── nginx/                    # Nginx配置
│   └── default.conf         # Nginx配置文件
├── Dockerfile.server-app     # 后端Dockerfile
├── Dockerfile.web-dev        # 前端开发Dockerfile
└── Dockerfile.web-prod       # 前端生产Dockerfile
```

## 更新日志
- v1.0.0: 初始版本，支持基础部署功能
- v1.1.0: 添加统一管理工具，提供完整的操作界面
- v1.2.0: 支持多架构 swoole-cli，优化权限管理
