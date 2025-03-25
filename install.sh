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
    xdpyinfo \
    python3-xlib \
    scrot

set -e  # 发生错误时退出
ARCH=$(dpkg --print-architecture)

# 检查是否为 ARM64 架构
if [[ "$ARCH" != "arm64" ]]; then
    echo "错误: 该脚本仅支持 ARM64 架构 (你的架构: $ARCH)"
    exit 1
fi

echo "✅ 检测到 ARM64 架构，开始安装 Chromium 和 ChromeDriver..."

# 2️⃣ 安装 ARM64 版 Chromium
echo "🚀 安装 Chromium..."
sudo apt update
sudo apt install -y chromium-browser

# 5️⃣ 下载 ARM64 兼容的 ChromeDriver
echo "🌍 获取 ChromeDriver 兼容版本..."
sudo apt install -y chromium-chromedriver
echo "✅ ChromeDriver 安装完成"

# 7️⃣ 验证安装
echo "🎯 验证安装..."
chromium --version
chromedriver --version

# 创建虚拟环境并安装依赖
echo -e "${GREEN}创建Python虚拟环境...${NC}"
sudo apt install python3.10-venv -y
sudo rm -rf .venv
python3 -m venv .venv

# 激活虚拟环境并安装依赖
source .venv/bin/activate

# 使用pip安装依赖
echo -e "${GREEN}安装Python依赖...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt-get install python3-tk python3-dev -y
pip3 install selenium screeninfo
pip3 install pyautogui

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