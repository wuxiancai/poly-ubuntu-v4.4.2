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
# 创建本地浏览器目录
mkdir -p chrome driver

# 下载并解压Chromium
echo -e "${GREEN}下载最新版Chromium...${NC}"
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -x google-chrome-stable_current_amd64.deb chrome
rm google-chrome-stable_current_amd64.deb

# 获取本地Chromium版本
CHROME_PATH="./chrome/opt/google/chrome
CHROME_VERSION=$($CHROME_PATH --version | grep -oP 'Google Chrome \K\d+\.\d+\.\d+\.\d+')

# 下载匹配的驱动
echo -e "${GREEN}下载匹配的Chromedriver (v${CHROME_VERSION})...${NC}"
DRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
wget -q "https://storage.googleapis.com/chrome-for-testing-public/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip"
unzip -q chromedriver_linux64.zip -d driver
rm chromedriver_linux64.zip
chmod +x driver/chromedriver

# 安装系统依赖（修正依赖列表格式）
echo -e "${GREEN}安装系统依赖...${NC}"
sudo apt-get install -y \
    libnss3 \
    libxss1 \
    libgbm1 \
    libasound2 \
    fonts-liberation \
    x11-xserver-utils \
    dbus-x11 \
    gcc \
    python3-tk \
    libx11-dev \
    libxtst-dev \
    libxt-dev \
    libxinerama-dev \
    libxcursor-dev \
    xvfb \
    unzip \
    wget \
    python3-pip \
    libappindicator3-1  # 新增必要依赖

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