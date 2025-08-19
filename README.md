# MineAdmin Docker 部署指南

## 概述

本项目提供了完整的 Docker 部署方案，支持生产环境部署。

## 环境配置

### 生产环境  
- **web-prod**: 使用 nginx Alpine 镜像
- **特点**: 只映射 dist 目录，运行编译后的静态文件
- **端口**: 80
- **配置文件**: `.env.production`

## 快速开始

### 生产环境启动

```bash
# 构建前端生产版本
cd web
pnpm run build

# 启动生产环境
cd docker
docker-compose up -d
```

## 服务说明

### 生产环境服务
- `mysql`: MySQL 8.0 数据库
- `redis`: Redis 7 缓存
- `server-app`: 后端服务 (Hyperf)
- `web-prod`: 前端生产服务器 (nginx)

## 环境变量

### 数据库配置
- `MYSQL_ROOT_PASSWORD`: MySQL root 密码 (默认: root123)
- `DB_PASSWORD`: 数据库密码 (默认: mineadmin123)

### Redis 配置
- `REDIS_PASSWORD`: Redis 密码 (默认: redis123)

### 前端配置
- `VITE_APP_TITLE`: 应用标题 (默认: MineAdmin)
- `VITE_APP_API_URL`: API 地址 (默认: http://localhost:9501)

## 目录映射

### 生产环境
- `../web/dist:/usr/share/nginx/html`: 映射构建后的静态文件
- `./nginx/default.conf:/etc/nginx/conf.d/default.conf`: nginx 配置
- `web_logs:/var/log/nginx`: nginx 日志

## 注意事项

1. **生产环境**: 需要确保已运行 `pnpm run build` 构建生产版本
2. **配置文件**: 确保 `.env.production` 文件存在
3. **端口冲突**: 确保 3306、6379、9501、80 端口未被占用

## 故障排除

### 生产环境问题  
- 检查 `dist` 目录是否存在
- 检查 `.env.production` 配置文件
- 查看容器日志: `docker-compose logs web-prod`

## 常用命令

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service-name]

# 停止服务
docker-compose down

# 重新构建
docker-compose build

# 清理数据
docker-compose down -v
```

## 开发建议

对于开发环境，建议直接在宿主机上运行：

```bash
# 在宿主机上启动开发服务器
cd web
pnpm install
pnpm run dev
```

这样可以避免架构兼容性问题，并且支持热重载等开发特性。
