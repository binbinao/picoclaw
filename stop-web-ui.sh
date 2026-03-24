#!/bin/bash

# Picoclaw Web UI 停止脚本
# 停止Web界面和相关的picoclaw-launcher进程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Picoclaw Web UI 停止器 ===${NC}"
echo

# 查找并停止picoclaw-launcher进程
echo -e "${BLUE}[INFO] 停止 picoclaw-launcher 进程...${NC}"
PIDS=$(pgrep -f "picoclaw-launcher" || true)

if [ -z "$PIDS" ]; then
    echo -e "${GREEN}[INFO] 没有找到运行中的Web UI进程${NC}"
else
    echo -e "${YELLOW}找到进程: $PIDS${NC}"
    kill $PIDS
    sleep 2
    
    # 检查是否还有残留进程
    REMAINING_PIDS=$(pgrep -f "picoclaw-launcher" || true)
    if [ -n "$REMAINING_PIDS" ]; then
        echo -e "${YELLOW}[WARNING] 强制停止残留进程: $REMAINING_PIDS${NC}"
        kill -9 $REMAINING_PIDS
    fi
    
    echo -e "${GREEN}[SUCCESS] Web UI已停止${NC}"
fi

# 可选：也停止picoclaw gateway
echo -e "${BLUE}[INFO] 检查是否需要停止 picoclaw gateway...${NC}"
GATEWAY_PIDS=$(pgrep -f "picoclaw gateway" || true)
if [ -n "$GATEWAY_PIDS" ]; then
    echo -e "${YELLOW}发现 gateway 进程: $GATEWAY_PIDS${NC}"
    read -p "是否同时停止gateway服务? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill $GATEWAY_PIDS
        echo -e "${GREEN}[SUCCESS] Gateway服务已停止${NC}"
    fi
fi

echo
echo -e "${GREEN}操作完成${NC}"