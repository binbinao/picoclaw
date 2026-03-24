# picoclaw 服务管理脚本

本目录包含用于管理picoclaw服务的shell脚本，包括停止、重启等功能。

## 脚本说明

### 0. Web界面脚本 (新增)

#### `start-web-ui.sh` - Web界面启动脚本
**功能：**
- 启动picoclaw内置的Web配置管理界面
- 提供可视化JSON编辑、模型管理、渠道配置等功能
- 支持中文/英文切换、主题切换
- 内置OAuth认证管理（OpenAI、Anthropic、Google等）

**用法：**
```bash
./start-web-ui.sh
```

**特点：**
- 访问地址: http://localhost:18800
- 支持局域网访问（自动开启公网模式）
- 彩色输出，易于阅读
- 自动构建启动器（如未找到）

#### `stop-web-ui.sh` - Web界面停止脚本
**功能：**
- 停止Web界面和相关进程
- 可选择同时停止gateway服务
- 优雅停止，避免数据丢失

**用法：**
```bash
./stop-web-ui.sh
```

**特点：**
- 安全检查，避免误杀其他进程
- 交互式确认，防止意外停止gateway
- 强制停止选项（如需要）

### 1. 停止脚本

#### `stop-picoclaw.sh` - 智能停止脚本
**功能：**
- 优雅停止picoclaw服务
- 支持强制停止模式
- 支持停止所有相关进程
- 显示详细的进程信息
- 健康状态检查

**用法：**
```bash
./stop-picoclaw.sh               # 优雅停止网关服务
./stop-picoclaw.sh -f            # 强制停止网关服务
./stop-picoclaw.sh -a            # 停止所有picoclaw相关进程
./stop-picoclaw.sh -af           # 强制停止所有picoclaw相关进程
./stop-picoclaw.sh --help        # 显示帮助信息
```

**特点：**
- 彩色输出，易于阅读
- 详细的进程信息展示
- 多种停止模式
- 错误处理和状态检查

#### `kill-picoclaw.sh` - 快速强制停止脚本
**功能：**
- 快速强制停止所有picoclaw进程
- 简单直接，适合紧急情况

**用法：**
```bash
./kill-picoclaw.sh
```

**特点：**
- 执行速度快
- 强制停止所有相关进程
- 简洁的输出

### 2. 重启脚本

#### `restart-picoclaw.sh` - 完整重启脚本
**功能：**
- 停止当前运行的picoclaw服务
- 重新构建二进制文件
- 启动新的服务
- 检查服务健康状态
- 显示详细的状态信息

**用法：**
```bash
./restart-picoclaw.sh
```

**特点：**
- 彩色输出，易于阅读
- 详细的日志记录
- 健康状态检查
- 错误处理和重试机制

#### `quick-restart.sh` - 快速重启脚本
**功能：**
- 仅停止并重启服务（不重新构建）
- 快速执行，适合频繁重启

**用法：**
```bash
./quick-restart.sh
```

**特点：**
- 执行速度快
- 简洁的输出
- 基本的健康检查

## 使用示例

### 首次使用设置
```bash
# 确保在picoclaw项目根目录
cd /Users/jiduobin/Documents/GitHub/picoclaw

# 给所有脚本添加执行权限
chmod +x stop-picoclaw.sh kill-picoclaw.sh restart-picoclaw.sh quick-restart.sh start-web-ui.sh stop-web-ui.sh
```

### 停止服务
```bash
# 优雅停止（推荐）
./stop-picoclaw.sh

# 强制停止所有进程
./stop-picoclaw.sh -f

# 停止所有相关进程（包括agent等）
./stop-picoclaw.sh -a

# 快速强制停止（紧急情况）
./kill-picoclaw.sh
```

### 管理Web界面
```bash
# 启动Web界面
./start-web-ui.sh

# 停止Web界面
./stop-web-ui.sh

# 访问Web界面
# 浏览器打开: http://localhost:18800
```

### 重启服务
```bash
# 完整重启（推荐）
./restart-picoclaw.sh

# 快速重启
./quick-restart.sh
```

