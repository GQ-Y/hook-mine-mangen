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
while IFS='=' read -r line; do
    # 跳过注释和空行
    if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $line ]]; then
        continue
    fi
    
    # 移除前后空格
    line=$(echo "$line" | xargs)
    
    # 提取键和值（处理等号前后可能有空格的情况）
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # 移除键和值的前后空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # 设置环境变量
        export "$key=$value"
        echo "   设置环境变量: $key"
    fi
done < /app/.env

# 检查并显示当前配置
echo "📋 当前环境配置:"

echo "✅ 环境配置已加载"
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

# 使用mysql命令测试数据库连接
echo "🔍 测试MySQL数据库连接..."
if mysql -h mysql -P 3306 -u root -p${DB_PASSWORD} -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ MySQL数据库连接测试成功"
else
    echo "❌ MySQL数据库连接测试失败"
    exit 1
fi

# 使用redis-cli测试Redis连接
echo "🔍 测试Redis连接..."
if redis-cli -h redis -p 6379 -a ${REDIS_AUTH} ping > /dev/null 2>&1; then
    echo "✅ Redis连接测试成功"
else
    echo "❌ Redis连接测试失败"
    exit 1
fi

# 检查初始化锁文件
echo "🔍 检查初始化锁文件..."
if [ -f /app/runtime/init.lock ]; then
    echo "✅ 初始化锁文件已存在，跳过数据库迁移和填充"
    echo "🚀 直接启动 MineAdmin 服务..."
    echo "📊 服务端口: 9501 (HTTP), 9502 (WebSocket), 9509 (Notification)"
    echo "=========================================="
    exec swoole-cli -d swoole.use_shortname='Off' bin/hyperf.php start
fi

echo "🔄 初始化锁文件不存在，开始执行数据库初始化..."

# 初始化状态标志
INIT_SUCCESS=true

# 运行数据库迁移
echo "🔄 运行数据库迁移..."
if swoole-cli bin/hyperf.php migrate --force; then
    echo "✅ 数据库迁移执行成功"
else
    echo "❌ 数据库迁移执行失败"
    INIT_SUCCESS=false
fi

# 运行数据库填充
echo "🔄 运行数据库填充..."
if swoole-cli bin/hyperf.php db:seed; then
    echo "✅ 数据库填充执行成功"
else
    echo "❌ 数据库填充执行失败"
    INIT_SUCCESS=false
fi

# 只有在所有初始化步骤都成功时才创建锁文件
if [ "$INIT_SUCCESS" = true ]; then
    echo "🔒 所有初始化步骤成功，创建初始化锁文件..."
    mkdir -p /app/runtime
    touch /app/runtime/init.lock
    echo "✅ 初始化锁文件创建成功"
else
    echo "❌ 数据库初始化失败，不创建锁文件"
    echo "⚠️  请检查数据库配置和迁移文件，然后重新启动服务"
    exit 1
fi

# 启动服务
echo "🚀 启动 MineAdmin 服务..."
echo "📊 服务端口: 9501 (HTTP), 9502 (WebSocket), 9509 (Notification)"
echo "=========================================="

# 使用 nohup 启动服务，确保常驻后台运行
echo "🔄 启动 MineAdmin 服务进程..."
nohup swoole-cli -d swoole.use_shortname='Off' bin/hyperf.php start > /app/logs/hyperf.log 2>&1 &

# 获取进程ID
SERVER_PID=$!
echo "✅ 服务进程已启动，PID: $SERVER_PID"

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务是否正常运行
if ps -p $SERVER_PID > /dev/null; then
    echo "✅ MineAdmin 服务启动成功，正在后台运行"
    echo "📊 服务端口: 9501 (HTTP), 9502 (WebSocket), 9509 (Notification)"
    echo "📝 日志文件: /app/logs/hyperf.log"
    echo "=========================================="
    
    # 保持容器运行，监控服务进程
    while ps -p $SERVER_PID > /dev/null; do
        sleep 10
    done
    
    echo "❌ 服务进程已停止"
    exit 1
else
    echo "❌ 服务启动失败"
    echo "📝 查看日志: tail -f /app/logs/hyperf.log"
    exit 1
fi
