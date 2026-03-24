#!/bin/bash

# autostart-status.sh
# 查看picoclaw开机自启动状态
# 用法: ./autostart-status.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== picoclaw开机自启动状态 ===${NC}"

# LaunchAgents目录
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# 检查配置文件
echo -e "\n${BLUE}[配置文件检查]${NC}"
PLIST_FILES=(
    "$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.plist"
    "$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.local.plist"
)

CONFIG_FOUND=false
for PLIST_FILE in "${PLIST_FILES[@]}"; do
    if [ -f "$PLIST_FILE" ]; then
        CONFIG_FOUND=true
        echo -e "${GREEN}✓ 找到配置文件: $(basename "$PLIST_FILE")${NC}"
        
        # 显示配置文件信息
        SERVICE_LABEL=$(basename "$PLIST_FILE" .plist)
        echo "  服务标签: $SERVICE_LABEL"
        
        # 提取程序路径
        PROGRAM_PATH=$(plutil -extract "ProgramArguments.0" raw "$PLIST_FILE" 2>/dev/null || echo "未知")
        echo "  程序路径: $PROGRAM_PATH"
        
        # 检查文件是否存在
        if [ -f "$PROGRAM_PATH" ]; then
            echo -e "  程序状态: ${GREEN}存在${NC}"
        else
            echo -e "  程序状态: ${RED}不存在${NC}"
        fi
    fi
done

if [ "$CONFIG_FOUND" = false ]; then
    echo -e "${YELLOW}⚠ 未找到picoclaw开机自启动配置文件${NC}"
fi

# 检查其他picoclaw相关的配置文件
OTHER_FILES=$(find "$LAUNCH_AGENTS_DIR" -name "*picoclaw*" -type f 2>/dev/null || true)
if [ -n "$OTHER_FILES" ] && [ "$CONFIG_FOUND" = true ]; then
    echo -e "\n${YELLOW}[其他相关配置文件]${NC}"
    echo "$OTHER_FILES" | while read -r file; do
        if [[ ! " ${PLIST_FILES[@]} " =~ " ${file} " ]]; then
            echo "  - $(basename "$file")"
        fi
    done
fi

# 检查LaunchAgents服务状态
echo -e "\n${BLUE}[LaunchAgents服务状态]${NC}"
SERVICES=("com.sipeed.picoclaw" "com.sipeed.picoclaw.local")
SERVICE_FOUND=false

for SERVICE in "${SERVICES[@]}"; do
    if launchctl list | grep -q "$SERVICE"; then
        SERVICE_FOUND=true
        echo -e "${GREEN}✓ 服务已注册: $SERVICE${NC}"
        
        # 获取更详细的状态
        STATUS=$(launchctl list "$SERVICE" 2>/dev/null | head -5 || echo "状态获取失败")
        echo "  状态信息:"
        echo "$STATUS" | sed 's/^/    /'
    fi
done

if [ "$SERVICE_FOUND" = false ]; then
    echo -e "${YELLOW}⚠ 未找到已注册的picoclaw服务${NC}"
fi

# 检查进程状态
echo -e "\n${BLUE}[进程状态]${NC}"
PROCESS_INFO=$(ps aux | grep "picoclaw gateway" | grep -v grep || true)

if [ -n "$PROCESS_INFO" ]; then
    echo -e "${GREEN}✓ picoclaw进程正在运行${NC}"
    echo "$PROCESS_INFO" | while read -r line; do
        PID=$(echo "$line" | awk '{print $2}')
        TIME=$(echo "$line" | awk '{print $10}')
        CMD=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
        echo "  PID: $PID, 运行时间: $TIME"
        echo "  命令: $CMD"
    done
else
    echo -e "${YELLOW}⚠ 未找到运行的picoclaw进程${NC}"
fi

# 检查健康状态
echo -e "\n${BLUE}[健康状态检查]${NC}"
if curl -s http://127.0.0.1:18790/health > /dev/null 2>&1; then
    RESPONSE=$(curl -s http://127.0.0.1:18790/health)
    STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "未知")
    UPTIME=$(echo "$RESPONSE" | grep -o '"uptime":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "未知")
    
    if [ "$STATUS" = "ok" ]; then
        echo -e "${GREEN}✓ 服务健康检查通过${NC}"
        echo "  状态: $STATUS"
        echo "  运行时间: $UPTIME"
    else
        echo -e "${YELLOW}⚠ 服务健康状态异常${NC}"
        echo "  状态: $STATUS"
    fi
else
    echo -e "${RED}✗ 无法连接到服务${NC}"
    echo "  网关地址: http://127.0.0.1:18790/health"
fi

# 检查日志文件
echo -e "\n${BLUE}[日志文件]${NC}"
LOG_FILES=(
    "/tmp/picoclaw-gateway.log"
    "/tmp/picoclaw-gateway-error.log"
    "/tmp/picoclaw-agent.log"
)

for LOG_FILE in "${LOG_FILES[@]}"; do
    if [ -f "$LOG_FILE" ]; then
        SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
        MOD_TIME=$(stat -f "%Sm" "$LOG_FILE" 2>/dev/null || date -r "$LOG_FILE" '+%Y-%m-%d %H:%M:%S')
        echo -e "${GREEN}✓ 日志文件: $(basename "$LOG_FILE")${NC}"
        echo "  大小: $SIZE, 修改时间: $MOD_TIME"
        
        # 显示最后3行日志
        if [ "$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)" -gt 0 ]; then
            echo "  最后日志:"
            tail -3 "$LOG_FILE" | sed 's/^/    /'
        fi
    else
        echo -e "${YELLOW}⚠ 日志文件不存在: $(basename "$LOG_FILE")${NC}"
    fi
done

# 显示管理命令
echo -e "\n${BLUE}[管理命令]${NC}"
echo "设置自启动: ./setup-autostart.sh"
echo "移除自启动: ./remove-autostart.sh"
echo "重启服务: ./restart-picoclaw.sh 或 ./quick-restart.sh"
echo "启动服务: launchctl start com.sipeed.picoclaw"
echo "停止服务: launchctl stop com.sipeed.picoclaw"
echo "查看日志: tail -f /tmp/picoclaw-gateway.log"
echo -e "${BLUE}======================${NC}"

echo -e "\n${GREEN}状态检查完成！${NC}"