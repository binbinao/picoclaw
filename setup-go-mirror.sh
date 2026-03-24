#!/bin/bash

# Go模块国内镜像配置脚本
# 解决Go模块下载超时问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Go模块国内镜像配置 ===${NC}"
echo

# 备份原有的环境变量设置
echo -e "${BLUE}[INFO] 配置Go模块镜像源...${NC}"

# 创建环境变量设置脚本
cat > /tmp/setup-go-env.sh << 'EOF'
# Go模块国内镜像配置
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GOPRIVATE=""

# 可选：如果使用七牛云镜像
export GOPROXY=https://goproxy.cn,direct

# 可选：阿里云镜像
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

# 可选：华为云镜像  
export GOPROXY=https://repo.huaweicloud.com/repository/goproxy/,direct

echo "Go镜像配置已生效:"
echo "GOPROXY=$GOPROXY"
echo "GOSUMDB=$GOSUMDB"
EOF

# 添加到shell配置文件
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bash_profile"
    [ ! -f "$SHELL_RC" ] && SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    echo -e "${BLUE}[INFO] 添加到 $SHELL_RC...${NC}"
    
    # 检查是否已经配置过
    if ! grep -q "GOPROXY.*goproxy.cn" "$SHELL_RC" && ! grep -q "GOPROXY.*mirrors.aliyun.com" "$SHELL_RC" && ! grep -q "GOPROXY.*repo.huaweicloud.com" "$SHELL_RC"; then
        echo >> "$SHELL_RC"
        echo "# Go模块国内镜像配置" >> "$SHELL_RC"
        echo "export GOPROXY=https://goproxy.cn,direct" >> "$SHELL_RC"
        echo "export GOSUMDB=sum.golang.google.cn" >> "$SHELL_RC"
        echo -e "${GREEN}[SUCCESS] 已添加到 $SHELL_RC${NC}"
        echo -e "${YELLOW}[INFO] 请运行 'source $SHELL_RC' 使配置生效${NC}"
    else
        echo -e "${GREEN}[INFO] $SHELL_RC 中已存在Go镜像配置${NC}"
    fi
else
    echo -e "${YELLOW}[WARNING] 未找到shell配置文件，请手动配置环境变量${NC}"
fi

# 立即在当前shell中设置环境变量
echo -e "${BLUE}[INFO] 在当前shell中设置环境变量...${NC}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
echo -e "${GREEN}[SUCCESS] 当前shell Go镜像配置完成${NC}"
echo
echo "当前配置:"
echo "GOPROXY=$GOPROXY"
echo "GOSUMDB=$GOSUMDB"
echo

echo -e "${GREEN}=== 配置完成 ===${NC}"
echo -e "${YELLOW}现在可以重新运行构建命令了：${NC}"
echo "  ./restart-picoclaw.sh"
echo "或者"
echo "  make build"