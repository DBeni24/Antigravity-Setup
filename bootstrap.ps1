# ==============================================================================
# Antigravity SOTA Toolkit - Zero-Dependency Bootstrap Telepítő (Windows)
# ==============================================================================
# Futtatható közvetlenül a webről (Git sem szükséges!):
#   irm https://raw.githubusercontent.com/DBeni24/Antigravity-Setup/main/bootstrap.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  🚀 Antigravity SOTA Toolkit - Gyors Telepítő Letöltése..." -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$tempZip = Join-Path $env:TEMP "Antigravity-Setup.zip"
$tempExtract = Join-Path $env:TEMP "Antigravity-Setup-Extract"
$zipUrl = "https://github.com/DBeni24/Antigravity-Setup/archive/refs/heads/main.zip"

# 1. Zip letöltése
Write-Host "`n[1/3] Csomag letöltése a GitHub-ról..." -ForegroundColor Yellow
Invoke-RestMethod -Uri $zipUrl -OutFile $tempZip
Write-Host "  -> Letöltve: $tempZip" -ForegroundColor Green

# 2. Kicsomagolás
Write-Host "`n[2/3] Kicsomagolás..." -ForegroundColor Yellow
if (Test-Path $tempExtract) {
    Remove-Item $tempExtract -Recurse -Force | Out-Null
}
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
Write-Host "  -> Kicsomagolva." -ForegroundColor Green

# 3. install.ps1 futtatása
$installerPath = Join-Path $tempExtract "Antigravity-Setup-main\install.ps1"
if (Test-Path $installerPath) {
    Write-Host "`n[3/3] Telepítő indítása..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $installerPath
} else {
    Write-Error "Nem található az install.ps1 fájl a kicsomagolt csomagban!"
}

# Takarítás
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Write-Host "`nKész!" -ForegroundColor Green
