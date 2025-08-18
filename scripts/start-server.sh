#!/bin/bash

# MineAdmin 后端服务启动脚本
# 用于在容器中启动后端服务

set -e

echo "=========================================="
echo "🚀 启动 MineAdmin 后端服务"
echo "=========================================="

# 设置环境变量
export TZ=${TZ:-"Asia/Shanghai"}
export APP_ENV=${APP_ENV:-"production"}
export APP_DEBUG=${APP_DEBUG:-"false"}

# 设置应用目录
export APP_RUNTIME_PATH="/runtime"
export APP_STORAGE_PATH="/storage"
export APP_LOG_PATH="/logs"
export APP_TEMP_PATH="/tmp"

echo "📅 时区设置: $TZ"
echo "🌍 环境模式: $APP_ENV"
echo "🐛 调试模式: $APP_DEBUG"

# 检查必要的环境变量
if [ -z "$DB_HOST" ]; then
    echo "❌ 错误: 数据库主机地址未设置"
    exit 1
fi

if [ -z "$REDIS_HOST" ]; then
    echo "❌ 错误: Redis主机地址未设置"
    exit 1
fi

echo "✅ 环境变量检查完成"

# 等待数据库服务就绪
echo "⏳ 等待数据库服务就绪..."
while ! nc -z $DB_HOST 3306; do
    echo "   数据库服务未就绪，等待 2 秒..."
    sleep 2
done
echo "✅ 数据库服务已就绪"

# 等待Redis服务就绪
echo "⏳ 等待Redis服务就绪..."
while ! nc -z $REDIS_HOST 6379; do
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

# 使用 swoole-cli 启动服务
exec swoole-cli bin/hyperf.php start