### 完整工作流程
```bash
# 1. 停止当前服务
./stop-picoclaw.sh

# 2. 检查是否完全停止
ps aux | grep picoclaw

# 3. 重新构建并启动
./restart-picoclaw.sh

# 4. 验证服务状态
curl -s http://127.0.0.1:18790/health
```

## 服务信息

### Gateway服务
重启后，服务将运行在：
- **网关地址**: http://127.0.0.1:18790
- **健康检查**: http://127.0.0.1:18790/health
- **就绪检查**: http://127.0.0.1:18790/ready
- **日志文件**: /tmp/picoclaw-gateway.log

### Web界面服务
启动Web界面后：
- **Web界面地址**: http://localhost:18800
- **公网访问**: http://[你的IP地址]:18800
- **配置管理**: 可视化编辑config.json
- **模型管理**: 添加/编辑/删除AI模型配置
- **渠道配置**: 配置Telegram、Discord、飞书等渠道
- **认证管理**: OAuth登录OpenAI、Anthropic、Google等
- **多语言**: 支持中文/英文切换
- **主题**: 支持浅色/深色/系统主题

## 查看服务状态

### Gateway服务状态
```bash
# 查看进程
ps aux | grep "picoclaw gateway" | grep -v grep

# 检查健康状态
curl -s http://127.0.0.1:18790/health

# 查看日志
tail -f /tmp/picoclaw-gateway.log
```

### Web界面状态
```bash
# 查看Web界面进程
ps aux | grep "picoclaw-launcher" | grep -v grep

# 检查端口占用
lsof -i :18800

# 测试Web界面响应
curl -s http://localhost:18800 | head -5
```

## 注意事项

1. **目录要求**: 脚本必须在picoclaw项目根目录执行
2. **权限要求**: 需要执行权限，首次使用请运行 `chmod +x *.sh`
3. **依赖要求**: 需要已安装Go和make工具
4. **配置文件**: 服务使用 `~/.picoclaw/config.json` 配置文件
5. **Web界面**: 首次启动会自动构建picoclaw-launcher，可能需要几分钟时间
6. **端口冲突**: Web界面使用18800端口，确保该端口未被占用
7. **网络访问**: 默认只允许本地访问，使用 `-public` 参数可允许局域网访问

## 故障排除

### Go模块下载超时
**问题现象**: 构建时出现 `dial tcp [2607:f8b0:400a:808::2011]:443: i/o timeout` 错误

**解决方案**:
```bash
# 方案1: 使用快速重启（推荐，无需重新构建）
./quick-restart.sh

# 方案2: 配置Go国内镜像源
./setup-go-mirror.sh
source ~/.zshrc  # 或 source ~/.bash_profile
./restart-picoclaw.sh

# 方案3: 手动设置环境变量（临时）
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
make build
```

**推荐的Go镜像源**:
- 七牛云: `https://goproxy.cn,direct`
- 阿里云: `https://mirrors.aliyun.com/goproxy/,direct`
- 华为云: `https://repo.huaweicloud.com/repository/goproxy/,direct`

### 脚本执行失败
```bash
# 检查脚本权限
ls -la restart-picoclaw.sh quick-restart.sh

# 添加执行权限
chmod +x restart-picoclaw.sh quick-restart.sh
```

### 服务启动失败
```bash
# 查看详细日志
tail -50 /tmp/picoclaw-gateway.log

# 手动启动测试
./build/picoclaw gateway
```

### 健康检查失败
```bash
# 检查服务是否在运行
ps aux | grep picoclaw

# 检查端口占用
lsof -i :18790

# 检查配置文件
cat ~/.picoclaw/config.json | head -20
```

## 脚本源码

两个脚本都包含详细的注释，可以根据需要进行修改。主要功能包括：
- 进程管理（停止/启动）
- 健康状态监控
- 错误处理和日志记录
- 用户友好的输出格式

---

**创建时间**: 2026-03-07  
**最后更新**: 2026-03-15  
**适用系统**: macOS/Linux  
**新增功能**: Web界面管理 (v1.0)