# MAGNETO v3 - Advanced APT Campaign Simulator

**Version 3** - October 2025

## Overview

MAGNETO is a professional-grade **Living Off The Land (LOLBin)** attack simulation framework designed for security professionals, penetration testers, red teams, and SOC analysts. Built exclusively with native Windows binaries and PowerShell, MAGNETO provides a comprehensive suite of MITRE ATT&CK techniques without requiring any external dependencies, third-party tools, or additional installations.

## Why MAGNETO is Unique

### 🎯 100% Living Off The Land (LOLBin)

MAGNETO exclusively leverages **legitimate Windows binaries** and built-in system tools that exist natively on every Windows installation:

- **No external executables** - Uses only Microsoft-signed binaries (certutil.exe, rundll32.exe, regsvr32.exe, wmic.exe, etc.)
- **No third-party dependencies** - No Python, no .NET assemblies, no PowerShell modules to install
- **No compilation required** - Pure PowerShell scripts that run out-of-the-box
- **Authentic threat simulation** - Mirrors real-world APT tradecraft that evades traditional signature-based detection

### ⚡ Lightweight & Self-Contained

- **Zero installation footprint** - Extract and run immediately
- **< 2MB total size** - All scripts combined are smaller than most executables
- **Portable** - Run from USB, network share, or any directory without system modifications
- **No prerequisites** - Works on any Windows 10/11 system with PowerShell 5.0+

### 📊 Comprehensive Coverage

From basic reconnaissance to advanced persistence mechanisms:

- **Simple techniques** - Network discovery, file enumeration, process listing
- **Intermediate techniques** - Registry persistence, scheduled tasks, WMI queries
- **Advanced techniques** - Process injection patterns, token manipulation, alternate data streams
- **Complete attack chains** - Pre-configured APT campaign simulations with realistic TTPs

### 🔬 Enterprise-Grade Testing Platform

- **38 MITRE ATT&CK Techniques** - Covers 14 MITRE tactics from Initial Access to Impact
- **7 APT Campaign Simulations** - Emulates real-world threat actors (APT41, Lazarus, APT29, FIN7, APT28, StealthFalcon)
- **SIEM/EDR validation** - Test detection rules, correlation logic, and alert accuracy
- **Purple team exercises** - Safe, controlled environment for offensive/defensive collaboration
- **Compliance testing** - Validate security controls meet regulatory requirements

## Key Features

- ✅ **38 MITRE ATT&CK Techniques** - Full kill chain coverage across all tactics
- ✅ **7 APT Campaign Simulations** - Real-world threat actor profiles with attributed TTPs
- ✅ **MITRE ATT&CK Tactics Visualization** - Interactive HTML reports with detailed kill chain mapping
- ✅ **Enhanced Threat Intelligence** - Each technique includes APT attribution, detection methods, and UEBA analytics
- ✅ **Auto-Update System** - One-click updates directly from GitHub
- ✅ **Windows Forms GUI** - Professional interface with no external dependencies
- ✅ **Detailed Logging** - Timestamped execution logs with command-level detail
- ✅ **HTML Reporting** - Professional reports with MITRE ATT&CK links and technique metadata
- ✅ **Cleanup Functionality** - Remove artifacts and restore system state post-testing

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

**YOU MAY NEED TO ADD ANTIVIRUS EXCLUSIONS BEFORE RUNNING MAGNETO**

MAGNETO is a **legitimate cybersecurity testing tool** used by security professionals for authorized penetration testing and red team exercises. Antivirus software **will block MAGNETO** because it simulates real attack techniques.

### Common Error Messages

If you see these errors, you need to add exclusions:

```
❌ "This script contains malicious content and has been blocked by your antivirus software"
❌ "Heur.BZC.ZFV.Boxter.1069.A73FD735 detected"
❌ "Technique section is empty"
❌ "Error loading techniques"
```

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
