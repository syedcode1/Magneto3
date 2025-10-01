# MAGNETO Auto-Update System

## Overview
MAGNETO v3.3 includes an automatic update mechanism that checks for new versions from the GitHub repository and allows one-click updates.

## Features
- ✅ **Automatic Update Check** on startup (silent)
- ✅ **Manual Update Check** via button in GUI
- ✅ **One-Click Update** with automatic download and installation
- ✅ **Automatic Backup** of current version before updating
- ✅ **Changelog Display** showing what's new
- ✅ **Auto-Restart** after successful update

## How It Works

### 1. On Startup
- MAGNETO silently checks GitHub for updates when the GUI loads
- If a new version is available, you'll see a dialog with the changelog
- Click "Yes" to update or "No" to skip

### 2. Manual Check
- Click the **[↻] CHECK UPDATES** button in the control panel
- This will check GitHub and show update status

### 3. Update Process
When you choose to update:
1. **Download** - Downloads latest version from GitHub
2. **Backup** - Creates backup folder with current version
3. **Extract** - Extracts new files
4. **Install** - Replaces old files with new ones (preserves logs)
5. **Restart** - Automatically restarts MAGNETO with new version

## For Repository Maintainers

### Publishing Updates

1. **Update version.json** in the repository root:
```json
{
  "version": "3.4.0",
  "releaseDate": "2025-10-15",
  "changelog": "• New feature 1\\n• Bug fix 2\\n• Enhancement 3",
  "downloadUrl": "https://github.com/syedcode1/Magneto3/archive/refs/heads/main.zip",
  "critical": false,
  "minVersion": "3.0.0"
}
```

2. **Update files** in the repository:
   - MAGNETO_GUI_v3.ps1
   - MAGNETO_v3.ps1
   - Launch_MAGNETO_v3.bat
   - version.json

3. **Commit and push** to GitHub

4. Users will automatically see the update on next launch!

### Version Numbering
- **Major.Minor.Patch** (e.g., 3.4.1)
- **Major**: Breaking changes or major new features
- **Minor**: New features, new techniques
- **Patch**: Bug fixes, small improvements

### Changelog Format
Use `\\n` for line breaks in JSON:
```json
"changelog": "• Fixed Defender detection\\n• Added 5 new techniques\\n• Improved HTML reports"
```

## Files Included in Update
- `*.ps1` - PowerShell scripts (GUI and core)
- `*.bat` - Batch launcher files
- `*.json` - Configuration files

## Files Preserved (Not Overwritten)
- `MAGNETO_GUI_Logs/*` - Log files
- `MAGNETO_Logs/*` - Attack logs
- `*.html` - Generated reports
- `MAGNETO_Backup_*` - Backup folders

## Backup Location
Backups are stored in: `MAGNETO_Backup_v{version}_{timestamp}`

Example: `MAGNETO_Backup_v3.3.0_20251001_143520`

## Troubleshooting

### Update Check Fails
- **Check internet connection**
- **Verify GitHub is accessible**
- **Check firewall/proxy settings**
- Manually visit: https://github.com/syedcode1/Magneto3

### Update Download Fails
- **Check available disk space**
- **Try manual download from GitHub**
- **Check antivirus isn't blocking**

### Update Installation Fails
- **Restore from backup folder**
- **Manually download and extract**
- **Ensure MAGNETO files aren't locked**

## Manual Update (Fallback)
If auto-update fails:

1. Go to: https://github.com/syedcode1/Magneto3
2. Click "Code" → "Download ZIP"
3. Extract the ZIP file
4. Copy `*.ps1`, `*.bat`, `*.json` to your MAGNETO folder
5. Overwrite when prompted
6. Restart MAGNETO

## Security Notes
- Updates are downloaded from **GitHub only**
- URL is hardcoded: `https://raw.githubusercontent.com/syedcode1/Magneto3/main/version.json`
- Files are downloaded over **HTTPS**
- Backups are created **before** any changes
- You can review changelog **before** updating

## Version History
- **v3.3.0** - Auto-update system, enhanced reporting, 38 techniques
- **v3.2.0** - APT campaigns, HTML reports
- **v3.1.0** - GUI improvements, technique enhancements
- **v3.0.0** - Initial MAGNETO v3 release

---

For support or issues: https://github.com/syedcode1/Magneto3/issues
