#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== Ubuntu 自动安装脚本 ===${NC}"

# 检查系统
if [[ "$(lsb_release -si)" != "Ubuntu" ]]; then
    echo -e "${RED}错误: 此脚本只能在 Ubuntu 系统上运行${NC}"
    exit 1
fi

# 创建虚拟环境目录
VENV_DIR=".venv"
REQUIREMENTS="requirements.txt"

# 安装系统依赖
echo -e "${GREEN}安装系统依赖...${NC}"
sudo apt-get update && sudo apt-get install -y \
    gcc \
    python3-dev \
    python3-venv \
    libx11-dev \
    libxtst-dev \
    libxt-dev \
    libxinerama-dev \
    libxcursor-dev \
    chromium-browser \  # 修改为Ubuntu 24 LTS的Chromium包名
    xvfb \
    unzip \
    wget \
    python3-pip \
    chromium-chromedriver  # 添加chromium专用驱动

# 获取已安装Chromium版本
CHROMIUM_VERSION=$(chromium-browser --version | grep -oP 'Chromium \K\d+\.\d+\.\d+\.\d+')
if [ -z "$CHROMIUM_VERSION" ]; then
    echo -e "${RED}错误: 无法获取Chromium版本${NC}"
    exit 1
fi

# 安装匹配的Chromedriver
echo -e "${GREEN}配置 Chromium Driver (v$CHROMIUM_VERSION)...${NC}"
CHROME_DRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROMIUM_VERSION")
if [ -z "$CHROME_DRIVER_VERSION" ]; then
    echo -e "${YELLOW}警告: 无法获取匹配驱动版本，使用最新版${NC}"
    CHROME_DRIVER_VERSION=$(curl -s https://chromedriver.storage.googleapis.com/LATEST_RELEASE)
fi

wget -q "https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip"
unzip -q chromedriver_linux64.zip
sudo mv chromedriver /usr/bin/
sudo chmod +x /usr/bin/chromedriver
rm chromedriver_linux64.zip

# 创建虚拟环境
echo -e "${GREEN}创建Python虚拟环境...${NC}"
python3 -m venv $VENV_DIR

# 安装Python依赖
echo -e "${GREEN}安装Python依赖...${NC}"
source $VENV_DIR/bin/activate
pip install --upgrade pip
pip install -r $REQUIREMENTS

# 创建运行脚本
echo -e "${GREEN}创建运行脚本...${NC}"
cat > run_trade.sh << 'EOL'
#!/bin/bash
source .venv/bin/activate
python crypto_trader.py
EOL

# 设置执行权限
chmod +x run_trade.sh

echo -e "${GREEN}安装完成！请执行以下命令启动：${NC}"
echo -e "./run_trade.sh"