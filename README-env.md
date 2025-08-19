# MineAdmin 环境配置说明

## 问题描述

在 Docker 环境中，容器内的应用需要与宿主机保持环境配置一致，特别是 `.env` 文件，因为该文件经常需要修改。

## 解决方案

### 1. 文件映射方式

将宿主机的 `.env` 文件直接映射到容器中：

```yaml
volumes:
  - ../server-app/.env:/app/.env
```

### 2. 环境变量覆盖

在容器启动时，启动脚本会：

1. **读取映射的 `.env` 文件**：加载所有配置到环境变量
2. **覆盖网络配置**：自动更新数据库和 Redis 配置指向 Docker 网络中的服务
3. **保持其他配置**：应用名称、调试模式等配置保持不变

### 3. 配置流程

1. **宿主机配置**：修改 `server-app/.env` 文件
2. **容器启动**：启动脚本读取 `.env` 文件并设置环境变量
3. **网络适配**：自动覆盖数据库和 Redis 配置
4. **服务运行**：应用使用环境变量中的配置

## 使用方法

### 开发环境

1. 修改 `server-app/.env` 文件中的配置
2. 重启容器：
   ```bash
   docker-compose restart server-app
   ```
3. 容器会自动使用更新后的配置

### 生产环境

1. 确保 `server-app/.env` 文件配置正确
2. 构建并启动服务：
   ```bash
   docker-compose up -d
   ```

## 配置示例

### 宿主机 .env 文件
```env
APP_NAME=MineAdmin
APP_ENV=dev
APP_DEBUG=true

DB_DRIVER=mysql
DB_HOST=19.168.1.126      # 宿主机配置
DB_PORT=3306
DB_DATABASE=mineadmin
DB_USERNAME=root
DB_PASSWORD=123456

REDIS_HOST=192.168.1.126  # 宿主机配置
REDIS_AUTH=123456
REDIS_PORT=6379
REDIS_DB=3
```

### 容器内环境变量（自动覆盖后）
```bash
APP_NAME=MineAdmin
APP_ENV=dev
APP_DEBUG=true

DB_DRIVER=mysql
DB_HOST=mysql             # 自动覆盖为 Docker 服务名
DB_PORT=3306
DB_DATABASE=mineadmin
DB_USERNAME=root
DB_PASSWORD=mineadmin123  # 使用 Docker Compose 环境变量

REDIS_HOST=redis          # 自动覆盖为 Docker 服务名
REDIS_AUTH=redis123       # 使用 Docker Compose 环境变量
REDIS_PORT=6379
REDIS_DB=3
```

## 优势

1. **实时生效**：修改 `.env` 文件后无需重新构建镜像
2. **配置一致**：宿主机和容器使用相同的配置文件
3. **开发友好**：便于调试和配置管理
4. **灵活性强**：支持不同环境的配置切换
5. **文件安全**：不修改映射的 `.env` 文件，避免权限问题

## 注意事项

1. 确保 `server-app/.env` 文件存在且可读
2. 容器启动时会自动覆盖数据库和 Redis 的网络配置
3. 数据库和 Redis 的密码会使用 Docker Compose 环境变量覆盖
4. 修改配置后需要重启容器才能生效
5. 应用会优先使用环境变量中的配置

## 技术实现

### 启动脚本逻辑

1. **读取 `.env` 文件**：逐行解析并设置环境变量
2. **跳过注释和空行**：只处理有效的配置项
3. **覆盖网络配置**：强制设置 `DB_HOST=mysql` 和 `REDIS_HOST=redis`
4. **保持其他配置**：应用名称、调试模式等保持不变

### 环境变量优先级

1. Docker Compose 环境变量（最高优先级）
2. 启动脚本中覆盖的配置
3. `.env` 文件中的配置（最低优先级）

## 故障排除

### 常见问题

1. **"Device or resource busy" 错误**：已通过环境变量覆盖方式解决
2. **配置不生效**：确保重启了容器
3. **网络连接失败**：检查 Docker 网络配置

### 调试方法

1. 查看容器日志：
   ```bash
   docker-compose logs server-app
   ```

2. 进入容器检查环境变量：
   ```bash
   docker-compose exec server-app env | grep -E "(DB_|REDIS_|APP_)"
   ```
