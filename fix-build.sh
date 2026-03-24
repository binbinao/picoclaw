#!/bin/bash

# Picoclaw构建修复脚本
# 解决Go模块下载超时问题并重新构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Picoclaw构建修复脚本 ===${NC}"
echo

# 设置Go国内镜像源
echo -e "${BLUE}[INFO] 配置Go国内镜像源...${NC}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
echo -e "${GREEN}[SUCCESS] Go镜像配置完成${NC}"
echo "GOPROXY=$GOPROXY"
echo "GOSUMDB=$GOSUMDB"
echo

# 检查是否有正在运行的picoclaw进程
echo -e "${BLUE}[INFO] 检查并停止现有进程...${NC}"
PIDS=$(pgrep -f "picoclaw gateway" || true)
if [ -n "$PIDS" ]; then
    echo -e "${YELLOW}发现运行中的进程: $PIDS${NC}"
    kill $PIDS
    sleep 3
    echo -e "${GREEN}[SUCCESS] 进程已停止${NC}"
else
    echo -e "${GREEN}[INFO] 没有发现运行中的进程${NC}"
fi

# 清理可能的缓存
echo -e "${BLUE}[INFO] 清理Go缓存...${NC}"
cd /Users/jiduobin/Documents/GitHub/picoclaw
go clean -modcache
rm -rf ~/go/pkg/mod/cache/download
echo -e "${GREEN}[SUCCESS] 缓存清理完成${NC}"

# 尝试构建
echo -e "${BLUE}[INFO] 开始构建picoclaw...${NC}"
echo -e "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}"
echo

if make build; then
    echo -e "${GREEN}[SUCCESS] 构建成功！${NC}"
    
    # 启动服务
echo -e "${BLUE}[INFO] 启动picoclaw服务...${NC}"
    nohup ./build/picoclaw gateway > /tmp/picoclaw-gateway.log 2>&1 &
    
    # 等待服务启动
sleep 5
    
    # 检查服务状态
    if curl -s http://127.0.0.1:18790/health > /dev/null; then
        echo -e "${GREEN}[SUCCESS] 服务启动成功！${NC}"
        echo -e "${GREEN}健康检查: http://127.0.0.1:18790/health${NC}"
        
        # 显示进程信息
        NEW_PIDS=$(pgrep -f "picoclaw gateway" | head -1)
        if [ -n "$NEW_PIDS" ]; then
            echo -e "${GREEN}进程ID: $NEW_PIDS${NC}"
        fi
    else
        echo -e "${RED}[ERROR] 服务启动失败，请检查日志:${NC}"
        echo -e "${YELLOW}tail -20 /tmp/picoclaw-gateway.log${NC}"
    fi
else
    echo -e "${RED}[ERROR] 构建失败！${NC}"
    echo
    echo -e "${YELLOW}替代方案:${NC}"
    echo "1. 使用已有的二进制文件（如果存在）:"
    echo "   ./build/picoclaw gateway"
    echo
    echo "2. 稍后重试构建:"
    echo "   export GOPROXY=https://goproxy.cn,direct"
    echo "   make build"
    echo
    echo "3. 使用Web界面（如果launcher存在）:"
    echo "   ./start-web-ui.sh"
fi