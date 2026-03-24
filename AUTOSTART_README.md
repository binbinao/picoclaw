# picoclaw 开机自启动配置

本文档介绍如何设置和管理picoclaw的开机自启动功能。

## 脚本说明

### 1. `setup-autostart.sh` - 设置开机自启动
**功能：**
- 创建LaunchAgent配置文件
- 加载服务到macOS启动系统
- 立即启动服务
- 验证配置状态

**用法：**
```bash
./setup-autostart.sh
```

### 2. `remove-autostart.sh` - 移除开机自启动
**功能：**
- 停止并卸载LaunchAgent服务
- 删除配置文件
- 清理相关配置

**用法：**
```bash
./remove-autostart.sh
```

### 3. `autostart-status.sh` - 查看自启动状态
**功能：**
- 检查配置文件状态
- 查看服务注册状态
- 检查进程运行状态
- 验证健康状态
- 查看日志文件

**用法：**
```bash
./autostart-status.sh
```

## 快速开始

### 设置开机自启动
```bash
# 确保在picoclaw项目根目录
cd /Users/jiduobin/Documents/GitHub/picoclaw

# 添加执行权限
chmod +x setup-autostart.sh remove-autostart.sh autostart-status.sh

# 设置开机自启动
./setup-autostart.sh
```

### 验证设置
```bash
# 查看自启动状态
./autostart-status.sh

# 手动测试服务
curl http://127.0.0.1:18790/health
```

### 移除自启动
```bash
# 移除开机自启动
./remove-autostart.sh
```

## macOS LaunchAgents 工作原理

### 配置文件位置
- `~/Library/LaunchAgents/com.sipeed.picoclaw.plist` - 使用已安装的picoclaw
- `~/Library/LaunchAgents/com.sipeed.picoclaw.local.plist` - 使用项目中的picoclaw

### 服务行为
- **RunAtLoad**: 登录时自动启动
- **KeepAlive**: 崩溃后自动重启
- **WorkingDirectory**: 工作目录设置为用户目录
- **EnvironmentVariables**: 设置必要的环境变量

### 日志文件
- `/tmp/picoclaw-gateway.log` - 标准输出日志
- `/tmp/picoclaw-gateway-error.log` - 错误日志

## 管理命令

### 服务管理
```bash
# 启动服务
launchctl start com.sipeed.picoclaw

# 停止服务
launchctl stop com.sipeed.picoclaw

# 重启服务
launchctl stop com.sipeed.picoclaw && launchctl start com.sipeed.picoclaw

# 查看服务状态
launchctl list | grep picoclaw
```

### 配置管理
```bash
# 查看配置文件
plutil -p ~/Library/LaunchAgents/com.sipeed.picoclaw.plist

# 编辑配置文件
nano ~/Library/LaunchAgents/com.sipeed.picoclaw.plist

# 重新加载配置
launchctl unload ~/Library/LaunchAgents/com.sipeed.picoclaw.plist
launchctl load ~/Library/LaunchAgents/com.sipeed.picoclaw.plist
```

### 日志管理
```bash
# 查看实时日志
tail -f /tmp/picoclaw-gateway.log

# 查看错误日志
tail -f /tmp/picoclaw-gateway-error.log

# 清空日志
> /tmp/picoclaw-gateway.log
```

## 故障排除

### 服务未启动
```bash
# 检查配置文件
./autostart-status.sh

# 手动启动测试
~/.local/bin/picoclaw gateway

# 查看系统日志
log show --predicate 'subsystem contains "com.sipeed.picoclaw"' --last 10m
```

### 配置文件错误
```bash
# 验证plist格式
plutil -lint ~/Library/LaunchAgents/com.sipeed.picoclaw.plist

# 重新设置
./remove-autostart.sh
./setup-autostart.sh
```

### 权限问题
```bash
# 检查文件权限
ls -la ~/Library/LaunchAgents/com.sipeed.picoclaw.plist
ls -la ~/.local/bin/picoclaw

# 修复权限
chmod +x ~/.local/bin/picoclaw
```

### 端口冲突
```bash
# 检查端口占用
lsof -i :18790

# 查看进程
ps aux | grep picoclaw
```

## 高级配置

### 自定义环境变量
编辑plist文件中的`EnvironmentVariables`部分：
```xml
<key>EnvironmentVariables</key>
<dict>
    <key>PICOCLAW_HOME</key>
    <string>/Users/jiduobin/.picoclaw</string>
    <key>WORKSPACE_DIR</key>
    <string>/Users/jiduobin/Workspace</string>
    <key>MY_CUSTOM_VAR</key>
    <string>value</string>
</dict>
```

### 调整启动参数
修改`ProgramArguments`部分：
```xml
<key>ProgramArguments</key>
<array>
    <string>/Users/jiduobin/.local/bin/picoclaw</string>
    <string>gateway</string>
    <string>--host</string>
    <string>0.0.0.0</string>
    <string>--port</string>
    <string>8080</string>
</array>
```

### 资源限制
```xml
<key>Nice</key>
<integer>1</integer>  <!-- 优先级 -->

<key>ThrottleInterval</key>
<integer>30</integer>  <!-- 重启间隔(秒) -->

<key>ExitTimeOut</key>
<integer>300</integer>  <!-- 停止超时(秒) -->
```

## 注意事项

1. **用户级别**: LaunchAgents在用户登录时启动，不是系统启动时
2. **权限要求**: 需要用户登录后才能运行
3. **更新后**: 更新picoclaw后可能需要重启服务
4. **多用户**: 每个用户需要单独配置
5. **网络依赖**: 确保网络可用，特别是需要连接API的服务

## 与其他脚本的集成

### 与重启脚本配合使用
```bash
# 重启服务（保持自启动配置）
./quick-restart.sh

# 完整重启（包括构建）
./restart-picoclaw.sh
```

### 自动化部署
```bash
#!/bin/bash
# 自动化部署脚本示例
make build
./setup-autostart.sh
./autostart-status.sh
```

---

**创建时间**: 2026-03-07  
**最后更新**: 2026-03-07  
**适用系统**: macOS  
**相关脚本**: restart-picoclaw.sh, quick-restart.sh