#!/bin/bash

# Picoclaw Web UI 启动脚本
# 启动内置的配置管理和Web界面

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取项目根目录
PROJECT_ROOT="/Users/jiduobin/Documents/GitHub/picoclaw"
LAUNCHER_PATH="$PROJECT_ROOT/cmd/picoclaw-launcher"
WEB_PORT=18800

echo -e "${BLUE}=== Picoclaw Web UI 启动器 ===${NC}"
echo -e "${BLUE}项目路径: $PROJECT_ROOT${NC}"
echo -e "${BLUE}Web界面端口: $WEB_PORT${NC}"
echo

# 检查启动器是否存在
if [ ! -f "$LAUNCHER_PATH/picoclaw-launcher" ]; then
    echo -e "${YELLOW}[INFO] 启动器未找到，正在构建...${NC}"
    cd "$PROJECT_ROOT"
    go build -o "$LAUNCHER_PATH/picoclaw-launcher" ./cmd/picoclaw-launcher/
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] 启动器构建完成${NC}"
    else
        echo -e "${RED}[ERROR] 启动器构建失败${NC}"
        exit 1
    fi
fi

# 检查端口是否被占用
echo -e "${BLUE}[INFO] 检查端口 $WEB_PORT...${NC}"
if lsof -Pi :$WEB_PORT -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}[WARNING] 端口 $WEB_PORT 已被占用${NC}"
    echo -e "${YELLOW}正在停止现有服务...${NC}"
    pkill -f "picoclaw-launcher" || true
    sleep 2
fi

# 启动Web UI
echo -e "${BLUE}[INFO] 启动 Web UI...${NC}"
echo -e "${GREEN}访问地址: http://localhost:$WEB_PORT${NC}"
echo -e "${YELLOW}按 Ctrl+C 停止服务${NC}"
echo

cd "$PROJECT_ROOT"
exec "$LAUNCHER_PATH/picoclaw-launcher" -public