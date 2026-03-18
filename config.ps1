# Claude Screenshot Uploader - Windows Configuration
# Edit this file with your own settings

$Config = @{
    # SSH server details
    SERVER_HOST = "your-server.com"
    SERVER_USER = "your-username"
    SERVER_PATH = "/tmp/screenshots"

    # Local screenshots directory to watch
    # Default: Windows Screenshots folder
    # For ShareX users: "$env:USERPROFILE\Documents\ShareX\Screenshots"
    LOCAL_SCREENSHOTS = "$env:USERPROFILE\Documents\ShareX\Screenshots"

    # Watch subdirectories (required for ShareX which uses YYYY-MM folders)
    INCLUDE_SUBDIRECTORIES = $true

    # Delete local file after successful upload?
    AUTO_DELETE = $false

    # SSH key file (leave empty to use default ~/.ssh/id_ed25519 or id_rsa)
    SSH_KEY = ""

    # File pattern to watch
    FILE_FILTER = "*.png"
}
