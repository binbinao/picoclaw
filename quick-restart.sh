#!/bin/bash

# quick-restart.sh
# 快速重启picoclaw服务（不重新构建）
# 用法: ./quick-restart.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 快速重启picoclaw服务 ===${NC}"

# 检查是否在正确目录
if [ ! -f "go.mod" ] || [ ! -f "Makefile" ]; then
    echo -e "${RED}错误: 当前目录不是picoclaw项目根目录${NC}"
    echo "请切换到 /Users/jiduobin/Documents/GitHub/picoclaw 目录"
    exit 1
fi

# 获取当前进程ID
PID=$(ps aux | grep "picoclaw gateway" | grep -v grep | awk '{print $2}')

if [ -n "$PID" ]; then
    echo "停止当前服务 (PID: $PID)"
    kill $PID 2>/dev/null
    sleep 2
    
    # 检查是否停止成功
    if ps -p $PID > /dev/null 2>&1; then
        echo "强制停止..."
        kill -9 $PID 2>/dev/null
        sleep 1
    fi
    
    echo "服务已停止"
else
    echo "没有找到运行的picoclaw服务"
fi

# 启动新服务
echo "启动picoclaw网关服务..."
nohup ./build/picoclaw gateway > /tmp/picoclaw-gateway.log 2>&1 &
NEW_PID=$!

echo "服务已启动 (PID: $NEW_PID)"
echo "日志文件: /tmp/picoclaw-gateway.log"

# 等待服务启动
sleep 3

# 检查服务状态
if ps -p $NEW_PID > /dev/null 2>&1; then
    echo -e "${GREEN}服务进程运行正常${NC}"
else
    echo -e "${RED}服务进程启动失败${NC}"
    echo "查看日志: tail -f /tmp/picoclaw-gateway.log"
    exit 1
fi

# 检查健康状态
echo "检查服务健康状态..."
if curl -s http://127.0.0.1:18790/health > /dev/null 2>&1; then
    RESPONSE=$(curl -s http://127.0.0.1:18790/health)
    STATUS=$(echo $RESPONSE | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$STATUS" = "ok" ]; then
        UPTIME=$(echo $RESPONSE | grep -o '"uptime":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}服务健康检查通过 (uptime: $UPTIME)${NC}"
    else
        echo -e "${RED}服务健康状态异常${NC}"
    fi
else
    echo -e "${RED}无法连接到服务${NC}"
fi

echo -e "${BLUE}=== 服务信息 ===${NC}"
echo "进程ID: $NEW_PID"
echo "网关地址: http://127.0.0.1:18790"
echo "健康检查: http://127.0.0.1:18790/health"
echo "日志文件: /tmp/picoclaw-gateway.log"
echo -e "${GREEN}快速重启完成！${NC}"