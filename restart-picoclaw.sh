#!/bin/bash

# restart-picoclaw.sh
# 重启picoclaw服务的shell脚本
# 用法: ./restart-picoclaw.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否在picoclaw项目目录
check_project_dir() {
    if [ ! -f "go.mod" ] || [ ! -f "Makefile" ]; then
        log_error "当前目录不是picoclaw项目根目录"
        log_error "请切换到 /Users/jiduobin/Documents/GitHub/picoclaw 目录"
        exit 1
    fi
}

# 获取当前运行的picoclaw进程
get_picoclaw_pid() {
    ps aux | grep "picoclaw gateway" | grep -v grep | awk '{print $2}'
}

# 检查服务健康状态
check_health() {
    local timeout=10
    local interval=1
    local elapsed=0
    
    log_info "检查服务健康状态..."
    
    while [ $elapsed -lt $timeout ]; do
        if curl -s http://127.0.0.1:18790/health > /dev/null 2>&1; then
            local response=$(curl -s http://127.0.0.1:18790/health)
            local status=$(echo $response | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            
            if [ "$status" = "ok" ]; then
                local uptime=$(echo $response | grep -o '"uptime":"[^"]*"' | cut -d'"' -f4)
                log_success "服务健康检查通过 (uptime: $uptime)"
                return 0
            fi
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        log_info "等待服务启动... ($elapsed/$timeout 秒)"
    done
    
    log_error "服务健康检查超时"
    return 1
}

# 停止当前服务
stop_service() {
    local pid=$(get_picoclaw_pid)
    
    if [ -n "$pid" ]; then
        log_info "停止当前picoclaw服务 (PID: $pid)"
        
        # 尝试优雅停止
        kill $pid 2>/dev/null
        
        # 等待进程结束
        local timeout=5
        local elapsed=0
        
        while [ $elapsed -lt $timeout ]; do
            if ! ps -p $pid > /dev/null 2>&1; then
                log_success "服务已停止"
                return 0
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        # 如果优雅停止失败，强制停止
        log_warning "优雅停止失败，尝试强制停止..."
        kill -9 $pid 2>/dev/null
        sleep 1
        
        if ! ps -p $pid > /dev/null 2>&1; then
            log_success "服务已强制停止"
        else
            log_error "无法停止服务 (PID: $pid)"
            return 1
        fi
    else
        log_info "没有找到运行的picoclaw服务"
    fi
    
    return 0
}

# 重新构建
rebuild() {
    log_info "重新构建picoclaw二进制文件..."
    
    if make build; then
        log_success "构建成功"
    else
        log_error "构建失败"
        exit 1
    fi
}

# 启动服务
start_service() {
    log_info "启动picoclaw网关服务..."
    
    # 检查是否已存在服务
    local existing_pid=$(get_picoclaw_pid)
    if [ -n "$existing_pid" ]; then
        log_warning "发现已有服务在运行 (PID: $existing_pid)，将先停止"
        stop_service
    fi
    
    # 启动新服务
    nohup ./build/picoclaw gateway > /tmp/picoclaw-gateway.log 2>&1 &
    
    local new_pid=$!
    log_info "服务已启动 (PID: $new_pid)"
    log_info "日志文件: /tmp/picoclaw-gateway.log"
    
    # 等待服务启动
    sleep 2
    
    # 验证服务启动
    if ps -p $new_pid > /dev/null 2>&1; then
        log_success "服务进程运行正常"
    else
        log_error "服务进程启动失败"
        log_info "查看日志: tail -f /tmp/picoclaw-gateway.log"
        return 1
    fi
    
    return 0
}

# 显示服务状态
show_status() {
    echo -e "\n${BLUE}=== picoclaw服务状态 ===${NC}"
    
    local pid=$(get_picoclaw_pid)
    if [ -n "$pid" ]; then
        echo -e "进程ID: $pid"
        echo -e "运行时间: $(ps -p $pid -o etime= 2>/dev/null || echo "未知")"
        
        # 检查健康状态
        if check_health; then
            echo -e "健康状态: ${GREEN}正常${NC}"
        else
            echo -e "健康状态: ${RED}异常${NC}"
        fi
        
        echo -e "网关地址: http://127.0.0.1:18790"
        echo -e "健康检查: http://127.0.0.1:18790/health"
    else
        echo -e "状态: ${RED}未运行${NC}"
    fi
    
    echo -e "${BLUE}=======================${NC}\n"
}

# 主函数
main() {
    echo -e "${BLUE}=== 重启picoclaw服务 ===${NC}"
    
    # 检查项目目录
    check_project_dir
    
    # 显示当前状态
    show_status
    
    # 停止服务
    if ! stop_service; then
        log_error "停止服务失败"
        exit 1
    fi
    
    # 重新构建
    rebuild
    
    # 启动服务
    if ! start_service; then
        log_error "启动服务失败"
        exit 1
    fi
    
    # 检查健康状态
    if check_health; then
        log_success "picoclaw服务重启完成"
    else
        log_warning "服务已启动但健康检查失败"
        log_info "请检查日志: tail -f /tmp/picoclaw-gateway.log"
    fi
    
    # 显示最终状态
    show_status
    
    echo -e "${GREEN}重启完成！${NC}"
}

# 运行主函数
main "$@"