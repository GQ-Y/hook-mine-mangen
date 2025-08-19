#!/bin/bash

# MineAdmin 后端服务启动脚本
# 用于在容器中启动后端服务

set -e

echo "=========================================="
echo "🚀 启动 MineAdmin 后端服务"
echo "=========================================="

# 设置环境变量
export TZ=${TZ:-"Asia/Shanghai"}

# 设置应用目录
export APP_RUNTIME_PATH="/runtime"
export APP_STORAGE_PATH="/storage"
export APP_LOG_PATH="/logs"
export APP_TEMP_PATH="/tmp"

echo "📅 时区设置: $TZ"

# 检查 .env 文件是否存在
if [ ! -f /app/.env ]; then
    echo "❌ 错误: .env 文件不存在"
    exit 1
fi

echo "✅ 找到 .env 文件"

# 读取 .env 文件并设置环境变量
echo "🔧 加载环境配置..."
while IFS='=' read -r key value; do
    # 跳过注释和空行
    if [[ $key =~ ^[[:space:]]*# ]] || [[ -z $key ]]; then
        continue
    fi
    
    # 移除前后空格
    key=$(echo $key | xargs)
    value=$(echo $value | xargs)
    
    # 设置环境变量
    export "$key=$value"
done < /app/.env

# 覆盖数据库和 Redis 配置以适配 Docker 网络
echo "🔧 更新网络配置以适配 Docker 环境..."
export DB_HOST="mysql"
export REDIS_HOST="redis"
export DB_PASSWORD="${DB_PASSWORD:-mineadmin123}"
export REDIS_AUTH="${REDIS_PASSWORD:-redis123}"

echo "✅ 环境配置已加载"
echo "📋 当前环境配置:"
echo "   APP_ENV: ${APP_ENV}"
echo "   APP_DEBUG: ${APP_DEBUG}"
echo "   DB_HOST: ${DB_HOST}"
echo "   REDIS_HOST: ${REDIS_HOST}"
echo "   DB_PASSWORD: ${DB_PASSWORD}"
echo "   REDIS_AUTH: ${REDIS_AUTH}"

# 等待数据库服务就绪
echo "⏳ 等待数据库服务就绪..."
while ! nc -z mysql 3306; do
    echo "   数据库服务未就绪，等待 2 秒..."
    sleep 2
done
echo "✅ 数据库服务已就绪"

# 等待Redis服务就绪
echo "⏳ 等待Redis服务就绪..."
while ! nc -z redis 6379; do
    echo "   Redis服务未就绪，等待 2 秒..."
    sleep 2
done
echo "✅ Redis服务已就绪"

# 检查数据库连接
echo "🔍 检查数据库连接..."
# 使用简单的数据库连接测试
swoole-cli bin/hyperf.php db:seed --class=menu_seeder_20240926 || {
    echo "⚠️  数据库连接测试失败，但继续启动服务"
}
echo "✅ 数据库连接检查完成"

# 运行数据库迁移
echo "🔄 运行数据库迁移..."
swoole-cli bin/hyperf.php migrate --force || {
    echo "⚠️  数据库迁移失败，但继续启动服务"
}

# 清理缓存
echo "🧹 清理应用缓存..."
swoole-cli bin/hyperf.php cache:clear || true

# 生成应用密钥（如果不存在）
if [ ! -f .env ] || ! grep -q "APP_KEY=" .env; then
    echo "🔑 生成应用密钥..."
    swoole-cli bin/hyperf.php key:generate || true
fi

# 启动服务
echo "🚀 启动 MineAdmin 服务..."
echo "📊 服务端口: 9501 (HTTP), 9502 (WebSocket), 9509 (Notification)"
echo "=========================================="

# 使用 swoole-cli 启动服务，禁用短函数名
exec swoole-cli -d swoole.use_shortname='Off' bin/hyperf.php start
