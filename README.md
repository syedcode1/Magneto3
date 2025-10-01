# MAGNETO v3 - Advanced APT Campaign Simulator

**Version 3** - October 2025

MAGNETO is a legitimate cybersecurity testing tool designed for security professionals to simulate Advanced Persistent Threat (APT) campaigns and MITRE ATT&CK techniques.

## Features

- ✅ **38 MITRE ATT&CK Techniques** - Comprehensive attack simulation
- ✅ **7 APT Campaign Simulations** - Real-world threat actor profiles (APT41, Lazarus, APT29, etc.)
- ✅ **MITRE ATT&CK Tactics Visualization** - Interactive HTML reports with kill chain mapping
- ✅ **Enhanced Threat Intelligence** - Detailed APT attribution and detection methods
- ✅ **Auto-Update System** - One-click updates from GitHub
- ✅ **Windows Forms GUI** - No external dependencies required

## Quick Start

### Installation

1. Download the latest release from GitHub
2. Extract all files to a folder
3. **Add antivirus exclusion** (see below)
4. Run `Launch_MAGNETO_v3.bat` as Administrator

### System Requirements

- Windows 10/11
- PowerShell 5.0 or higher
- Administrator privileges (recommended)
- .NET Framework 4.5+

## ⚠️ CRITICAL: Antivirus Exclusion Required

**YOU MUST ADD ANTIVIRUS EXCLUSIONS BEFORE RUNNING MAGNETO**

MAGNETO is a **legitimate cybersecurity testing tool** used by security professionals for authorized penetration testing and red team exercises. Antivirus software **will block MAGNETO** because it simulates real attack techniques.

### Common Error Messages

If you see these errors, you need to add exclusions:

```
❌ "This script contains malicious content and has been blocked by your antivirus software"
❌ "Heur.BZC.ZFV.Boxter.1069.A73FD735 detected"
❌ "Technique section is empty"
❌ "Error loading techniques"
```

### BitDefender - Step-by-Step Instructions

**BEFORE launching MAGNETO, follow these steps:**

1. Open **BitDefender** from system tray
2. Click **Protection** in left sidebar
3. Click **Antivirus**
4. Click the **Settings** gear icon (⚙️)
5. Scroll down and click **Manage Exceptions**
6. Click **Add an Exception** button
7. Choose **Folder** from the dropdown
8. Click **Browse** and navigate to your MAGNETO folder
   - Example: `C:\Users\YourName\Desktop\Latest MagnetoV3 working`
9. Click **Select Folder**
10. Click **Add Exception** to confirm
11. **Restart your computer** (recommended) or restart MAGNETO

**Alternative - Add Files Individually:**

If folder exclusion doesn't work, add these files:
- `MAGNETO_v3.ps1`
- `MAGNETO_GUI_v3.ps1`
- `Launch_MAGNETO_v3.bat`

### Windows Defender - Step-by-Step Instructions

**BEFORE launching MAGNETO, follow these steps:**

1. Open **Windows Security** (search in Start menu)
2. Click **Virus & threat protection**
3. Scroll down to **Virus & threat protection settings**
4. Click **Manage settings**
5. Scroll down to **Exclusions**
6. Click **Add or remove exclusions**
7. Click **+ Add an exclusion**
8. Select **Folder**
9. Browse to your MAGNETO installation directory
10. Click **Select Folder**
11. Close Windows Security and launch MAGNETO

### Kaspersky Users

1. Open **Kaspersky** application
2. Click **Settings** (⚙️ gear icon)
3. Click **Additional** → **Threats and Exclusions**
4. Click **Manage Exclusions**
5. Click **Add**
6. Browse to MAGNETO folder and click **Add**

### Norton Users

1. Open **Norton** application
2. Click **Settings**
3. Click **Antivirus**
4. Click **Scans and Risks**
5. Under **Exclusions/Low Risks**, click **Configure**
6. Click **Add** under **Items to Exclude from Scans**
7. Browse to MAGNETO folder

### Avast/AVG Users

1. Open **Avast/AVG** application
2. Go to **Menu** → **Settings**
3. Click **Exceptions** (or **General** → **Exceptions**)
4. Click **Add Exception**
5. Browse to MAGNETO folder
6. Click **Add Exception**

### McAfee Users

1. Open **McAfee** application
2. Click **PC Security** → **Real-Time Scanning**
3. Click **Turn Off** → **Never**
4. Or add MAGNETO folder to **Excluded Files** in settings

### Other Antivirus Software

Add the entire MAGNETO installation folder to your antivirus exclusion/whitelist list. Consult your antivirus documentation for "How to add exclusions" or "How to whitelist files."

### Why Does MAGNETO Trigger Antivirus?

MAGNETO is a **red team tool** that simulates real-world attack techniques:

- ✅ **Registry modifications** - Simulates persistence mechanisms
- ✅ **Process injection patterns** - Tests EDR detection
- ✅ **Network reconnaissance** - Simulates C2 communications
- ✅ **Credential access techniques** - Tests security monitoring
- ✅ **LOLBin execution** - Uses legitimate Windows binaries

