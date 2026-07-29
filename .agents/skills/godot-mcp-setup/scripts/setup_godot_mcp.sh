#!/usr/bin/env bash
# ============================================================
# Godot MCP Pro — 自动安装脚本 (Unix / macOS / Git Bash)
#
# 约定：
#   Server 放在 resources/godot-mcp-pro-server/（需开发者自行获取付费包并解压至此）
#   脚本自动生成项目根目录的 .mcp.json
#
# 用法：
#   bash .reasonix/skills/godot-mcp-setup/scripts/setup_godot_mcp.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../" && pwd)"
SERVER_DIR="$PROJECT_ROOT/resources/godot-mcp-pro-server"
MCP_JSON="$PROJECT_ROOT/.mcp.json"

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Godot MCP Pro — 环境检测与安装${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# ---------- 1. 检查 Node.js ----------
echo -e "${CYAN}[1/4]${NC} 检查 Node.js ..."

if ! command -v node &> /dev/null; then
    echo -e "${RED}[FAIL]${NC} 未检测到 Node.js。请安装 Node.js 18+ 后重试。"
    echo "  下载地址: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}[FAIL]${NC} Node.js 版本过低 (当前: $(node -v), 需要 >= 18)"
    echo "  下载地址: https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}[PASS]${NC} Node.js $(node -v)"

# ---------- 2. 检查 Server 目录 ----------
echo -e "${CYAN}[2/4]${NC} 检查 Godot MCP Pro Server ..."

if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}[FAIL]${NC} 未找到 Server 目录: resources/godot-mcp-pro-server/"
    echo ""
    echo -e "${YELLOW}请按以下步骤获取 Godot MCP Pro 付费包：${NC}"
    echo ""
    echo "  1. 购买 (一次性付费，终身更新):"
    echo "     https://buymeacoffee.com/y1uda/extras"
    echo "     https://y1uda.itch.io/godot-mcp-pro"
    echo ""
    echo "  2. 下载 zip 并解压"
    echo ""
    echo "  3. 将解压后的目录复制到本项目:"
    echo "     cp -r <解压路径>/godot-mcp-pro/ resources/godot-mcp-pro-server/"
    echo ""
    echo -e "${YELLOW}完成后重新运行本脚本。${NC}"
    exit 1
fi

if [ ! -f "$SERVER_DIR/server/build/setup.js" ]; then
    echo -e "${RED}[FAIL]${NC} Server 缺少 build/setup.js，无法自动构建。"
    echo "  请确认付费包完整解压到 resources/godot-mcp-pro-server/"
    exit 1
fi

NEEDS_BUILD=false
if [ ! -f "$SERVER_DIR/server/build/index.js" ] || [ ! -d "$SERVER_DIR/server/node_modules" ]; then
    NEEDS_BUILD=true
fi

if $NEEDS_BUILD; then
    echo -e "${YELLOW}[WARN]${NC} Server 需要构建，正在执行 node build/setup.js install ..."
    cd "$SERVER_DIR/server"
    node build/setup.js install
    cd "$PROJECT_ROOT"
else
    echo -e "${GREEN}[PASS]${NC} Server 已构建"
fi

# ---------- 3. Doctor 验证 ----------
echo -e "${CYAN}[3/4]${NC} 运行环境验证 (doctor) ..."
cd "$SERVER_DIR/server"
node build/setup.js doctor
cd "$PROJECT_ROOT"
echo -e "${GREEN}[PASS]${NC} 环境验证通过"

# ---------- 4. 生成 .mcp.json ----------
echo -e "${CYAN}[4/4]${NC} 生成 .mcp.json ..."

SERVER_REL_PATH="resources/godot-mcp-pro-server/server/build/index.js"

if [ -f "$MCP_JSON" ]; then
    if grep -q '"godot-mcp-pro"' "$MCP_JSON" 2>/dev/null; then
        echo -e "${GREEN}[PASS]${NC} .mcp.json 已存在且包含 godot-mcp-pro 配置，跳过"
    else
        echo -e "${YELLOW}[WARN]${NC} .mcp.json 已存在但不含 godot-mcp-pro，请手动合并:"
        echo ""
        echo '  { "mcpServers": { "godot-mcp-pro": { "command": "node", "args": ["./'$SERVER_REL_PATH'"] } } }'
    fi
else
    cat > "$MCP_JSON" << MCPEOF
{
  "mcpServers": {
    "godot-mcp-pro": {
      "command": "node",
      "args": ["./$SERVER_REL_PATH"]
    }
  }
}
MCPEOF
    echo -e "${GREEN}[PASS]${NC} .mcp.json 已自动生成"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo ""
echo "  下一步:"
echo "  1. 打开 Godot 编辑器"
echo "  2. 启用插件: Project → Project Settings → Plugins → Godot MCP Pro → Enable"
echo "  3. 重启 AI 客户端以使 .mcp.json 生效"
echo -e "${GREEN}============================================${NC}"
