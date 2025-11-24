# MAGNETO v3 🎯

**Advanced APT Campaign & Attack Simulator**

![Version](https://img.shields.io/badge/version-3.3.1-brightgreen)
![MITRE ATT&CK](https://img.shields.io/badge/MITRE%20ATT%26CK-v16.1-red)
![PowerShell](https://img.shields.io/badge/PowerShell-5.0%2B-blue)
![License](https://img.shields.io/badge/license-Educational%20Use-orange)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)

> **Living Off The Land Attack Simulator** - 100% REAL | 100% SAFE

A sophisticated PowerShell-based threat simulation framework designed for cybersecurity professionals to test UEBA/SIEM systems, validate security controls, and simulate real-world APT campaigns using native Windows binaries (LOLBins).

<img width="2904" height="1422" alt="Screenshot 2025-10-29 153457" src="https://github.com/user-attachments/assets/c9863539-c327-413b-8a83-cc9fc57d28f7" />



--

> **Sample Report**
<img width="2501" height="1309" alt="Screenshot 2025-10-23 144604" src="https://github.com/user-attachments/assets/128de513-2af3-4e73-ad98-7b49e58d7993" />




---

## 🎯 **Overview**

MAGNETO v3 is an enterprise-grade attack simulation platform that enables security teams to:

- **Simulate Real APT Campaigns**: Execute pre-configured attack chains from major threat actors (APT41, Lazarus, APT29, APT28, FIN7, StealthFalcon)
- **Test SIEM/UEBA Systems**: Generate realistic attack telemetry to validate security monitoring solutions (Exabeam, Splunk, QRadar, etc.)
- **Validate Security Controls**: Map attacks to NIST 800-53 Rev 5 controls and verify defensive measures
- **Train Security Teams**: Provide hands-on experience with adversary tactics, techniques, and procedures (TTPs)
- **Assess Industry Risks**: Simulate threats specific to 10+ industry verticals (Financial, Healthcare, Energy, etc.)

**Key Philosophy**: All techniques use **native Windows binaries** (LOLBins) - no malware, no exploits, 100% safe for production-like environments.

---

## ⭐ **Key Features**

### 🎭 **APT Campaign Simulations**
Execute realistic attack chains from 7 major threat actors:

| APT Group | Campaign Name | Description | Techniques |
|-----------|---------------|-------------|------------|
| **APT41** | Shadow Harvest | Chinese state-sponsored espionage & financial gain | 8 TTPs |
| **Lazarus** | DEV#POPPER | North Korean financial targeting | 5 TTPs |
| **APT29** | GRAPELOADER | Russian SVR diplomatic espionage | 4 TTPs |
| **APT28** | Fancy Bear | Russian GRU military intelligence | 3 TTPs |
| **FIN7** | Carbanak | Financially motivated retail/POS targeting | 3 TTPs |
| **StealthFalcon** | Project Raven | Middle East dissident surveillance | 3 TTPs |

### 🎯 **MITRE ATT&CK Coverage**
- **55+ Techniques** spanning all 14 tactics
- **Real-world attribution** to known APT groups
- **Detailed descriptions** explaining why each technique matters
- **MITRE ATT&CK v16.1** compatible mappings

### 🏢 **Industry Vertical Scenarios**
Simulate threats specific to 10 industry sectors:
- Financial Services & Banking
- Healthcare & Hospitals
- Energy, Oil & Gas, Utilities
- Manufacturing & OT/ICS
- Technology & Software
- Government & Defense
- Education & Academia
- Retail & Hospitality
- Telecommunications
- Legal & Professional Services

### 🛡️ **NIST 800-53 Rev 5 Mapping**
- Automatic mapping of techniques to security controls
- Compliance reporting for federal/regulatory requirements
- Control validation testing

### 📊 **Comprehensive Reporting**
- **HTML Attack Reports** with visual MITRE ATT&CK heatmaps
- **Detailed logs** with command execution history
- **Success/failure tracking** for each technique
- **SIEM integration** for event correlation

### 🖥️ **Modern GUI Interface**
- Intuitive Windows Forms interface
- Real-time execution monitoring
- Visual status indicators with red alert flashing
- APT campaign browser with threat intelligence
- Technique filtering and selection
- SIEM logging status verification

---

## 🏗️ **Architecture**

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    MAGNETO v3 Platform                       │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴──────────────┐
                │                            │
         ┌──────▼───────┐           ┌───────▼────────┐
         │  GUI Layer   │           │   CLI Layer    │
         │ (WinForms)   │           │ (Direct Exec)  │
         └──────┬───────┘           └───────┬────────┘
                │                            │
                └─────────────┬──────────────┘
                              │
                   ┌──────────▼──────────┐
                   │   Core Engine       │
                   │ (MAGNETO_v3.ps1)    │
                   └──────────┬──────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
      ┌─────▼─────┐    ┌──────▼──────┐   ┌────▼─────┐
      │ Technique │    │   APT       │   │ Industry │
      │ Library   │    │ Campaigns   │   │ Verticals│
      │ (55 TTPs) │    │  (7 Groups) │   │  (10)    │
      └─────┬─────┘    └──────┬──────┘   └────┬─────┘
            │                 │                │
            └─────────────────┼────────────────┘
                              │
                   ┌──────────▼──────────┐
                   │   Execution Layer   │
                   │  (Native Windows    │
                   │     LOLBins)        │
                   └──────────┬──────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
      ┌─────▼─────┐    ┌──────▼──────┐   ┌────▼─────┐
      │  Logging  │    │  Reporting  │   │   SIEM   │
      │  System   │    │  (HTML/TXT) │   │  Events  │
      └───────────┘    └─────────────┘   └──────────┘
```

### Execution Flow

```
┌──────────────┐
│  User Input  │
│ (GUI or CLI) │
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│  Configuration Builder   │
│ - APT Campaign          │
│ - Industry Vertical     │
│ - Technique Filters     │
│ - Execution Mode        │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  Technique Selection     │
│ - Filter by tactics     │
│ - Filter by techniques  │
│ - APT-specific TTPs     │
│ - Randomization         │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│   Pre-Flight Validation  │
│ - Admin privileges      │
│ - Domain membership     │
│ - OS compatibility      │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  Technique Execution     │
│ (For each technique):   │
│ 1. Log start            │
│ 2. Execute action       │
│ 3. Capture output       │
│ 4. Record result        │
│ 5. Cleanup (optional)   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│   Results Processing     │
│ - Success/Fail count    │
│ - Skipped validation    │
│ - Attack timeline       │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│    Report Generation     │
│ - Text logs             │
│ - HTML reports          │
│ - MITRE heatmaps        │
│ - NIST mappings         │
└──────────────────────────┘
```

---

## 📋 **Requirements**

### System Requirements
- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.0 or higher
- **.NET Framework**: 4.5 or higher (for GUI)
- **Privileges**: Administrator rights recommended (some techniques require elevation)
- **Network**: Internet connectivity for certain techniques (optional)

### Optional Requirements
- **Active Directory**: For domain-specific techniques
- **SIEM System**: For event correlation and monitoring
- **NIST Module**: For compliance mapping (optional add-on)

---

## 🚀 **Installation**

### Quick Start

Option 1: Install via PowerShell
  1. Open PowerShell
  2. Navigate to directory where you like to install Magneto3 (e.g. D:\)
  3. Paste following command and hit Enter. (This will download Magneto and place it in a folder called "Magneto3")
```bash
$repo = "Magneto3"; $url = "https://github.com/syedcode1/Magneto3/archive/HEAD.zip"; $zip = "Magneto3.zip"; Write-Host "⬇️  Downloading $repo..." -ForegroundColor Cyan; Invoke-WebRequest -Uri $url -OutFile $zip; Write-Host "📦 Extracting files..." -ForegroundColor Cyan; $temp = "temp_$((Get-Random))"; Expand-Archive -Path $zip -DestinationPath $temp -Force; $extracted = Get-ChildItem -Path $temp -Directory | Select-Object -First 1; if (Test-Path $repo) { Remove-Item $repo -Recurse -Force }; Move-Item -Path $extracted.FullName -Destination $repo; Remove-Item $zip; Remove-Item $temp -Recurse -Force; Write-Host "✅ Done! Application downloaded to ./$repo" -ForegroundColor Green; Start-Sleep -Seconds 3;
```

Option 2: Install via Git (If you have Git installed)

  ```bash
  git clone https://github.com/syedcode1/Magneto3.git
  cd Magneto3
  ```

2. **Verify files**:
```
Magneto3/
├── Launch_MAGNETO_v3.bat      # Main launcher
├── MAGNETO_v3.ps1              # Core engine
├── MAGNETO_GUI_v3.ps1          # GUI interface
├── Logs/                       # Auto-created
│   ├── Attack Logs/
│   └── GUI Logs/
└── Reports/                    # Auto-created
```

3. **Launch**:
```batch
# Double-click or run:
Launch_MAGNETO_v3.bat
```

The launcher will:
- ✅ Check for administrator privileges
- ✅ Verify PowerShell version
- ✅ Validate required files
- ✅ Create folder structure
- ✅ Launch GUI interface

---

## 💻 **Usage**

### GUI Mode (Recommended)

1. **Launch the GUI**:
```batch
Launch_MAGNETO_v3.bat
```

2. **Select Execution Mode**:
   - **Random**: Execute random techniques
   - **Chain**: Execute attack chain
   - **All**: Run all available techniques
   - **Filtered**: Use tactic/technique filters

3. **Choose Configuration**:
   - **APT Campaign**: Select pre-configured threat actor
   - **Industry Vertical**: Simulate sector-specific threats
   - **Technique Count**: Number of techniques to execute
   - **Delay**: Time between techniques (stealth/speed)

4. **Execute**:
   - Click **EXECUTE ATTACK**
   - Monitor real-time execution status
   - View results in console output
   - Check generated logs and reports

### Command-Line Mode

#### Run APT Campaign
```powershell
.\MAGNETO_v3.ps1 -APTCampaign "APT41"
```

#### Random Attack with Filters
```powershell
.\MAGNETO_v3.ps1 -AttackMode Random -TechniqueCount 10 -ExcludeTactics "Impact"
```

#### Industry-Specific Simulation
```powershell
.\MAGNETO_v3.ps1 -IndustryVertical "Financial Services" -AttackMode Chain
```

#### Run All Techniques
```powershell
.\MAGNETO_v3.ps1 -RunAll -DelayBetweenTechniques 5
```

#### With Cleanup
```powershell
.\MAGNETO_v3.ps1 -APTCampaign "Lazarus" -Cleanup
```

### Advanced Options

#### List Available Items
```powershell
# List all techniques
.\MAGNETO_v3.ps1 -ListTechniques

# List MITRE tactics
.\MAGNETO_v3.ps1 -ListTactics

# List APT campaigns
.\MAGNETO_v3.ps1 -ListAPTCampaigns

# List industry verticals
.\MAGNETO_v3.ps1 -ListIndustryVerticals
```

#### Filtering Techniques
```powershell
# Include only specific tactics
.\MAGNETO_v3.ps1 -IncludeTactics "Discovery","Credential Access" -AttackMode Random

# Exclude specific techniques
.\MAGNETO_v3.ps1 -ExcludeTechniques "T1486","T1490" -AttackMode Chain

# Combine filters
.\MAGNETO_v3.ps1 -IncludeTactics "Persistence" -ExcludeTechniques "T1053.005"
```

#### Remote Execution
```powershell
$cred = Get-Credential
.\MAGNETO_v3.ps1 -RemoteComputer "TARGET-PC" -RemoteCredential $cred -APTCampaign "APT29"
```

#### WhatIf Mode (Dry Run)
```powershell
.\MAGNETO_v3.ps1 -APTCampaign "FIN7" -WhatIf
```

---

## 🎭 **APT Campaign Details**

### APT41 - Shadow Harvest Campaign
**Attribution**: Chinese Ministry of State Security (MSS)  
**Motivation**: State espionage + Financial gain  
**Target Sectors**: Technology, Healthcare, Telecommunications, Gaming

**Signature TTPs**:
- Network Service Discovery (T1049)
- Domain Account Discovery (T1087.001)
- Rundll32 Proxy Execution (T1218.011)
- Component Object Model Hijacking (T1546.015)
- Pass-the-Hash (T1550.002)
- SMB/Windows Admin Shares (T1021.002)
- C2 over Web Services (T1041)

**Known Campaigns**: Operation ShadowPad, CCleaner supply chain attack

---

### Lazarus Group - DEV#POPPER Campaign
**Attribution**: North Korean Reconnaissance General Bureau  
**Motivation**: Financial theft for regime funding  
**Target Sectors**: Banks, Cryptocurrency Exchanges, Defense

**Signature TTPs**:
- DLL Side-Loading (T1574.002)
- Scheduled Task Persistence (T1053.005)
- NTDS Dumping (T1003.003)
- SMB Lateral Movement (T1021.002)
- Archive Collection (T1560.002)

**Known Campaigns**: WannaCry, Bangladesh Bank heist ($81M), Sony Pictures hack

---

### APT29 - GRAPELOADER Campaign
**Attribution**: Russian Foreign Intelligence Service (SVR)  
**Motivation**: Long-term espionage  
**Target Sectors**: Government, Diplomatic, Defense, Healthcare

**Signature TTPs**:
- COM Hijacking for Persistence (T1546.015)
- Scheduled Tasks (T1053.005)
- Token Manipulation (T1134.001)
- File Deletion (T1070.004)

**Known Campaigns**: SolarWinds supply chain attack, DNC hack, COVID-19 vaccine research targeting

---

### APT28 - Fancy Bear Operations
**Attribution**: Russian Main Intelligence Directorate (GRU)  
**Motivation**: Military intelligence, political interference  
**Target Sectors**: Government, Military, Political campaigns, Media

**Signature TTPs**:
- PowerShell Execution (T1059.001)
- UAC Bypass (T1548.002)
- Remote Desktop Protocol (T1021.002)

**Known Campaigns**: DNC hack, NotPetya, French election interference, WADA targeting

---

### FIN7 - Carbanak Campaign
**Attribution**: Financially motivated cybercrime group  
**Motivation**: Financial theft  
**Target Sectors**: Retail POS, Restaurants, Hospitality

**Signature TTPs**:
- PowerShell Scripts (T1059.001)
- File Download (T1105)
- Windows Service Persistence (T1543.003)

**Known Campaigns**: $1+ billion stolen from retail/hospitality sector

---

### StealthFalcon - Project Raven
**Attribution**: UAE intelligence services  
**Motivation**: Political surveillance  
**Target Sectors**: Journalists, Activists, Dissidents

**Signature TTPs**:
- UAC Bypass (T1548.002)
- Obfuscation (T1027)
- Registry Modification (T1112)

**Known Campaigns**: Surveillance of Al Jazeera journalists, Middle East opposition figures

---

## 🏢 **Industry Vertical Simulations**

### Financial Services & Banking
**Risk Level**: Critical  
**Primary Threats**: Ransomware, Wire fraud, Cryptocurrency theft, Data breaches  
**Key APT Groups**: Lazarus, FIN7, APT38, Carbanak  
**Top Techniques**: Credential dumping, Pass-the-hash, SMB lateral movement, Data exfiltration

### Healthcare & Hospitals
**Risk Level**: Critical  
**Primary Threats**: Ransomware, Patient data theft, Service disruption  
**Key APT Groups**: APT41, FIN7, LockBit, ALPHV/BlackCat, Royal  
**Top Techniques**: Phishing, RDP compromise, Ransomware deployment, Data staging

### Energy & Utilities
**Risk Level**: Critical Infrastructure  
**Primary Threats**: ICS/SCADA compromise, Infrastructure damage, Service disruption  
**Key APT Groups**: APT33, APT28, APT29, Dragonfly  
**Top Techniques**: External exploitation, Network discovery, Lateral movement, Service stop

### Technology & Software
**Risk Level**: High  
**Primary Threats**: Supply chain attacks, Source code theft, Cloud compromise  
**Key APT Groups**: APT29, APT41, APT28  
**Top Techniques**: Supply chain compromise, Cloud credential access, API abuse

---

## 📊 **MITRE ATT&CK Tactics Coverage**

| Tactic | Techniques | Coverage |
|--------|------------|----------|
| **Reconnaissance** | 2 | Network scanning, Domain trust discovery |
| **Initial Access** | 3 | Phishing, External services, Valid accounts |
| **Execution** | 6 | PowerShell, WMI, Rundll32, Regsvr32, MSBuild |
| **Persistence** | 8 | Scheduled tasks, Registry run keys, Services, COM hijacking |
| **Privilege Escalation** | 5 | UAC bypass, Token manipulation, Process injection |
| **Defense Evasion** | 10 | Obfuscation, Timestomping, Indicator removal, DLL side-loading |
| **Credential Access** | 7 | LSASS dumping, SAM dumping, NTDS dumping, DCSync |
| **Discovery** | 9 | Account discovery, Domain trust, Network shares, Process discovery |
| **Lateral Movement** | 3 | RDP, SMB shares, Pass-the-hash |
| **Collection** | 4 | Data staging, Archive collection, Email collection |
| **Exfiltration** | 3 | HTTP exfil, DNS exfil, Scheduled transfers |
| **Impact** | 3 | Service stop, Data destruction, Ransomware simulation |
| **Command & Control** | 2 | Web service C2, DNS tunneling |

**Total**: 55+ techniques across 14 tactics

---

## 📁 **Output & Reporting**

### Log Files
Generated in `Logs/Attack Logs/`:
```
MAGNETO_AttackLog_20251028_143052.txt
MAGNETO_APT_APT41_20251028_143052.txt
```

**Contents**:
- Execution summary (success/fail/skipped counts)
- Detailed technique information
- MITRE ATT&CK mappings
- Command execution log
- Timestamps and metadata

### HTML Reports
Generated in `Reports/`:
```
MAGNETO_APT41_Report_20251028_143052.html
```

**Features**:
- Visual MITRE ATT&CK heatmap
- Technique execution timeline
- NIST 800-53 control mappings
- APT attribution and threat intelligence
- Success/failure statistics
- Recommendations for detection

### SIEM Integration
MAGNETO generates standard Windows event logs that can be ingested by:
- Exabeam UEBA
- Splunk Enterprise Security
- IBM QRadar
- Microsoft Sentinel
- Elastic SIEM
- LogRhythm

**Key Event IDs** to monitor:
- 4688 - Process Creation
- 4624/4625 - Logon Events
- 4672 - Special Privileges Assigned
- 4720 - User Account Created
- 5140/5145 - Network Share Access
- 7045 - Service Installation

---

## 🛡️ **NIST 800-53 Rev 5 Mappings**

MAGNETO techniques map to security controls:

| Control Family | Key Controls |
|----------------|--------------|
| **AC** (Access Control) | AC-2, AC-3, AC-6, AC-17 |
| **AU** (Audit & Accountability) | AU-2, AU-3, AU-6, AU-12 |
| **CM** (Configuration Management) | CM-2, CM-6, CM-7 |
| **IA** (Identification & Authentication) | IA-2, IA-4, IA-5 |
| **IR** (Incident Response) | IR-4, IR-5, IR-6 |
| **SC** (System & Communications Protection) | SC-7, SC-8, SC-18 |
| **SI** (System & Information Integrity) | SI-3, SI-4, SI-7 |

---

## 🔒 **Safety & Ethics**

### Safe by Design
✅ **No Exploitation**: Uses only native Windows binaries (LOLBins)  
✅ **No Malware**: Zero malicious payloads or exploits  
✅ **No Data Theft**: Simulates exfiltration without actual data transfer  
✅ **No Destruction**: Impact techniques are non-destructive simulations  
✅ **Full Control**: WhatIf mode, cleanup options, execution limits

### Intended Use
✔️ **Authorized security testing** in controlled environments  
✔️ **SIEM/UEBA validation** and tuning  
✔️ **Security team training** and education  
✔️ **Red team exercises** with proper authorization  
✔️ **Compliance testing** (NIST, SOC 2, PCI-DSS)

### Prohibited Use
❌ **Unauthorized access** to systems  
❌ **Production environments** without approval  
❌ **Malicious intent** or illegal activities  
❌ **Bypassing security controls** without authorization

---

## 📚 **Technical Details**

### Architecture Patterns
- **Modular Design**: Techniques are self-contained scriptblocks
- **Validation Framework**: Pre-flight checks before execution
- **Error Handling**: Graceful failures with detailed logging
- **Cleanup Mechanisms**: Optional artifact removal
- **Remote Execution**: PSRemoting support for distributed testing

### Technique Definition Schema
```powershell
@{
    ID = "T1049"
    Name = "Network Service Discovery"
    Tactic = "Discovery"
    Description = @{
        WhyTrack = "Reveals network topology and services"
        RealWorldUsage = "Used by APT41 in Shadow Harvest campaign"
    }
    APTGroup = "APT41"
    ValidationRequired = { Test-AdminPrivileges }
    Action = {
        # Technique implementation
        Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State
    }
    CleanupAction = {
        # Cleanup steps (if needed)
    }
}
```

### Extensibility
Add custom techniques by extending the `$techniques` array:
```powershell
$techniques += @{
    ID = "T1234"
    Name = "Custom Technique"
    Tactic = "Custom Tactic"
    # ... additional properties
}
```

---

## 🔄 **Versioning**

**Current Version**: 3.3.1  
**MITRE ATT&CK Compatibility**: v16.1  
**Release Date**: October 2025

### Version History
- **v3.3.1** - Added DNS exfiltration, HTTP POST exfil, bug fixes
- **v3.0** - Major rewrite with GUI, APT campaigns, industry verticals
- **v2.x** - Enhanced technique library, MITRE mappings
- **v1.x** - Initial release with core techniques

---

## 🤝 **Contributing**

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/NewTechnique`)
3. Commit changes (`git commit -m 'Add T1234 technique'`)
4. Push to branch (`git push origin feature/NewTechnique`)
5. Open a Pull Request

**Contribution Guidelines**:
- Follow existing technique schema
- Include MITRE ATT&CK mappings
- Add appropriate validation checks
- Document real-world APT usage
- Test thoroughly before submission

---

## 📄 **License**

This project is provided for **educational and authorized security testing purposes only**.

**Terms**:
- Must only be used in authorized testing environments
- Requires explicit permission from system owners
- Not for use in production systems without approval
- Author assumes no liability for misuse

---

## 👤 **Author**

**Syed Hasan Rizvi**  
Cybersecurity Professional | UEBA/SIEM Specialist

---

## 🙏 **Acknowledgments**

- **MITRE Corporation** - ATT&CK Framework
- **NIST** - 800-53 Security Controls
- **Security Community** - Threat intelligence and research
- **APT Research Teams** - Attribution and campaign analysis

---

## 📞 **Support**

- **Issues**: [GitHub Issues](https://github.com/syedcode1/Magneto3/issues)
- **Updates**: Check GUI "Check for Updates" button
- **Documentation**: [MITRE ATT&CK](https://attack.mitre.org/)

---

## ⚠️ **Disclaimer**

MAGNETO is a professional security testing tool intended for use by qualified cybersecurity professionals in authorized testing scenarios only. Unauthorized use of this tool may violate computer fraud and abuse laws. Users are solely responsible for compliance with all applicable laws and regulations. The author assumes no liability for misuse or damage caused by this software.

**USE AT YOUR OWN RISK. ALWAYS OBTAIN PROPER AUTHORIZATION BEFORE TESTING.**

---

## 🔗 **Quick Links**

- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [NIST 800-53 Rev 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [Exabeam UEBA Documentation](https://docs.exabeam.com/)
- [Microsoft Security Documentation](https://docs.microsoft.com/en-us/security/)

---

**Made with ❤️ for the cybersecurity community**

*Simulate. Detect. Defend.*
