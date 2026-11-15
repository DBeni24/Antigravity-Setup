# ==============================================================================
# Antigravity SOTA Toolkit - Automatikus Telepítő Szkript (Windows)
# ==============================================================================
# Használat:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  🚀 Antigravity SOTA Toolkit Telepítése és Konfigurálása" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$userProfile = [Environment]::GetFolderPath("UserProfile")
$geminiConfigDir = Join-Path $userProfile ".gemini\config"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Célkönyvtárak előkészítése
Write-Host "`n[1/6] Célkönyvtárak előkészítése ($geminiConfigDir)..." -ForegroundColor Yellow
$dirs = @(
    $geminiConfigDir,
    (Join-Path $geminiConfigDir "skills"),
    (Join-Path $geminiConfigDir "rules"),
    (Join-Path $geminiConfigDir "hooks")
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}
Write-Host "  -> Könyvtárak kész." -ForegroundColor Green

# 2. uv (Python Package Manager) ellenőrzése / telepítése
Write-Host "`n[2/6] 'uv' ellenőrzése..." -ForegroundColor Yellow
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "  -> 'uv' nincs telepítve. Letöltés és telepítés..." -ForegroundColor Cyan
    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:PATH = "$userProfile\.local\bin;" + $env:PATH
} else {
    Write-Host "  -> 'uv' elérhető: $(uv --version)" -ForegroundColor Green
}

# 3. Node.js & npm ellenőrzése
Write-Host "`n[3/6] Node.js és npm ellenőrzése..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    # Ellenőrizzük a Program Files-ban
    $defaultNode = "C:\Program Files\nodejs\node.exe"
    if (Test-Path $defaultNode) {
        $env:PATH = "C:\Program Files\nodejs;$userProfile\AppData\Roaming\npm;" + $env:PATH
        Write-Host "  -> Node.js megtalálva a Program Files-ban és hozzáadva a PATH-hoz." -ForegroundColor Green
    } else {
        Write-Host "  -> Node.js nem található. Telepítés winget segítségével..." -ForegroundColor Cyan
        winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
        $env:PATH = "C:\Program Files\nodejs;$userProfile\AppData\Roaming\npm;" + $env:PATH
    }
} else {
    Write-Host "  -> Node.js elérhető: $(node -v)" -ForegroundColor Green
}

# 4. Globális MCP Csomagok telepítése
Write-Host "`n[4/6] MCP Szerverek és Kódintelligencia telepítése..." -ForegroundColor Yellow

# 4.1 agent-lsp (npm)
Write-Host "  -> agent-lsp telepítése npm-mel..." -ForegroundColor Cyan
npm install -g @blackwell-systems/agent-lsp 2>$null | Out-Null
Write-Host "     agent-lsp telepítve." -ForegroundColor Green

# 4.2 Python MCP eszközök (uv tool)
Write-Host "  -> code-index-mcp telepítése uv-val..." -ForegroundColor Cyan
uv tool install code-index-mcp --python 3.12 --force 2>$null | Out-Null
Write-Host "     code-index-mcp telepítve." -ForegroundColor Green

Write-Host "  -> mcp-server-tree-sitter telepítése uv-val..." -ForegroundColor Cyan
uv tool install mcp-server-tree-sitter --python 3.12 --with "mcp<2" --force 2>$null | Out-Null
Write-Host "     mcp-server-tree-sitter telepítve." -ForegroundColor Green

# 5. Skillek, Szabályok és Hookok másolása
Write-Host "`n[5/6] Skillek, Szabályzat és Hookok integrálása..." -ForegroundColor Yellow

# Skillek
Copy-Item -Path "$scriptDir\config\skills\*" -Destination "$geminiConfigDir\skills" -Recurse -Force
Write-Host "  -> 23 db SOTA skill átmásolva." -ForegroundColor Green

# Szabályzat
Copy-Item -Path "$scriptDir\config\rules\*" -Destination "$geminiConfigDir\rules" -Recurse -Force
Write-Host "  -> Globális AGENTS.md átmásolva." -ForegroundColor Green

# Hookok
Copy-Item -Path "$scriptDir\config\hooks\*" -Destination "$geminiConfigDir\hooks" -Recurse -Force
Copy-Item -Path "$scriptDir\config\hooks.json" -Destination "$geminiConfigDir\hooks.json" -Force
Copy-Item -Path "$scriptDir\config\pwsh.cmd" -Destination "$geminiConfigDir\pwsh.cmd" -Force
Write-Host "  -> Safety Gate és Lint Hookok beállítva." -ForegroundColor Green

# MCP Konfiguráció felépítése dinamikus elérési utakkal
$mcpJson = @"
{
  "mcpServers": {
    "agent-lsp": {
      "command": "$($userProfile -replace '\\', '\\')\\AppData\\Roaming\\npm\\agent-lsp.cmd",
      "args": [],
      "env": {
        "PATH": "C:\\Program Files\\nodejs;$($userProfile -replace '\\', '\\')\\AppData\\Roaming\\npm;$($userProfile -replace '\\', '\\')\\.local\\bin;%PATH%",
        "AGENT_LSP_LOG_LEVEL": "warn"
      }
    },
    "code-index": {
      "command": "$($userProfile -replace '\\', '\\')\\.local\\bin\\code-index-mcp.exe",
      "args": []
    },
    "tree-sitter": {
      "command": "$($userProfile -replace '\\', '\\')\\.local\\bin\\mcp-server-tree-sitter.exe",
      "args": []
    },
    "playwright": {
      "command": "C:\\Program Files\\nodejs\\npx.cmd",
      "args": [
        "-y",
        "@playwright/mcp@latest",
        "--headless"
      ],
      "env": {
        "PATH": "C:\\Program Files\\nodejs;$($userProfile -replace '\\', '\\')\\AppData\\Roaming\\npm;%PATH%"
      }
    }
  }
}
"@
Set-Content -Path "$geminiConfigDir\mcp_config.json" -Value $mcpJson -Encoding UTF8
Write-Host "  -> mcp_config.json generálva." -ForegroundColor Green

# 6. Felhasználói PATH frissítése tartósan
Write-Host "`n[6/6] Felhasználói környezeti változók (PATH) ellenőrzése..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$neededPaths = @(
    "C:\Program Files\nodejs",
    "$userProfile\AppData\Roaming\npm",
    "$userProfile\.local\bin"
)

$parts = $userPath -split ';' | Where-Object { $_ -ne "" }
$updated = $false
foreach ($p in $neededPaths) {
    if ($parts -notcontains $p) {
        $parts += $p
        $updated = $true
    }
}
if ($updated) {
    [Environment]::SetEnvironmentVariable("Path", ($parts -join ';'), "User")
    Write-Host "  -> PATH sikeresen frissítve a felhasználói regisztrációban." -ForegroundColor Green
} else {
    Write-Host "  -> PATH már tartalmazza a szükséges könyvtárakat." -ForegroundColor Green
}

Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host "  🎉 SIKERES TELEPÍTÉS!" -ForegroundColor Green
Write-Host "  Az Antigravity mostantól minden projektben elérheti a 23 SOTA skillt," -ForegroundColor Green
Write-Host "  a 4 MCP kódintelligencia szervert és a biztonsági hookokat." -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
