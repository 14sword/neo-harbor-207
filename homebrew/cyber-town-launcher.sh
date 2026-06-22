#!/bin/bash

# Neo Harbor 207 // 赛博小镇一键启动器
# ----------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

echo "====== 赛博小镇城市接入终端 // NEO HARBOR 207 ======"

# 1. 检查环境变量
ENV_PATH="backend/.env"
if [ ! -f "$ENV_PATH" ]; then
    echo "[!] 未检测到 API 密钥配置文件，正在初始化环境..."
    read -p "请输入 Groq API Key (直接回车跳过): " groq_key
    read -p "请输入 MiMo API Key (直接回车跳过): " mimo_key
    
    echo "MIMO_API_KEY=$mimo_key" > "$ENV_PATH"
    echo "GROQ_API_KEY=$groq_key" >> "$ENV_PATH"
    echo "DEEPSEEK_API_KEY=" >> "$ENV_PATH"
    echo "ENABLE_BATCH_DIALOGUE_REFRESH=false" >> "$ENV_PATH"
    echo "[✓] 配置文件已生成: backend/.env"
fi

# 2. 检查并启动后端服务 (8000 端口)
PORT=8000
nc -z localhost $PORT >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[✓] 检测到 FastAPI 后端已在运行。"
else
    echo "[...] 正在拉起 FastAPI 后端服务..."
    if command -v brew &> /dev/null && brew services list | grep -q "cyber-town-backend"; then
        brew services start cyber-town-backend
    else
        echo "[!] 本地拉起 Python FastAPI 后端中..."
        cd backend
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -r requirements.txt
        python3 -m uvicorn main:app --port $PORT --reload > /dev/null 2>&1 &
        BACKEND_PID=$!
        cd ..
    fi
    
    # 等待端口响应
    for i in {1..10}; do
        nc -z localhost $PORT >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "[✓] 后端服务已就绪。"
            break
        fi
        sleep 1
    done
fi

# 3. 启动 Godot 客户端
echo "[...] 正在拉起 Godot 游戏客户端..."
if [ -d "/Applications/Godot.app" ]; then
    /Applications/Godot.app/Contents/MacOS/Godot --path game/
elif command -v godot &> /dev/null; then
    godot --path game/
else
    echo "[!] 未在 Applications 中检测到 Godot 4，尝试通过操作系统默认程序打开项目..."
    open game/project.godot
fi

# 4. 退出清理 (如果是本地进程则关闭)
if [ ! -z "$BACKEND_PID" ]; then
    echo ""
    read -p "游戏已关闭，是否停止本地运行的后端进程？(Y/n): " stop_backend
    if [[ "$stop_backend" =~ ^[Yy]*$ ]] || [ -z "$stop_backend" ]; then
        kill $BACKEND_PID
        echo "[✓] 后端进程已安全终止。"
    fi
fi
