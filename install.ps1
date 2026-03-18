# Claude Screenshot Uploader - Windows Installer
# Registers the uploader as a Windows startup task via Task Scheduler

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uploaderScript = Join-Path $scriptDir "screenshot-uploader.ps1"
$taskName = "ClaudeScreenshotUploader"

Write-Host "=== Claude Screenshot Uploader - Windows Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check OpenSSH
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Host "WARNING: OpenSSH is not installed!" -ForegroundColor Yellow
    Write-Host "Go to Settings > Apps > Optional Features > OpenSSH Client" -ForegroundColor Yellow
    Write-Host ""
}

# Check SSH key
$sshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
if (-not (Test-Path $sshKeyPath)) {
    $sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
}
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "WARNING: No SSH key found. Generate one with:" -ForegroundColor Yellow
    Write-Host "  ssh-keygen -t ed25519" -ForegroundColor Gray
    Write-Host "Then copy it to your server:" -ForegroundColor Yellow
    Write-Host "  type `$env:USERPROFILE\.ssh\id_ed25519.pub | ssh user@server `"mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys`"" -ForegroundColor Gray
    Write-Host ""
}

# Check config
Write-Host "IMPORTANT: Edit config.ps1 with your server details first!" -ForegroundColor Yellow
Write-Host "  $scriptDir\config.ps1" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Add to Windows startup (Task Scheduler)? [Y/n]"
if ($choice -eq "" -or $choice -eq "Y" -or $choice -eq "y") {
    # Remove existing task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    # Create new scheduled task
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$uploaderScript`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Automatically uploads screenshots to a remote server via SSH" `
        -RunLevel Limited | Out-Null

    Write-Host "Scheduled task created: $taskName" -ForegroundColor Green
    Write-Host "It will start automatically on login." -ForegroundColor Green
} else {
    Write-Host "Not added to startup. To run manually:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$uploaderScript`"" -ForegroundColor Gray
}

Write-Host ""
$run = Read-Host "Start now? [Y/n]"
if ($run -eq "" -or $run -eq "Y" -or $run -eq "y") {
    Write-Host "Starting..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$uploaderScript`""
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
