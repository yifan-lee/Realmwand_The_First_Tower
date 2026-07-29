# ============================================================
# Godot MCP Pro — 自动安装脚本 (Windows PowerShell)
#
# 约定：
#   Server 放在 resources/godot-mcp-pro-server/（需开发者自行获取付费包并解压至此）
#   脚本自动生成项目根目录的 .mcp.json
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File .reasonix/skills/godot-mcp-setup/scripts/setup_godot_mcp.ps1
# ============================================================
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Resolve-Path (Join-Path $SCRIPT_DIR "..\..\..\..")
$SERVER_DIR = Join-Path $PROJECT_ROOT "resources\godot-mcp-pro-server"
$MCP_JSON = Join-Path $PROJECT_ROOT ".mcp.json"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Godot MCP Pro - 环境检测与安装" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---------- 1. 检查 Node.js ----------
Write-Host "[1/4] 检查 Node.js ..." -ForegroundColor Cyan

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "[FAIL] 未检测到 Node.js。请安装 Node.js 18+ 后重试。" -ForegroundColor Red
    Write-Host "  下载地址: https://nodejs.org/"
    exit 1
}

$nodeVersion = (node -v) -replace 'v',''
$majorVersion = [int]($nodeVersion.Split('.')[0])
if ($majorVersion -lt 18) {
    Write-Host "[FAIL] Node.js 版本过低 (当前: v$nodeVersion, 需要 >= 18)" -ForegroundColor Red
    Write-Host "  下载地址: https://nodejs.org/"
    exit 1
}

Write-Host "[PASS] Node.js v$nodeVersion" -ForegroundColor Green

# ---------- 2. 检查 Server 目录 ----------
Write-Host "[2/4] 检查 Godot MCP Pro Server ..." -ForegroundColor Cyan

if (-not (Test-Path $SERVER_DIR)) {
    Write-Host "[FAIL] 未找到 Server 目录: resources\godot-mcp-pro-server\" -ForegroundColor Red
    Write-Host ""
    Write-Host "请按以下步骤获取 Godot MCP Pro 付费包：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. 购买 (一次性付费，终身更新):"
    Write-Host "     https://buymeacoffee.com/y1uda/extras"
    Write-Host "     https://y1uda.itch.io/godot-mcp-pro"
    Write-Host ""
    Write-Host "  2. 下载 zip 并解压"
    Write-Host ""
    Write-Host "  3. 将解压后的目录复制到本项目:"
    Write-Host "     Copy-Item -Recurse <解压路径>\godot-mcp-pro\ resources\godot-mcp-pro-server\"
    Write-Host ""
    Write-Host "完成后重新运行此脚本。" -ForegroundColor Yellow
    exit 1
}

$setupJs = Join-Path $SERVER_DIR "server\build\setup.js"
if (-not (Test-Path $setupJs)) {
    Write-Host "[FAIL] Server 缺少 build/setup.js，无法自动构建。" -ForegroundColor Red
    Write-Host "  请确认付费包完整解压到 resources\godot-mcp-pro-server\"
    exit 1
}

$serverIndex = Join-Path $SERVER_DIR "server\build\index.js"
$nodeModules = Join-Path $SERVER_DIR "server\node_modules"
$needsBuild = $false
if ((-not (Test-Path $serverIndex)) -or (-not (Test-Path $nodeModules))) {
    $needsBuild = $true
}

if ($needsBuild) {
    Write-Host "[WARN] Server 需要构建，正在执行 node build/setup.js install ..." -ForegroundColor Yellow
    Push-Location (Join-Path $SERVER_DIR "server")
    node build/setup.js install
    Pop-Location
} else {
    Write-Host "[PASS] Server 已构建" -ForegroundColor Green
}

# ---------- 3. Doctor 验证 ----------
Write-Host "[3/4] 运行环境验证 (doctor) ..." -ForegroundColor Cyan
Push-Location (Join-Path $SERVER_DIR "server")
node build/setup.js doctor
Pop-Location
Write-Host "[PASS] 环境验证通过" -ForegroundColor Green

# ---------- 4. 生成 .mcp.json ----------
Write-Host "[4/4] 生成 .mcp.json ..." -ForegroundColor Cyan

$serverPath = "resources/godot-mcp-pro-server/server/build/index.js"

if (Test-Path $MCP_JSON) {
    $content = Get-Content $MCP_JSON -Raw
    if ($content -match '"godot-mcp-pro"') {
        Write-Host "[PASS] .mcp.json 已存在且包含 godot-mcp-pro 配置，跳过" -ForegroundColor Green
    } else {
        Write-Host "[WARN] .mcp.json 已存在但不含 godot-mcp-pro，请手动合并以下配置:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host '  {'
        Write-Host '    "mcpServers": {'
        Write-Host '      "godot-mcp-pro": {'
        Write-Host '        "command": "node",'
        Write-Host "        `"args`": [`"./$serverPath`"]"
        Write-Host '      }'
        Write-Host '    }'
        Write-Host '  }'
    }
} else {
    $mcpConfig = @{
        mcpServers = @{
            "godot-mcp-pro" = @{
                command = "node"
                args = @("./$serverPath")
            }
        }
    }
    $mcpConfig | ConvertTo-Json -Depth 3 | Set-Content $MCP_JSON -Encoding UTF8
    Write-Host "[PASS] .mcp.json 已自动生成" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  下一步:"
Write-Host "  1. 打开 Godot 编辑器"
Write-Host "  2. 启用插件: Project > Project Settings > Plugins > Godot MCP Pro > Enable"
Write-Host "  3. 重启 AI 客户端以使 .mcp.json 生效"
Write-Host "============================================" -ForegroundColor Green
