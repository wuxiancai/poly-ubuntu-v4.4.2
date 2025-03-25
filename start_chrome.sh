#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查系统
if [[ "$(lsb_release -si)" != "Ubuntu" ]]; then
    echo -e "${RED}错误: 此脚本只能在 Ubuntu 系统上运行${NC}"
    exit 1
fi

# 版本检查函数
check_drivers() {
    # 获取Chromium完整版本号（示例输出：Chromium 123.0.6312.45）
    CHROME_FULL_VERSION=$(chromium --version | awk '{print $2}')
    CHROME_MAJOR_VERSION=$(echo "$CHROME_FULL_VERSION" | cut -d'.' -f1)
    echo -e "${YELLOW}检测到Chromium版本: ${CHROME_FULL_VERSION}${NC}"

    # 检查chromedriver安装状态
    check_driver() {
        # Ubuntu系统默认安装路径
        PATHS=("/usr/bin/chromedriver")
        for path in "${PATHS[@]}"; do
            if [ -f "$path" ]; then
                DRIVER_PATH="$path"
                break
            fi
        done

        if [ -z "$DRIVER_PATH" ]; then
            echo -e "${RED}未找到chromedriver，请先运行install.sh安装${NC}"
            return 1
        fi
        
        DRIVER_VERSION=$($DRIVER_PATH --version | awk '{print $2}')
        DRIVER_MAJOR_VERSION=$(echo "$DRIVER_VERSION" | cut -d'.' -f1)
        echo -e "${YELLOW}当前chromedriver版本: ${DRIVER_VERSION}${NC}"
        
        # 版本比较逻辑
        if [ "$DRIVER_MAJOR_VERSION" -lt "$CHROME_MAJOR_VERSION" ]; then
            echo -e "${RED}驱动版本过低，请运行install.sh更新！${NC}"
            return 1
        fi
        echo -e "${GREEN}驱动版本兼容！${NC}"
        return 0
    }

    # 执行版本检查
    if ! check_driver; then
        echo -e "${RED}驱动不兼容，请执行以下命令：\n./install.sh${NC}"
        exit 1
    fi
}

# 主执行流程
echo -e "${YELLOW}开始执行浏览器启动流程...${NC}"

# 先执行驱动检查
check_drivers

# 启动Chromium
echo -e "${YELLOW}正在启动Chromium...${NC}"
# 确保目录存在并设置正确权限
CHROME_DEBUG_DIR="$HOME/chromium-debug"
mkdir -p "$CHROME_DEBUG_DIR"
chmod 755 "$CHROME_DEBUG_DIR"

# 确保没有其他Chromium实例在运行
pkill -f chromium || true
sleep 2
chromium \
    --remote-debugging-port=9222 \
    --user-data-dir="CHROME_DEBUG_DIR" \
    --disable-gpu \
    --disable-dev-shm-usage \
    https://polymarket.com/markets/crypto &

echo -e "${GREEN}Chromium已成功启动！${NC}"