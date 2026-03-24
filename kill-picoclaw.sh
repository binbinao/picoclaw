#!/bin/bash

# kill-picoclaw.sh
# 快速强制停止所有picoclaw进程
# 用法: ./kill-picoclaw.sh

set -e

echo "=== 快速停止所有picoclaw进程 ==="

# 查找所有picoclaw相关进程
PIDS=$(ps aux | grep -E "(picoclaw|claw)" | grep -v grep | grep -v "$0" | awk '{print $2}')

if [ -z "$PIDS" ]; then
    echo "✓ 没有找到运行中的picoclaw进程"
    exit 0
fi

echo "找到以下进程:"
ps aux | grep -E "(picoclaw|claw)" | grep -v grep | grep -v "$0"

echo ""
echo "正在停止进程: $PIDS"

# 强制停止所有进程
kill -9 $PIDS 2>/dev/null

# 等待进程停止
sleep 2

# 检查是否还有进程在运行
REMAINING=$(ps aux | grep -E "(picoclaw|claw)" | grep -v grep | grep -v "$0" | awk '{print $2}')

if [ -z "$REMAINING" ]; then
    echo "✓ 所有picoclaw进程已停止"
else
    echo "⚠ 仍有进程在运行: $REMAINING"
    echo "尝试再次停止..."
    kill -9 $REMAINING 2>/dev/null
    sleep 1
fi

# 最终检查
FINAL_CHECK=$(ps aux | grep -E "(picoclaw|claw)" | grep -v grep | grep -v "$0")

if [ -z "$FINAL_CHECK" ]; then
    echo "✅ 所有picoclaw进程已成功停止"
else
    echo "❌ 无法停止以下进程:"
    echo "$FINAL_CHECK"
    echo ""
    echo "可能需要手动检查:"
    echo "  lsof -i :18790"
    echo "  sudo kill -9 [PID]"
fi

echo ""
echo "=== 完成 ==="