$global:ErrorActionPreference = "Continue"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  ?? Antigravity SOTA Toolkit - Gyors Telepito Letoltese..." -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$tempZip = Join-Path $env:TEMP "Antigravity-Setup.zip"
$tempExtract = Join-Path $env:TEMP "Antigravity-Setup-Extract"
$cacheBuster = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$zipUrl = "https://github.com/DBeni24/Antigravity-Setup/archive/refs/heads/main.zip?t=$cacheBuster"

Write-Host "`n[1/3] Csomag letoltese a GitHub-rol..." -ForegroundColor Yellow
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-RestMethod -Uri $zipUrl -OutFile $tempZip
    Write-Host "  -> Letoltve: $tempZip" -ForegroundColor Green
} catch {
    Write-Error "Nem sikerult letolteni a csomagot: $_"
    return
}

Write-Host "`n[2/3] Kicsomagolas..." -ForegroundColor Yellow
if (Test-Path $tempExtract) {
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
Write-Host "  -> Kicsomagolva." -ForegroundColor Green

$installerPath = Join-Path $tempExtract "Antigravity-Setup-main\install.ps1"
if (Test-Path $installerPath) {
    Write-Host "`n[3/3] Telepito inditasa..." -ForegroundColor Yellow
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File $installerPath
} else {
    Write-Error "Nem talalhato az install.ps1 a kicsomagolt csomagban!"
}

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue