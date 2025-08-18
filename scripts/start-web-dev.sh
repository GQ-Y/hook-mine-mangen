#!/bin/bash

# MineAdmin 前端开发模式启动脚本
# 用于在容器中启动前端开发服务器

set -e

echo "=========================================="
echo "🚀 启动 MineAdmin 前端开发服务器"
echo "=========================================="

# 设置环境变量
export TZ=${TZ:-"Asia/Shanghai"}
export NODE_ENV=${NODE_ENV:-"development"}
export VITE_APP_TITLE=${VITE_APP_TITLE:-"MineAdmin"}
export VITE_APP_API_URL=${VITE_APP_API_URL:-"http://localhost:9501"}

echo "📅 时区设置: $TZ"
echo "🌍 环境模式: $NODE_ENV"
echo "📱 应用标题: $VITE_APP_TITLE"
echo "🔗 API地址: $VITE_APP_API_URL"

# 检查 Node.js 和 pnpm
echo "🔍 检查 Node.js 环境..."
node --version || {
    echo "❌ 错误: Node.js 未安装"
    exit 1
}

pnpm --version || {
    echo "❌ 错误: pnpm 未安装"
    exit 1
}

echo "✅ Node.js 环境检查完成"

# 进入应用目录
cd /app

# 检查 package.json 是否存在
if [ ! -f "package.json" ]; then
    echo "❌ 错误: package.json 文件不存在"
    exit 1
fi

echo "📦 检查依赖包..."

# 强制重新安装依赖（解决 Rollup 架构兼容性问题）
echo "📥 重新安装依赖包..."
rm -rf node_modules pnpm-lock.yaml
pnpm install
echo "✅ 依赖包安装完成"

# 检查后端服务是否就绪（可选）
echo "⏳ 检查后端服务状态..."
if [ -n "$VITE_APP_API_URL" ]; then
    # 提取主机地址
    API_HOST=$(echo $VITE_APP_API_URL | sed 's|^https\?://||' | sed 's|:.*$||')
    API_PORT=$(echo $VITE_APP_API_URL | sed 's|^https\?://[^:]*:||' | sed 's|/.*$||')
    
    if [ -z "$API_PORT" ]; then
        API_PORT=9501
    fi
    
    echo "🔍 检查后端服务: $API_HOST:$API_PORT"
    
    # 简单检查后端服务（不等待）
    if nc -z $API_HOST $API_PORT 2>/dev/null; then
        echo "✅ 后端服务已就绪"
    else
        echo "⚠️  警告: 后端服务未就绪，但继续启动前端服务"
    fi
fi

# 启动开发服务器
echo "🚀 启动前端开发服务器..."
echo "📊 服务端口: 2888"
echo "🌐 访问地址: http://localhost:2888"
echo "=========================================="

# 使用 pnpm 启动开发服务器（禁用自动打开浏览器）
exec pnpm run dev --host 0.0.0.0 --port 2888 --no-open
