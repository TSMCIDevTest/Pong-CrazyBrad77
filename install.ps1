# Self-elevate if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- CONFIG ---
$repoOwner = "TSMCIDevTest"   # <-- replace with your GitHub username
$repoName  = "Pong-CrazyBrad77"   # <-- replace with your GitHub repo name
$zipUrl    = "https://github.com/$repoOwner/$repoName/releases/latest/download/Pong.zip"

$installFolderName = "Pong"
$programFilesPath = [System.Environment]::GetFolderPath("ProgramFiles")
$destinationPath = Join-Path -Path $programFilesPath -ChildPath $installFolderName
$exePath = Join-Path -Path $destinationPath -ChildPath "Pong.exe"

# Shortcut paths
$desktopPath = [Environment]::GetFolderPath("Desktop")
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$desktopShortcut = Join-Path $desktopPath "Pong.lnk"
$startMenuShortcut = Join-Path $startMenuPath "Pong.lnk"

function Show-Message {
    param ([string]$message)
    Write-Host "`n----------------------------------------"
    Write-Host $message -ForegroundColor Green
    Write-Host "----------------------------------------`n"
}

function Create-Shortcut {
    param (
        [string]$shortcutPath,
        [string]$targetPath
    )
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = Split-Path $targetPath
    $shortcut.IconLocation = $targetPath
    $shortcut.WindowStyle = 1
    $shortcut.Save()
}

function Install-App {
    $tempZip = Join-Path $env:TEMP "Pong.zip"

    Show-Message "Downloading Pong..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing

    if (-Not (Test-Path -Path $destinationPath)) {
        Show-Message "Creating installation folder: $destinationPath"
        New-Item -ItemType Directory -Path $destinationPath | Out-Null
    }

    Show-Message "Extracting files..."
    Expand-Archive -Path $tempZip -DestinationPath $destinationPath -Force
    Remove-Item $tempZip -Force

    if (Test-Path $exePath) {
        Show-Message "Creating shortcuts..."
        Create-Shortcut -shortcutPath $desktopShortcut -targetPath $exePath
        Create-Shortcut -shortcutPath $startMenuShortcut -targetPath $exePath
    }

    Show-Message "Installation complete!"
    Write-Host "Pong installed at: $destinationPath" -ForegroundColor Cyan
    Write-Host "Shortcuts created on Desktop and Start Menu." -ForegroundColor Yellow
}

function Uninstall-App {
    if (Test-Path -Path $destinationPath) {
        Show-Message "Uninstalling Pong..."
        Remove-Item -Path $destinationPath -Recurse -Force
        if (Test-Path $desktopShortcut) { Remove-Item $desktopShortcut -Force }
        if (Test-Path $startMenuShortcut) { Remove-Item $startMenuShortcut -Force }
        Show-Message "Uninstallation complete!"
    } else {
        Write-Host "Pong is not installed." -ForegroundColor Yellow
    }
}

function Show-Menu {
    Clear-Host
    Show-Message "Pong Installer Menu"

    if (Test-Path -Path $destinationPath) {
        Write-Host "1) Reinstall Pong"
        Write-Host "2) Uninstall Pong"
        Write-Host "3) Exit"
        $choice = Read-Host "Enter your choice (1-3)"
        switch ($choice) {
            1 { Uninstall-App; Install-App }
            2 { Uninstall-App }
            3 { exit }
            default { Write-Host "Invalid choice." -ForegroundColor Red }
        }
    } else {
        Write-Host "1) Install Pong"
        Write-Host "2) Exit"
        $choice = Read-Host "Enter your choice (1-2)"
        switch ($choice) {
            1 { Install-App }
            2 { exit }
            default { Write-Host "Invalid choice." -ForegroundColor Red }
        }
    }
}

# Run the menu
Show-Menu
