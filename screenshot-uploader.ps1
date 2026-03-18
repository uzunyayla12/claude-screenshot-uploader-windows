# Claude Screenshot Uploader for Windows
# Automatically uploads screenshots to a remote server via SSH
# and copies the remote file path to your clipboard.
# Compatible with ShareX, Windows Snipping Tool, and any screenshot tool.

param(
    [switch]$Background
)

# Load configuration
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptDir\config.ps1"

$server = $Config.SERVER_HOST
$user = $Config.SERVER_USER
$remotePath = $Config.SERVER_PATH
$localPath = $Config.LOCAL_SCREENSHOTS
$autoDelete = $Config.AUTO_DELETE
$sshKey = $Config.SSH_KEY
$fileFilter = $Config.FILE_FILTER
$includeSubDirs = $Config.INCLUDE_SUBDIRECTORIES

# Logging helpers
function Write-Status($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Err($msg) { Write-Host "[-] $msg" -ForegroundColor Red }

# Check for OpenSSH
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Err "scp not found. Make sure OpenSSH is installed."
    Write-Err "Settings > Apps > Optional Features > OpenSSH Client"
    exit 1
}

# Check local directory
if (-not (Test-Path $localPath)) {
    Write-Err "Screenshots directory not found: $localPath"
    exit 1
}

# Test SSH connection
Write-Status "Testing SSH connection..."
$sshTestArgs = @("-o", "BatchMode=yes", "-o", "ConnectTimeout=5", "$user@$server", "echo ok")
if ($sshKey -ne "") { $sshTestArgs = @("-i", $sshKey) + $sshTestArgs }
$testResult = & ssh @sshTestArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Err "SSH connection failed! Make sure SSH key authentication is set up."
    Write-Host ""
    Write-Host "  1. Generate an SSH key (if you don't have one):" -ForegroundColor Yellow
    Write-Host "     ssh-keygen -t ed25519" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Copy the key to your server:" -ForegroundColor Yellow
    Write-Host "     type `$env:USERPROFILE\.ssh\id_ed25519.pub | ssh $user@$server `"mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys`"" -ForegroundColor Gray
    Write-Host ""
    Write-Err "Run this script again after setting up SSH key auth."
    exit 1
}
Write-Ok "SSH connection successful!"

# Create remote directory
Write-Status "Creating remote directory: $remotePath"
$sshArgs = @("$user@$server", "mkdir -p $remotePath")
if ($sshKey -ne "") { $sshArgs = @("-i", $sshKey) + $sshArgs }
ssh @sshArgs 2>$null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Status "Watching: $localPath"
Write-Status "Subdirectories: $includeSubDirs"
Write-Status "Target: ${user}@${server}:${remotePath}"
Write-Status "Press Ctrl+C to stop"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set up FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $localPath
$watcher.Filter = $fileFilter
$watcher.IncludeSubdirectories = $includeSubDirs
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
$watcher.InternalBufferSize = 65536
$watcher.EnableRaisingEvents = $true

# Windows toast notification
function Send-Notification($title, $message) {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null

        $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$title</text>
            <text>$message</text>
        </binding>
    </visual>
</toast>
"@
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Screenshot Uploader").Show($toast)
    } catch {
        # Silently continue if notification fails
    }
}

# Upload a screenshot file
function Upload-Screenshot($filePath) {
    $fileName = Split-Path -Leaf $filePath

    # Only process image files
    $ext = [System.IO.Path]::GetExtension($fileName).ToLower()
    if ($ext -notin @('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp')) {
        return
    }

    # Wait for the file to finish writing
    Start-Sleep -Milliseconds 500
    $retries = 0
    while ($retries -lt 10) {
        try {
            [IO.File]::OpenRead($filePath).Close()
            break
        } catch {
            Start-Sleep -Milliseconds 300
            $retries++
        }
    }

    Write-Status "Uploading: $fileName"

    # Upload via SCP
    $remoteTarget = "${user}@${server}:${remotePath}/${fileName}"
    $scpArgs = @("-o", "BatchMode=yes")
    if ($sshKey -ne "") { $scpArgs += @("-i", $sshKey) }
    $scpArgs += @($filePath, $remoteTarget)

    $result = & scp @scpArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        $remoteFullPath = "${remotePath}/${fileName}"
        Set-Clipboard -Value $remoteFullPath
        Write-Ok "Uploaded: $fileName -> $remoteFullPath"
        Write-Ok "Remote path copied to clipboard!"
        Send-Notification "Screenshot Uploaded" "$fileName -> copied to clipboard"

        if ($autoDelete) {
            Remove-Item $filePath -Force
            Write-Status "Local file deleted: $fileName"
        }
    } else {
        Write-Err "Upload failed: $fileName"
        Write-Err $result
        Send-Notification "Upload Failed" "$fileName could not be uploaded"
    }
    Write-Host ""
}

# Register event handlers
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType

    if ($changeType -eq 'Created' -or $changeType -eq 'Renamed') {
        Start-Sleep -Milliseconds 800
        Upload-Screenshot $path
    }
}

Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
Register-ObjectEvent $watcher "Renamed" -Action $action | Out-Null

Write-Ok "Ready! Waiting for new screenshots..."
Write-Host ""

# Keep running
try {
    while ($true) {
        Wait-Event -Timeout 1
    }
} finally {
    $watcher.EnableRaisingEvents = $false
    Get-EventSubscriber | Unregister-Event
    $watcher.Dispose()
    Write-Status "Stopped."
}