These are **intentional, authorized security testing behaviors** used by:
- Penetration testers
- Red teams
- SOC analysts
- Security researchers
- SIEM/EDR vendors

**This is the SAME reason tools like Metasploit, Cobalt Strike, and Atomic Red Team are flagged.**

### Verification After Adding Exclusion

After adding the exclusion:

1. **Restart MAGNETO** or reboot your computer
2. Launch `Launch_MAGNETO_v3.bat`
3. You should see:
   ```
   [+] MAGNETO GUI v3 initialized
   [+] Found MAGNETO_v3.ps1 in script directory
   [>] Loading techniques from MAGNETO v3 script...
   [+] Loaded 38 techniques successfully
   ```
4. The **Technique List** in GUI should show all 38 techniques

### Still Having Issues?

If exclusions don't work:

1. **Temporarily disable antivirus** (not recommended for production systems)
2. **Run MAGNETO in a VM** (recommended for testing environments)
3. **Contact your antivirus vendor** and explain it's a legitimate security testing tool
4. **Check GitHub Issues**: https://github.com/syedcode1/Magneto3/issues

## Usage

### GUI Mode (Recommended)

```batch
Launch_MAGNETO_v3.bat
```

The GUI provides:
- Technique selection and filtering
- APT campaign dropdown
- Real-time execution monitoring
- HTML report generation
- Statistics and progress tracking

### Command Line Mode

```powershell
# Run specific APT campaign
.\MAGNETO_v3.ps1 -APTCampaign APT41

# Random attack mode
.\MAGNETO_v3.ps1 -AttackMode Random -TechniqueCount 10

# Clean up artifacts
.\MAGNETO_v3.ps1 -APTCampaign Lazarus -Cleanup

# List all techniques
.\MAGNETO_v3.ps1 -ListTechniques

# Get help
.\MAGNETO_v3.ps1 -Help
```

## APT Campaigns

MAGNETO includes pre-configured attack chains for major threat actors:

| Campaign | Description | Techniques |
|----------|-------------|------------|
| **APT41** | Shadow Harvest - Chinese espionage with Google Calendar C2 | 8 techniques |
| **Lazarus** | DEV#POPPER - North Korean financial targeting | 5 techniques |
| **APT29** | GRAPELOADER - Russian diplomatic espionage | 4 techniques |
| **StealthFalcon** | Project Raven - Middle East dissident targeting | 3 techniques |
| **FIN7** | Carbanak - Financial crime syndicate | 3 techniques |
| **APT28** | Fancy Bear - Russian military intelligence | 3 techniques |

## Auto-Update System

MAGNETO automatically checks for updates on launch. To manually check:

1. Click **[↻] CHECK UPDATES** button in GUI
2. Review changelog if update available
3. Click **Yes** to download and install
4. MAGNETO will automatically restart with new version

## Output and Reports

### HTML Reports

After execution, MAGNETO generates detailed HTML reports:
- MITRE ATT&CK tactics visualization
- Technique details with ATT&CK links
- Commands executed
- Detection methods
- Timestamps

### Log Files

- **MAGNETO_GUI_Logs/** - GUI application logs
- **MAGNETO_Logs/** - Technique execution logs

## Security Notes

- ⚠️ **Use only in authorized test environments**
- ⚠️ **Do not run on production systems**
- ⚠️ **Obtain proper authorization before testing**
- ✅ All techniques are logged
- ✅ Cleanup functionality available
- ✅ No data exfiltration (safe URLs used)

## Troubleshooting

### GUI won't launch

1. Check PowerShell version: `$PSVersionTable.PSVersion`
2. Ensure .NET Framework 4.5+ is installed
3. Run as Administrator
4. Check antivirus exclusions

### Techniques fail to execute

1. Verify Administrator privileges
2. Check Windows Defender/antivirus settings
3. Review logs in `MAGNETO_GUI_Logs/` folder

### Update check fails

1. Verify internet connection
2. Check GitHub is accessible: https://github.com/syedcode1/Magneto3
3. Verify firewall/proxy settings

## Support

For issues, questions, or contributions:
- **GitHub Issues:** https://github.com/syedcode1/Magneto3/issues
- **Repository:** https://github.com/syedcode1/Magneto3

## Disclaimer

MAGNETO is provided for **educational and authorized security testing purposes only**. Users are responsible for complying with all applicable laws and regulations. Unauthorized use of this tool against systems you do not own or have explicit permission to test is illegal.

The authors assume no liability for misuse or damage caused by this tool.

## License

This tool is provided as-is for cybersecurity research and testing.

## Credits

- **Author:** Syed Hasan Rizvi (syedcode1)
- **MITRE ATT&CK:** Framework by MITRE Corporation
- **Technique Research:** Real-world APT TTPs and threat intelligence

---

**Version 3.3.1** - October 2025

🔒 For authorized security testing only
