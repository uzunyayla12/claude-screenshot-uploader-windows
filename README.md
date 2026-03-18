# claude-screenshot-uploader-windows

Automatically upload screenshots to a remote server via SSH on Windows — built with Claude Code.

When using Claude Code on a remote server via SSH, you can't easily share local screenshots. This tool bridges that gap by watching your local screenshots folder, uploading new files to your server, and copying the remote path to your clipboard — ready to paste into Claude Code.

Inspired by [mdrzn/claude-screenshot-uploader](https://github.com/mdrzn/claude-screenshot-uploader) (macOS). This is the Windows equivalent built entirely with PowerShell.

## How It Works

1. You take a screenshot (ShareX, Snipping Tool, Print Screen — anything)
2. The script detects the new file via `FileSystemWatcher`
3. Uploads it to your remote server via `scp`
4. Copies the remote file path to your clipboard
5. Shows a Windows toast notification

Now just paste the path into Claude Code on your remote server. No manual file transfers.

## Features

- **Real-time detection** — watches your screenshots folder for new files
- **ShareX compatible** — handles ShareX's `YYYY-MM` subfolder structure
- **SSH key auth** — secure, password-free operation
- **Clipboard integration** — remote path is instantly ready to paste
- **Toast notifications** — visual feedback on upload status
- **Auto-start** — optional Task Scheduler integration for startup
- **Auto-delete** — optionally remove local files after upload
- **Easy uninstall** — clean removal script included

## Requirements

- Windows 10/11
- PowerShell 5.1+ (included with Windows)
- OpenSSH Client (Settings > Apps > Optional Features > OpenSSH Client)
- SSH key authentication set up with your remote server

## Quick Start

### 1. Clone the repo

```powershell
git clone https://github.com/uzunyayla12/claude-screenshot-uploader-windows.git
cd claude-screenshot-uploader-windows
```

### 2. Set up SSH key auth (if not already done)

```powershell
# Generate a key
ssh-keygen -t ed25519

# Copy it to your server
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh user@your-server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Edit the config

Open `config.ps1` and set your server details:

```powershell
$Config = @{
    SERVER_HOST = "your-server.com"
    SERVER_USER = "your-username"
    SERVER_PATH = "/tmp/screenshots"
    LOCAL_SCREENSHOTS = "$env:USERPROFILE\Documents\ShareX\Screenshots"
    INCLUDE_SUBDIRECTORIES = $true
    AUTO_DELETE = $false
    SSH_KEY = ""
    FILE_FILTER = "*.png"
}
```

### 4. Run it

```powershell
# Manual run
powershell -ExecutionPolicy Bypass -File screenshot-uploader.ps1

# Or install as a startup task
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Usage with Claude Code

Once running, the workflow is:

1. Take a screenshot with ShareX (or any tool)
2. Wait for the toast notification confirming upload
3. In your SSH session with Claude Code, paste the path — it's already in your clipboard
4. Claude Code can now reference the screenshot on the remote server

## Files

| File | Description |
|------|-------------|
| `config.ps1` | Configuration (server, paths, options) |
| `screenshot-uploader.ps1` | Main script — watches, uploads, copies to clipboard |
| `install.ps1` | Registers as a Windows startup task |
| `uninstall.ps1` | Removes the startup task and optionally deletes files |

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## License

MIT

## Credits

- Inspired by [mdrzn/claude-screenshot-uploader](https://github.com/mdrzn/claude-screenshot-uploader) for macOS
- Built with [Claude Code](https://claude.ai/claude-code)
