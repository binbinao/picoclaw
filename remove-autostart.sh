#!/bin/bash

# remove-autostart.sh
# 移除picoclaw的开机自启动
# 用法: ./remove-autostart.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 移除picoclaw开机自启动 ===${NC}"

# LaunchAgents目录
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# 要移除的plist文件列表
PLIST_FILES=(
    "$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.plist"
    "$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.local.plist"
)

# 停止并卸载所有相关的LaunchAgents
for PLIST_FILE in "${PLIST_FILES[@]}"; do
    if [ -f "$PLIST_FILE" ]; then
        echo "处理配置文件: $(basename "$PLIST_FILE")"
        
        # 获取服务标签
        SERVICE_LABEL=$(basename "$PLIST_FILE" .plist)
        
        # 停止服务
        if launchctl list | grep -q "$SERVICE_LABEL"; then
            echo "停止服务: $SERVICE_LABEL"
            launchctl stop "$SERVICE_LABEL" 2>/dev/null || true
            
            echo "卸载服务: $SERVICE_LABEL"
            launchctl unload "$PLIST_FILE" 2>/dev/null || true
        fi
        
        # 删除配置文件
        echo "删除配置文件: $PLIST_FILE"
        rm -f "$PLIST_FILE"
        
        echo -e "${GREEN}已移除: $(basename "$PLIST_FILE")${NC}"
    fi
done

# 检查是否还有其他picoclaw相关的LaunchAgents
REMAINING=$(find "$LAUNCH_AGENTS_DIR" -name "*picoclaw*" -type f 2>/dev/null || true)
if [ -n "$REMAINING" ]; then
    echo -e "${YELLOW}发现其他picoclaw相关的配置文件:${NC}"
    echo "$REMAINING"
    echo "如需移除，请手动删除。"
fi

# 检查进程是否还在运行
if ps aux | grep "picoclaw gateway" | grep -v grep > /dev/null; then
    echo -e "${YELLOW}注意: picoclaw进程仍在运行${NC}"
    echo "如需停止，请运行:"
    echo "  pkill -f 'picoclaw gateway'"
fi

echo -e "\n${BLUE}=== 清理完成 ===${NC}"
echo "开机自启动已移除。"
echo "注意: 这不会删除picoclaw程序本身，只会移除开机自启动配置。"
echo -e "${GREEN}操作完成！${NC}"