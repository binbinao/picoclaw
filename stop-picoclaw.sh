#!/bin/bash

# stop-picoclaw.sh
# 关闭picoclaw服务的shell脚本
# 用法: ./stop-picoclaw.sh [选项]
# 选项:
#   -f, --force    强制停止（使用kill -9）
#   -a, --all      停止所有picoclaw相关进程（包括agent等）
#   -h, --help     显示帮助信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 变量初始化
FORCE_MODE=false
STOP_ALL=false
VERBOSE=false

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

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}=== picoclaw服务停止脚本 ===${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -f, --force     强制停止（使用kill -9）"
    echo "  -a, --all       停止所有picoclaw相关进程（包括agent、gateway等）"
    echo "  -v, --verbose   显示详细调试信息"
    echo "  -h, --help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              优雅停止picoclaw网关服务"
    echo "  $0 -f           强制停止picoclaw网关服务"
    echo "  $0 -a           停止所有picoclaw相关进程"
    echo "  $0 -af          强制停止所有picoclaw相关进程"
    echo ""
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_MODE=true
                shift
                ;;
            -a|--all)
                STOP_ALL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 获取picoclaw进程
get_picoclaw_processes() {
    if [ "$STOP_ALL" = true ]; then
        # 获取所有picoclaw相关进程
        ps aux | grep -E "(picoclaw|claw)" | grep -v grep | grep -v "$0"
    else
        # 只获取网关进程
        ps aux | grep "picoclaw gateway" | grep -v grep
    fi
}

# 获取进程详细信息
get_process_info() {
    local pid=$1
    local cmdline=$(ps -p $pid -o command= 2>/dev/null || echo "未知")
    local runtime=$(ps -p $pid -o etime= 2>/dev/null || echo "未知")
    local memory=$(ps -p $pid -o rss= 2>/dev/null || echo "未知")
    
    echo "  PID: $pid"
    echo "  命令: $cmdline"
    echo "  运行时间: $runtime"
    echo "  内存占用: ${memory}KB"
}

# 停止单个进程
stop_process() {
    local pid=$1
    local process_info=$(get_process_info $pid)
    
    log_info "停止进程:"
    echo "$process_info"
    
    if [ "$FORCE_MODE" = true ]; then
        log_warning "使用强制模式 (kill -9)"
        kill -9 $pid 2>/dev/null
    else
        log_info "尝试优雅停止 (kill)"
        kill $pid 2>/dev/null
        
        # 等待进程结束
        local timeout=10
        local elapsed=0
        
        while [ $elapsed -lt $timeout ]; do
            if ! ps -p $pid > /dev/null 2>&1; then
                log_success "进程已停止"
                return 0
            fi
            sleep 1
            elapsed=$((elapsed + 1))
            log_debug "等待进程停止... ($elapsed/$timeout 秒)"
        done
        
        # 如果优雅停止失败，强制停止
        log_warning "优雅停止失败，尝试强制停止..."
        kill -9 $pid 2>/dev/null
        sleep 1
    fi
    
    # 验证进程是否已停止
    if ! ps -p $pid > /dev/null 2>&1; then
        log_success "进程已成功停止"
        return 0
    else
        log_error "无法停止进程 (PID: $pid)"
        return 1
    fi
}

# 检查服务健康状态
check_health() {
    log_info "检查服务健康状态..."
    
    if curl -s http://127.0.0.1:18790/health > /dev/null 2>&1; then
        local response=$(curl -s http://127.0.0.1:18790/health)
        local status=$(echo $response | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$status" = "ok" ]; then
            local uptime=$(echo $response | grep -o '"uptime":"[^"]*"' | cut -d'"' -f4)
            log_warning "服务仍在运行 (uptime: $uptime)"
            return 0
        fi
    fi
    
    log_info "服务已停止或无法访问"
    return 1
}

# 显示当前进程状态
show_status() {
    echo -e "\n${CYAN}=== 当前picoclaw进程状态 ===${NC}"
    
    local processes=$(get_picoclaw_processes)
    
    if [ -n "$processes" ]; then
        echo -e "${YELLOW}找到以下运行中的进程:${NC}"
        echo ""
        
        # 按PID分组显示
        echo "$processes" | while read line; do
            local pid=$(echo $line | awk '{print $2}')
            get_process_info $pid
            echo ""
        done
        
        echo -e "总计: $(echo "$processes" | wc -l) 个进程"
    else
        echo -e "${GREEN}没有找到运行中的picoclaw进程${NC}"
    fi
    
    echo -e "${CYAN}================================${NC}\n"
}

# 主函数
main() {
    echo -e "${CYAN}=== 停止picoclaw服务 ===${NC}"
    
    # 解析参数
    parse_args "$@"
    
    # 显示当前状态
    show_status
    
    # 获取进程列表
    local processes=$(get_picoclaw_processes)
    
    if [ -z "$processes" ]; then
        log_success "没有需要停止的进程"
        exit 0
    fi
    
    # 统计进程数量
    local process_count=$(echo "$processes" | wc -l)
    log_info "准备停止 $process_count 个进程"
    
    # 停止每个进程
    local success_count=0
    local fail_count=0
    
    echo "$processes" | while read line; do
        local pid=$(echo $line | awk '{print $2}')
        
        if stop_process $pid; then
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
        
        echo ""
    done
    
    # 等待所有进程停止
    sleep 2
    
    # 最终状态检查
    echo -e "\n${CYAN}=== 停止结果汇总 ===${NC}"
    echo -e "${GREEN}成功停止: $success_count 个进程${NC}"
    
    if [ $fail_count -gt 0 ]; then
        echo -e "${RED}停止失败: $fail_count 个进程${NC}"
    fi
    
    # 检查是否还有进程在运行
    local remaining=$(get_picoclaw_processes)
    if [ -n "$remaining" ]; then
        log_warning "仍有进程在运行:"
        echo "$remaining"
        echo ""
        log_info "建议使用强制模式: ./stop-picoclaw.sh -f"
    else
        log_success "所有picoclaw进程已停止"
    fi
    
    # 健康检查
    if check_health; then
        log_warning "服务健康检查仍可通过，可能仍有进程在运行"
    else
        log_success "服务已完全停止"
    fi
    
    echo -e "\n${GREEN}停止操作完成！${NC}"
}

# 运行主函数
main "$@"