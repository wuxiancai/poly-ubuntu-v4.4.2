#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Polymarket 自动交易系统安装脚本 ===${NC}"

# 检查系统
if [[ "$(lsb_release -si)" != "Ubuntu" ]]; then
    echo -e "${RED}错误: 此脚本只能在 Ubuntu 系统上运行${NC}"
    exit 1
fi

# 安装系统依赖
echo -e "${GREEN}安装系统依赖...${NC}"
sudo apt-get update
sudo apt-get install -y --fix-missing \
    libnss3 \
    libxss1 \
    libgbm1 \
    fonts-liberation \
    x11-xserver-utils \
    dbus-x11 \
    gcc \
    python3-dev \
    python3-pip \
    python3-tk \
    python3-venv \
    libx11-dev \
    libxtst-dev \
    libxt-dev \
    libxinerama-dev \
    libxcursor-dev \
    xvfb \
    unzip \
    wget \
    xauth \
    x11-apps \
    x11-utils \
    python3-xlib \
    scrot \
    jq

set -e  # 发生错误时退出
ARCH=$(dpkg --print-architecture)

# 适配 ARM64 和 AMD64
if [[ "$ARCH" == "arm64" ]]; then
    echo "✅ 检测到 ARM64 架构，开始安装 Chromium 和 ChromeDriver..."
    sudo apt install -y chromium-browser chromium-chromedriver
elif [[ "$ARCH" == "amd64" ]]; then
    echo "✅ 检测到 AMD64 架构，开始安装 Google Chrome 和 ChromeDriver..."
    
    # 下载 Google Chrome
    wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get -f install -y

    # 获取Chrome版本并提取主版本号
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f 1)
    echo "检测到Chrome主版本号: $CHROME_VERSION"
    
    CHROMEDRIVER_VERSION=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" | jq -r '.versions[] | select(.version == "134.0.6944.0") | .downloads.chromedriver[] | select(.platform == "linux64") | .url')
    echo "找到 ChromeDriver 版本: $CHROMEDRIVER_VERSION"
    # 下载 ChromeDriver
    wget "$CHROMEDRIVER_VERSION"
    echo "✅ 下载完成！"
    # 解压并安装
    unzip chromedriver-linux64.zip
    sudo mv chromedriver-linux*/chromedriver /usr/local/bin/
    sudo chmod +x /usr/local/bin/chromedriver
    rm -rf chromedriver-linux* chromedriver-linux64.zip

    # 验证安装
    echo "✅ 安装完成！"
    chromedriver --version
else
    echo "❌ 不支持的架构: $ARCH"
    exit 1
fi

# 验证安装
echo "🎯 验证安装..."
if [[ "$ARCH" == "arm64" ]]; then
    chromium --version
    chromedriver --version
else
    google-chrome --version
    chromedriver --version
fi

# 创建 Python 虚拟环境
echo -e "${GREEN}创建 Python 虚拟环境...${NC}"
# 判断 python3 版本,根据版本安装 PYTON3.*-venv
python_version=$(python3 --version)
if [[ "$python_version" == "Python 3.10"* ]]; then
    sudo apt install python3.10-venv -y
else
    sudo apt install python3.12-venv -y
fi
sudo rm -rf .venv
python3 -m venv .venv

# 激活虚拟环境并安装依赖
source .venv/bin/activate

echo -e "${GREEN}安装 Python 依赖...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt-get install python3-tk python3-dev -y
pip3 install selenium --break-system-packages
pip3 install screeninfo --break-system-packages
pip3 install pyautogui --break-system-packages
# 验证安装
echo -e "${GREEN}验证Python依赖安装...${NC}"
python3 -c "import selenium; print('Selenium版本:', selenium.__version__)"
python3 -c "import pyautogui; print('PyAutoGUI版本:', pyautogui.__version__)"

# 创建运行脚本
echo -e "${GREEN}创建运行脚本...${NC}"
cat > run_trade.sh << 'EOL'
#!/bin/bash
# 激活虚拟环境
source .venv/bin/activate
python3 crypto_trader.py
EOL

# 检查是否有实际显示器
if xdpyinfo >/dev/null 2>&1; then
  echo "检测到实际显示器，使用实际显示"
  # 使用实际显示器
  python3 crypto_trader.py
else
  echo "未检测到实际显示器，使用虚拟显示"
  # 设置虚拟显示
  export DISPLAY=:99
  Xvfb :99 -screen 0 1280x1024x24 &
  XVFB_PID=$!
  sleep 2  # 等待Xvfb启动
  
  # 运行交易程序
  python3 crypto_trader.py
  
  # 清理
  kill $XVFB_PID
fi
EOL

# 创建日志目录
mkdir -p logs

# 设置执行权限
chmod +x run_trade.sh
chmod +x crypto_trader.py

echo -e "${GREEN}安装完成！请执行以下命令启动：${NC}"
echo -e "./run_trade.sh"