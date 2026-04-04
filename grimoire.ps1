# ╔══════════════════════════════════════════════════╗
# ║              grimoire — Windows setup            ║
# ╚══════════════════════════════════════════════════╝
# Run as Administrator in PowerShell
# After this completes, run grimoire.sh inside WSL

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║           * grimoire *               ║" -ForegroundColor Magenta
    Write-Host "  ║      Windows setup wizard            ║" -ForegroundColor Magenta
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Step($num, $total, $msg) {
    Write-Host "  ├─ " -ForegroundColor Cyan -NoNewline
    Write-Host "[$num/$total] " -ForegroundColor Green -NoNewline
    Write-Host $msg
}

function Info($msg) {
    Write-Host "  │   " -ForegroundColor Cyan -NoNewline
    Write-Host $msg -ForegroundColor DarkGray
}

function Ok($msg) {
    Write-Host "  │   " -ForegroundColor Cyan -NoNewline
    Write-Host "✓ $msg" -ForegroundColor Green
}

function Warn($msg) {
    Write-Host "  │   " -ForegroundColor Cyan -NoNewline
    Write-Host "⚠ $msg" -ForegroundColor Yellow
}

function Err($msg) {
    Write-Host "  │   " -ForegroundColor Cyan -NoNewline
    Write-Host "✗ $msg" -ForegroundColor Red
}

Banner

Write-Host "  ┌─ Windows prerequisites" -ForegroundColor Cyan
Write-Host "  │" -ForegroundColor Cyan

# ── WSL ──
Step 1 5 "Checking WSL..."
$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $wsl) {
    Info "Installing WSL..."
    wsl --install --no-launch
    Ok "WSL installed. You may need to reboot and re-run this script."
} else {
    Info "WSL is installed"
}

# ── WSL networking ──
Step 2 5 "Configuring WSL mirrored networking..."
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if (Test-Path $wslConfigPath) {
    $content = Get-Content $wslConfigPath -Raw
    if ($content -match "networkingMode=mirrored") {
        Info "Mirrored networking already configured"
    } else {
        Add-Content $wslConfigPath "`n[wsl2]`nnetworkingMode=mirrored"
        Ok "Added mirrored networking to .wslconfig"
    }
} else {
    Set-Content $wslConfigPath "[wsl2]`nnetworkingMode=mirrored"
    Ok "Created .wslconfig with mirrored networking"
}

# ── OpenSSH Server ──
Step 3 5 "Configuring OpenSSH server..."
$sshd = Get-Service -Name sshd -ErrorAction SilentlyContinue
if (-not $sshd) {
    Info "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic
Ok "sshd running and set to auto-start"

# ── Default shell ──
Step 4 5 "Setting default SSH shell to WSL bash..."
$bashCmd = Get-Command bash.exe -ErrorAction SilentlyContinue
if (-not $bashCmd) {
    Warn "bash.exe not found. Open a terminal and run 'wsl --install', then reboot and re-run this script."
} else {
    $bashPath = $bashCmd.Source
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value $bashPath -PropertyType String -Force | Out-Null
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandLine -ErrorAction SilentlyContinue
    Restart-Service sshd
    Ok "Default shell set to $bashPath"
}

# ── Firewall ──
Step 5 5 "Configuring firewall for mosh..."
$moshRule = Get-NetFirewallRule -DisplayName "Mosh" -ErrorAction SilentlyContinue
if (-not $moshRule) {
    New-NetFirewallRule -DisplayName "Mosh" -Direction Inbound -Protocol UDP -LocalPort 60000-61000 -Action Allow | Out-Null
    Ok "Mosh UDP firewall rule created"
} else {
    Info "Mosh firewall rule already exists"
}

Write-Host "  │" -ForegroundColor Cyan
Write-Host "  └─ " -ForegroundColor Cyan -NoNewline
Write-Host "done" -ForegroundColor Green -NoNewline
Write-Host ""
Write-Host ""

# ── Hand off to WSL ──
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     Windows setup complete!          ║" -ForegroundColor Magenta
Write-Host "  ║     Launching WSL setup...           ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Detect grimoire.sh location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wslScriptDir = $scriptDir -replace '\\','/' -replace '^([A-Za-z]):','/mnt/$1'
$wslScriptDir = $wslScriptDir.ToLower() -replace '/mnt/([a-z])','/mnt/$1'

Write-Host "  Now run inside WSL:" -ForegroundColor Yellow
Write-Host "    bash $wslScriptDir/grimoire.sh" -ForegroundColor White
Write-Host ""
