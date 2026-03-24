#!/bin/bash

# setup-autostart.sh
# 设置picoclaw开机自启动
# 用法: ./setup-autostart.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 设置picoclaw开机自启动 ===${NC}"

# 检查是否在正确目录
if [ ! -f "go.mod" ] || [ ! -f "Makefile" ]; then
    echo -e "${RED}错误: 当前目录不是picoclaw项目根目录${NC}"
    echo "请切换到 /Users/jiduobin/Documents/GitHub/picoclaw 目录"
    exit 1
fi

# 检查LaunchAgents目录是否存在
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
if [ ! -d "$LAUNCH_AGENTS_DIR" ]; then
    echo "创建LaunchAgents目录..."
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

# 检查picoclaw是否已安装
if [ -f "$HOME/.local/bin/picoclaw" ]; then
    PICOCLAW_PATH="$HOME/.local/bin/picoclaw"
    PLIST_FILE="$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.plist"
    echo -e "${GREEN}使用已安装的picoclaw: $PICOCLAW_PATH${NC}"
else
    PICOCLAW_PATH="$PWD/build/picoclaw"
    PLIST_FILE="$LAUNCH_AGENTS_DIR/com.sipeed.picoclaw.local.plist"
    echo -e "${YELLOW}使用项目中的picoclaw: $PICOCLAW_PATH${NC}"
    
    # 确保二进制文件存在
    if [ ! -f "$PICOCLAW_PATH" ]; then
        echo "构建picoclaw二进制文件..."
        make build
    fi
fi

# 创建plist文件
echo "创建LaunchAgent配置文件..."
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.sipeed.picoclaw</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$PICOCLAW_PATH</string>
        <string>gateway</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/tmp/picoclaw-gateway.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/picoclaw-gateway-error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/jiduobin/.local/bin</string>
        <key>HOME</key>
        <string>/Users/jiduobin</string>
        <key>PICOCLAW_HOME</key>
        <string>/Users/jiduobin/.picoclaw</string>
        <key>WORKSPACE_DIR</key>
        <string>/Users/jiduobin/Workspace</string>
    </dict>
    
    <key>WorkingDirectory</key>
    <string>/Users/jiduobin</string>
</dict>
</plist>
EOF

echo -e "${GREEN}配置文件已创建: $PLIST_FILE${NC}"

# 加载LaunchAgent
echo "加载LaunchAgent..."
if launchctl list | grep -q "com.sipeed.picoclaw"; then
    echo "停止现有服务..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
fi

# 加载新的配置
if launchctl load "$PLIST_FILE"; then
    echo -e "${GREEN}LaunchAgent加载成功${NC}"
else
    echo -e "${RED}LaunchAgent加载失败${NC}"
    echo "请检查配置文件: $PLIST_FILE"
    exit 1
fi

# 立即启动服务
echo "立即启动服务..."
launchctl start com.sipeed.picoclaw

# 检查服务状态
echo "检查服务状态..."
sleep 2

if launchctl list | grep -q "com.sipeed.picoclaw"; then
    echo -e "${GREEN}服务已成功注册到LaunchAgents${NC}"
else
    echo -e "${YELLOW}服务注册状态异常${NC}"
fi

# 检查进程
if ps aux | grep "picoclaw gateway" | grep -v grep > /dev/null; then
    echo -e "${GREEN}picoclaw服务正在运行${NC}"
else
    echo -e "${YELLOW}picoclaw服务未运行，将在下次登录时自动启动${NC}"
fi

# 显示配置摘要
echo -e "\n${BLUE}=== 配置摘要 ===${NC}"
echo "配置文件: $PLIST_FILE"
echo "服务名称: com.sipeed.picoclaw"
echo "启动命令: $PICOCLAW_PATH gateway"
echo "日志文件: /tmp/picoclaw-gateway.log"
echo "错误日志: /tmp/picoclaw-gateway-error.log"
echo "工作目录: /Users/jiduobin"
echo -e "${BLUE}================${NC}"

# 显示管理命令
echo -e "\n${BLUE}=== 管理命令 ===${NC}"
echo "启动服务: launchctl start com.sipeed.picoclaw"
echo "停止服务: launchctl stop com.sipeed.picoclaw"
echo "查看状态: launchctl list | grep picoclaw"
echo "查看日志: tail -f /tmp/picoclaw-gateway.log"
echo "卸载服务: launchctl unload $PLIST_FILE"
echo -e "${BLUE}================${NC}"

echo -e "\n${GREEN}开机自启动设置完成！${NC}"
echo "picoclaw将在下次系统启动时自动运行。"