# Claude Screenshot Uploader - Windows Uninstaller

$taskName = "ClaudeScreenshotUploader"

Write-Host "=== Claude Screenshot Uploader - Uninstall ===" -ForegroundColor Cyan
Write-Host ""

# Remove scheduled task
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Scheduled task removed." -ForegroundColor Green
} else {
    Write-Host "Scheduled task not found (may already be removed)." -ForegroundColor Yellow
}

# Stop running process
$procs = Get-Process powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*screenshot-uploader*" }
if ($procs) {
    $procs | Stop-Process -Force
    Write-Host "Running process stopped." -ForegroundColor Green
}

Write-Host ""
$choice = Read-Host "Also delete script files? [y/N]"
if ($choice -eq "y" -or $choice -eq "Y") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Remove-Item $scriptDir -Recurse -Force
    Write-Host "Files deleted." -ForegroundColor Green
} else {
    Write-Host "Files kept." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Uninstall complete!" -ForegroundColor Green
