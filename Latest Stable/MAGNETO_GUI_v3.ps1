# MAGNETO GUI v3 - Advanced APT Campaign Simulator Interface
# Version 3 - October 2025
# Author: Enhanced for Cybersecurity Practitioners
# No external dependencies required - Pure PowerShell/Windows Forms

# Set execution policy for current process only (doesn't trigger AV like Bypass)
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction SilentlyContinue
} catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Version Information
$script:currentVersion = "3.3.1"
$script:versionCheckUrl = "https://raw.githubusercontent.com/syedcode1/Magneto3/main/version.json"
$script:githubRepoUrl = "https://github.com/syedcode1/Magneto3"

# Store the MAGNETO v3 script path
$script:magnetoScriptPath = Join-Path $PSScriptRoot "MAGNETO_v3.ps1"

# Import NIST Mapping Module
$script:nistMappingModulePath = Join-Path $PSScriptRoot "nist_mappings\nist_mapping_module.ps1"
$script:nistMappingsEnabled = $false
if (Test-Path $script:nistMappingModulePath) {
    try {
        . $script:nistMappingModulePath
        $script:nistMappingsEnabled = $true
        Write-Verbose "NIST mapping module loaded successfully"
    } catch {
        Write-Warning "Failed to load NIST mapping module: $($_.Exception.Message)"
    }
}

# Dark Theme Colors (Original color scheme)
$script:colorScheme = @{
    Background = [System.Drawing.Color]::FromArgb(15, 15, 15)
    Surface = [System.Drawing.Color]::FromArgb(25, 25, 25)
    Primary = [System.Drawing.Color]::FromArgb(0, 255, 0)
    Secondary = [System.Drawing.Color]::FromArgb(255, 0, 0)
    Accent = [System.Drawing.Color]::FromArgb(0, 200, 255)
    Text = [System.Drawing.Color]::FromArgb(220, 220, 220)
    TextDim = [System.Drawing.Color]::FromArgb(150, 150, 150)
    Border = [System.Drawing.Color]::FromArgb(50, 50, 50)
    Success = [System.Drawing.Color]::FromArgb(0, 255, 100)
    Warning = [System.Drawing.Color]::FromArgb(255, 200, 0)
    Error = [System.Drawing.Color]::FromArgb(255, 50, 50)
    APTHighlight = [System.Drawing.Color]::FromArgb(255, 0, 0)  # Red for APT
    FlashRed = [System.Drawing.Color]::FromArgb(255, 0, 0)  # Bright red for flashing
}

# Create Custom Font (Original fonts)
$script:fontRegular = New-Object System.Drawing.Font("Consolas", 9)
$script:fontBold = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$script:fontLarge = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
$script:fontTitle = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$script:fontFlash = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)  # Bold font for flashing

# Initialize global variables
$script:techniques = @()
$script:isRunning = $false
$script:process = $null
$script:job = $null
$script:jobTimer = $null
$script:executedTechniques = @()
$script:flashTimer = $null  # Timer for flashing effect
$script:flashState = $false  # Track flash state
$script:industryVerticals = @{}  # Industry vertical mappings
$script:originalStatusFont = $null  # Store original font
$script:originalStatusColor = $null  # Store original color
$script:completionHandled = $false  # Track if completion has been handled
$script:generatedLogFile = $null  # Track the generated log file path
$script:aptCampaigns = @{
    "None" = @{
        Name="Standard MAGNETO Mode"
        Description="Use standard technique selection"
        Techniques=@()
    }
    "APT41" = @{
        Name="Shadow Harvest"
        Description="Chinese espionage with Google Calendar C2"
        Techniques=@("T1049", "T1087.001", "T1218.011", "T1546.015", "T1055.100", "T1550.002", "T1021.002", "T1041")
        Overview="APT41 is a sophisticated Chinese state-sponsored threat group that conducts both espionage operations for the Chinese government and financially motivated cybercrime for personal gain."
        Targets="Technology companies, healthcare, telecommunications, video game industry, higher education, travel services, and news/media organizations worldwide"
        AttackMethods="Spear-phishing, watering hole attacks, supply chain compromise, exploiting vulnerabilities in internet-facing applications, custom malware deployment, and living-off-the-land techniques"
        Attribution="Chinese state-sponsored group linked to the Ministry of State Security (MSS)"
        KnownCampaigns="Operation ShadowPad (2017), CCleaner supply chain attack (2017), MESSAGETAP telecommunications espionage (2019)"
    }
    "Lazarus" = @{
        Name="DEV#POPPER"
        Description="North Korean financial targeting"
        Techniques=@("T1574.002", "T1053.005", "T1003.003", "T1021.002", "T1560.002")
        Overview="Lazarus Group is a highly sophisticated North Korean state-sponsored APT group known for conducting both espionage and financially motivated attacks to generate revenue for the North Korean regime."
        Targets="Financial institutions (banks, cryptocurrency exchanges), defense contractors, media organizations, and critical infrastructure across the globe"
        AttackMethods="Watering hole attacks, sophisticated social engineering, supply chain compromise, custom malware frameworks, cryptocurrency theft, destructive attacks, and SWIFT banking fraud"
        Attribution="North Korean government (Reconnaissance General Bureau)"
        KnownCampaigns="Sony Pictures hack (2014), Bangladesh Bank heist (2016), WannaCry ransomware (2017), multiple cryptocurrency exchange hacks"
    }
    "APT29" = @{
        Name="GRAPELOADER"
        Description="Russian diplomatic espionage"
        Techniques=@("T1546.015", "T1053.005", "T1134.001", "T1070.004")
        Overview="APT29 (Cozy Bear) is a highly capable Russian intelligence-gathering group associated with the Foreign Intelligence Service (SVR). Known for patient, stealthy long-term operations focused on intelligence collection."
        Targets="Government agencies, think tanks, diplomatic entities, defense contractors, energy sector, and healthcare organizations primarily in NATO countries"
        AttackMethods="Sophisticated spear-phishing campaigns, strategic web compromises, stealth malware (WellMess, WellMail), legitimate cloud services abuse, credential harvesting, and long-term persistent access"
        Attribution="Russian Foreign Intelligence Service (SVR)"
        KnownCampaigns="DNC hack (2016), SolarWinds supply chain attack (2020), COVID-19 vaccine research targeting (2020)"
    }
    "StealthFalcon" = @{
        Name="Project Raven"
        Description="Middle East dissident targeting"
        Techniques=@("T1548.002", "T1027", "T1112")
        Overview="StealthFalcon is a Middle Eastern threat group known for targeted surveillance operations against journalists, activists, and dissidents. The group uses sophisticated malware and infrastructure to maintain long-term access."
        Targets="Journalists, political dissidents, activists, human rights organizations, and opposition figures primarily in the Middle East region"
        AttackMethods="Spear-phishing with personalized lures, watering hole attacks, zero-day exploits, mobile device targeting, advanced stealth malware, and surveillance tools"
        Attribution="Linked to UAE intelligence services through Project Raven operations"
        KnownCampaigns="Project Raven (2019), targeting of Al Jazeera journalists, surveillance of Middle Eastern activists and opposition figures"
    }
    "FIN7" = @{
        Name="Carbanak"
        Description="Financial crime syndicate"
        Techniques=@("T1059.001", "T1105", "T1543.003")
        Overview="FIN7 is a financially motivated threat group that has been active since 2013, primarily targeting retail, restaurant, and hospitality sectors to steal payment card data and conduct financial fraud."
        Targets="Retail point-of-sale systems, restaurants, hospitality industry, financial institutions, and any organization processing credit card transactions"
        AttackMethods="Sophisticated phishing campaigns, malicious USB drops, point-of-sale malware, fileless malware techniques, legitimate tools abuse (PowerShell, WMI), and persistent backdoor deployment"
        Attribution="Financially motivated cybercrime group (not state-sponsored), allegedly based in Eastern Europe"
        KnownCampaigns="Carbanak banking malware campaign (2013-2018), targeting of numerous retail chains and restaurants, estimated $1+ billion in stolen funds"
    }
    "APT28" = @{
        Name="Fancy Bear"
        Description="Russian military intelligence"
        Techniques=@("T1059.001", "T1548.002", "T1021.002")
        Overview="APT28 (Fancy Bear) is a Russian military intelligence group associated with the GRU. Known for aggressive cyber operations, influence campaigns, and attacks against government, military, and security organizations."
        Targets="Government institutions, military organizations, security companies, media outlets, political campaigns, and anti-doping agencies worldwide"
        AttackMethods="Spear-phishing with credential harvesting, zero-day exploits, custom malware families (X-Agent, Sofacy), infrastructure targeting, and coordinated information operations"
        Attribution="Russian Main Intelligence Directorate (GRU) - Unit 26165"
        KnownCampaigns="DNC hack (2016), World Anti-Doping Agency (WADA) targeting (2016), French election interference (2017), NotPetya destructive attack (2017)"
    }
}

# Initialize Logging and Artifacts folders
$script:logPath = Join-Path $PSScriptRoot "Logs\GUI Logs"
if (-not (Test-Path $script:logPath)) {
    New-Item -ItemType Directory -Path $script:logPath -Force | Out-Null
}
$script:artifactsPath = Join-Path $PSScriptRoot "artifacts"
if (-not (Test-Path $script:artifactsPath)) {
    New-Item -ItemType Directory -Path $script:artifactsPath -Force | Out-Null
}

# Log rotation settings
$script:maxLogFiles = 10        # Keep last 10 log files
$script:maxLogSizeMB = 50        # Max size per log file in MB
$script:logFile = Join-Path $script:logPath "MAGNETO_GUI_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:verboseLogging = $true

# Perform log rotation on startup
function Invoke-LogRotation {
    param(
        [string]$LogDirectory = $script:logPath,
        [int]$MaxFiles = $script:maxLogFiles
    )

    try {
        # Get all log files sorted by creation time (oldest first)
        $logFiles = Get-ChildItem -Path $LogDirectory -Filter "MAGNETO_GUI_*.log" -ErrorAction SilentlyContinue |
                    Sort-Object CreationTime

        # Remove excess log files
        if ($logFiles.Count -gt $MaxFiles) {
            $filesToRemove = $logFiles | Select-Object -First ($logFiles.Count - $MaxFiles)
            foreach ($file in $filesToRemove) {
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                Write-Verbose "Rotated old log file: $($file.Name)"
            }
        }

        # Check size of existing logs and compress if needed
        foreach ($file in $logFiles | Select-Object -Last $MaxFiles) {
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            if ($sizeMB -gt $script:maxLogSizeMB) {
                # Archive large log files
                $archivePath = "$($file.FullName).archive"
                Move-Item -Path $file.FullName -Destination $archivePath -Force -ErrorAction SilentlyContinue
                Write-Verbose "Archived large log file: $($file.Name) ($sizeMB MB)"
            }
        }
    } catch {
        Write-Warning "Log rotation failed: $($_.Exception.Message)"
    }
}

# Run log rotation
Invoke-LogRotation

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$NoConsole
    )
    
    if (-not $script:verboseLogging -and $Level -eq "DEBUG") { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $script:logFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {}
    
    if ($script:verboseLogging -and $Level -eq "DEBUG") {
        Write-Debug $logEntry
    }
}

# Function to start flashing alert
function Start-FlashAlert {
    Write-Log "Starting flash alert" "INFO"
    
    # Store original state
    $script:originalStatusFont = $statusLabel.Font
    $script:originalStatusColor = $statusLabel.ForeColor
    
    # Create flash timer
    $script:flashTimer = New-Object System.Windows.Forms.Timer
    $script:flashTimer.Interval = 300  # Flash every 300ms
    $script:flashTimer.Add_Tick({
        if ($script:flashState) {
            $statusLabel.ForeColor = $script:colorScheme.FlashRed
            $statusLabel.Font = $script:fontFlash
            $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(50, 0, 0)  # Dark red background
            $script:flashState = $false
        } else {
            $statusLabel.ForeColor = [System.Drawing.Color]::Black
            $statusLabel.Font = $script:fontFlash
            $statusLabel.BackColor = $script:colorScheme.FlashRed  # Bright red background
            $script:flashState = $true
        }
        [System.Windows.Forms.Application]::DoEvents()
    })
    $script:flashTimer.Start()
    
    # Also flash the console panel border
    $consolePanel.ForeColor = $script:colorScheme.FlashRed
}

# Function to stop flashing alert
function Stop-FlashAlert {
    Write-Log "Stopping flash alert" "INFO"
    
    # Stop the flash timer if it exists
    if ($script:flashTimer) {
        try {
            $script:flashTimer.Stop()
            $script:flashTimer.Dispose()
        } catch {
            Write-Log "Error stopping flash timer: $_" "DEBUG"
        }
        $script:flashTimer = $null
    }
    
    # Restore original state
    try {
        if ($script:originalStatusFont) {
            $statusLabel.Font = $script:originalStatusFont
        } else {
            $statusLabel.Font = $script:fontBold
        }
        
        if ($script:originalStatusColor) {
            $statusLabel.ForeColor = $script:originalStatusColor
        } else {
            $statusLabel.ForeColor = $script:colorScheme.Accent
        }
        
        $statusLabel.BackColor = $script:colorScheme.Surface
        $consolePanel.ForeColor = $script:colorScheme.Primary
    } catch {
        Write-Log "Error restoring original state: $_" "DEBUG"
    }
    
    $script:flashState = $false
    Write-Log "Flash alert stopped successfully" "DEBUG"
}

# Log system information at startup
Write-Log "========================================" "INFO"
Write-Log "MAGNETO GUI v3 Starting" "INFO"
Write-Log "========================================" "INFO"
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)" "INFO"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)" "INFO"
Write-Log "Machine: $env:COMPUTERNAME" "INFO"
Write-Log "User: $env:USERNAME" "INFO"
Write-Log "Script Directory: $PSScriptRoot" "INFO"
Write-Log "Log File: $script:logFile" "INFO"

# Function to create styled button (Original style)
function New-StyledButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 120,
        [int]$Height = 35,
        [System.Drawing.Color]$BackColor = $script:colorScheme.Surface,
        [System.Drawing.Color]$ForeColor = $script:colorScheme.Text,
        [bool]$IsPrimary = $false
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.FlatStyle = 'Flat'
    $button.BackColor = if ($IsPrimary) { $script:colorScheme.Primary } else { $BackColor }
    $button.ForeColor = if ($IsPrimary) { $script:colorScheme.Background } else { $ForeColor }
    $button.Font = $script:fontBold
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = if ($IsPrimary) { $script:colorScheme.Primary } else { $script:colorScheme.Border }
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Add hover effect
    $button.Add_MouseEnter({
        if ($this.Enabled) {
            $this.BackColor = if ($this.Tag -eq "Primary") { 
                [System.Drawing.Color]::FromArgb(0, 200, 0) 
            } else { 
                [System.Drawing.Color]::FromArgb(40, 40, 40) 
            }
        }
    })
    
    $button.Add_MouseLeave({
        if ($this.Enabled) {
            $this.BackColor = if ($this.Tag -eq "Primary") { 
                $script:colorScheme.Primary 
            } else { 
                $script:colorScheme.Surface 
            }
        }
    })
    
    if ($IsPrimary) { $button.Tag = "Primary" }
    
    return $button
}

# Function to create styled panel (Original style)
function New-StyledPanel {
    param(
        [string]$Title,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )
    
    $panel = New-Object System.Windows.Forms.GroupBox
    $panel.Text = $Title
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.BackColor = $script:colorScheme.Surface
    $panel.ForeColor = $script:colorScheme.Primary
    $panel.Font = $script:fontBold
    $panel.FlatStyle = 'Flat'
    
    return $panel
}

# Create Main Form (Original size and settings)
$form = New-Object System.Windows.Forms.Form
$form.Text = "MAGNETO v3 - Advanced APT Campaign Simulator"
$form.Size = New-Object System.Drawing.Size(1420, 910)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $script:colorScheme.Background
$form.ForeColor = $script:colorScheme.Text
$form.Font = $script:fontRegular
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.SystemIcons]::Shield

# Title Banner (Replaced with PictureBox)
$imagePath = Join-Path $PSScriptRoot "artifacts\Magneto_Banner.png"

if (Test-Path $imagePath) {
    $bannerImage = New-Object System.Windows.Forms.PictureBox
    $bannerImage.Location = New-Object System.Drawing.Point(20, 10)
    $bannerImage.Size = New-Object System.Drawing.Size(1380, 100)
    $bannerImage.Image = [System.Drawing.Image]::FromFile($imagePath)
    # 'Zoom' scales the image to fit the control while preserving aspect ratio
    $bannerImage.SizeMode = 'Zoom'
    $form.Controls.Add($bannerImage)
}
else {
    # Fallback to a text label if the image is not found
    $bannerLabel = New-Object System.Windows.Forms.Label
    $bannerLabel.Text = "MAGNETO v.3`nBanner Image Not Found in 'artifacts' folder"
    $bannerLabel.Location = New-Object System.Drawing.Point(20, 10)
    $bannerLabel.Size = New-Object System.Drawing.Size(1380, 100)
    $bannerLabel.ForeColor = $script:colorScheme.Warning
    $bannerLabel.Font = $script:fontTitle
    $bannerLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($bannerLabel)
}

# Status Bar
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "READY | Breach. Evade. Exfil. All Native. All Stealth."
$statusLabel.Location = New-Object System.Drawing.Point(20, 110)
$statusLabel.Size = New-Object System.Drawing.Size(1380, 25)
$statusLabel.ForeColor = $script:colorScheme.Accent
$statusLabel.Font = $script:fontBold
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusLabel.BackColor = $script:colorScheme.Surface
$statusLabel.BorderStyle = 'FixedSingle'
$form.Controls.Add($statusLabel)

# Left Panel - Configuration (Original layout)
$configPanel = New-StyledPanel -Title "[CONFIG] CONFIGURATION" -X 20 -Y 150 -Width 420 -Height 640
$form.Controls.Add($configPanel)

# APT Campaign Selection (NEW - Added above mode selection)
$aptLabel = New-Object System.Windows.Forms.Label
$aptLabel.Text = "APT CAMPAIGN:"
$aptLabel.Location = New-Object System.Drawing.Point(15, 25)
$aptLabel.Size = New-Object System.Drawing.Size(120, 20)
$aptLabel.ForeColor = $script:colorScheme.APTHighlight
$configPanel.Controls.Add($aptLabel)

$aptCombo = New-Object System.Windows.Forms.ComboBox
$aptCombo.Location = New-Object System.Drawing.Point(140, 23)
$aptCombo.Size = New-Object System.Drawing.Size(240, 25)
$aptCombo.BackColor = $script:colorScheme.Background
$aptCombo.ForeColor = $script:colorScheme.APTHighlight
$aptCombo.FlatStyle = 'Flat'
$aptCombo.DropDownStyle = 'DropDownList'
$script:aptCampaigns.Keys | ForEach-Object {
    $null = $aptCombo.Items.Add($_)
}
$aptCombo.SelectedItem = "None"
$configPanel.Controls.Add($aptCombo)

# Industry Vertical Selection
$verticalLabel = New-Object System.Windows.Forms.Label
$verticalLabel.Text = "INDUSTRY VERTICAL:"
$verticalLabel.Location = New-Object System.Drawing.Point(15, 55)
$verticalLabel.Size = New-Object System.Drawing.Size(120, 20)
$verticalLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100)
$configPanel.Controls.Add($verticalLabel)

$verticalCombo = New-Object System.Windows.Forms.ComboBox
$verticalCombo.Location = New-Object System.Drawing.Point(140, 53)
$verticalCombo.Size = New-Object System.Drawing.Size(240, 25)
$verticalCombo.BackColor = $script:colorScheme.Background
$verticalCombo.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100)
$verticalCombo.FlatStyle = 'Flat'
$verticalCombo.DropDownStyle = 'DropDownList'
$null = $verticalCombo.Items.Add("None")
$null = $verticalCombo.Items.Add("Financial Services")
$null = $verticalCombo.Items.Add("Healthcare")
$null = $verticalCombo.Items.Add("Energy & Utilities")
$null = $verticalCombo.Items.Add("Manufacturing & OT")
$null = $verticalCombo.Items.Add("Technology")
$null = $verticalCombo.Items.Add("Government")
$null = $verticalCombo.Items.Add("Education & Research")
$null = $verticalCombo.Items.Add("Retail & Hospitality")
$null = $verticalCombo.Items.Add("Telecommunications")
$null = $verticalCombo.Items.Add("Transportation")
$verticalCombo.SelectedItem = "None"
$configPanel.Controls.Add($verticalCombo)

# Mode Selection
$modeLabel = New-Object System.Windows.Forms.Label
$modeLabel.Text = "ATTACK MODE:"
$modeLabel.Location = New-Object System.Drawing.Point(15, 85)
$modeLabel.Size = New-Object System.Drawing.Size(120, 20)
$modeLabel.ForeColor = $script:colorScheme.Text
$configPanel.Controls.Add($modeLabel)

$modeCombo = New-Object System.Windows.Forms.ComboBox
$modeCombo.Location = New-Object System.Drawing.Point(140, 83)
$modeCombo.Size = New-Object System.Drawing.Size(240, 25)
$modeCombo.BackColor = $script:colorScheme.Background
$modeCombo.ForeColor = $script:colorScheme.Primary
$modeCombo.FlatStyle = 'Flat'
$modeCombo.DropDownStyle = 'DropDownList'
$modeCombo.Items.AddRange(@(
    "Random - Chaos Mode",
    "Chain - Attack Lifecycle", 
    "Specific Techniques Only",
    "Run All Techniques",
    "Run All in Selected Tactics"
))
$modeCombo.SelectedIndex = 0
$configPanel.Controls.Add($modeCombo)

# Technique Count
$countLabel = New-Object System.Windows.Forms.Label
$countLabel.Text = "TECHNIQUE COUNT:"
$countLabel.Location = New-Object System.Drawing.Point(15, 120)
$countLabel.Size = New-Object System.Drawing.Size(140, 20)
$countLabel.ForeColor = $script:colorScheme.Text
$countLabel.BackColor = [System.Drawing.Color]::Transparent
$configPanel.Controls.Add($countLabel)

$countUpDown = New-Object System.Windows.Forms.NumericUpDown
$countUpDown.Location = New-Object System.Drawing.Point(160, 118)
$countUpDown.Size = New-Object System.Drawing.Size(80, 25)
$countUpDown.BackColor = $script:colorScheme.Background
$countUpDown.ForeColor = $script:colorScheme.Primary
$countUpDown.Minimum = 1
$countUpDown.Maximum = 50
$countUpDown.Value = 7
$configPanel.Controls.Add($countUpDown)

# Delay Between Techniques
$delayLabel = New-Object System.Windows.Forms.Label
$delayLabel.Text = "DELAY:"
$delayLabel.Location = New-Object System.Drawing.Point(250, 120)
$delayLabel.Size = New-Object System.Drawing.Size(70, 20)
$delayLabel.ForeColor = $script:colorScheme.Text
$delayLabel.BackColor = [System.Drawing.Color]::Transparent
$configPanel.Controls.Add($delayLabel)

$delayUpDown = New-Object System.Windows.Forms.NumericUpDown
$delayUpDown.Location = New-Object System.Drawing.Point(320, 118)
$delayUpDown.Size = New-Object System.Drawing.Size(60, 25)
$delayUpDown.BackColor = $script:colorScheme.Background
$delayUpDown.ForeColor = $script:colorScheme.Primary
$delayUpDown.Minimum = 0
$delayUpDown.Maximum = 60
$delayUpDown.Value = 2
$configPanel.Controls.Add($delayUpDown)

# Cleanup Checkbox
$cleanupCheck = New-Object System.Windows.Forms.CheckBox
$cleanupCheck.Text = "Enable Cleanup (Remove Artifacts)"
$cleanupCheck.Location = New-Object System.Drawing.Point(15, 155)
$cleanupCheck.Size = New-Object System.Drawing.Size(300, 25)
$cleanupCheck.ForeColor = $script:colorScheme.Warning
$cleanupCheck.Checked = $true
$cleanupCheck.Add_CheckedChanged({
    if (-not $cleanupCheck.Checked) {
        [System.Windows.Forms.MessageBox]::Show(
            "WARNING: Disabling cleanup will leave simulated attack artifacts on the target system.`n`n" +
            "This is NOT RECOMMENDED as it may:`n" +
            "  • Leave malicious-looking files and registry keys`n" +
            "  • Trigger security alerts`n" +
            "  • Create confusion during forensic analysis`n" +
            "  • Violate security policies`n`n" +
            "Only disable cleanup if you have a specific reason and understand the implications.",
            "Cleanup Disabled - Security Warning",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})
$configPanel.Controls.Add($cleanupCheck)

# Admin Mode Indicator
$adminLabel = New-Object System.Windows.Forms.Label
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminLabel.Text = if ($isAdmin) { "[OK] ADMIN MODE ACTIVE" } else { "[!] LIMITED MODE (Non-Admin)" }
$adminLabel.Location = New-Object System.Drawing.Point(15, 190)
$adminLabel.Size = New-Object System.Drawing.Size(250, 25)
$adminLabel.ForeColor = if ($isAdmin) { $script:colorScheme.Success } else { $script:colorScheme.Warning }
$adminLabel.Font = $script:fontBold
$configPanel.Controls.Add($adminLabel)

# Domain Status
$domainLabel = New-Object System.Windows.Forms.Label
$isDomain = ($env:USERDOMAIN -ne $env:COMPUTERNAME)
$domainLabel.Text = if ($isDomain) { "[OK] DOMAIN JOINED" } else { "[--] STANDALONE SYSTEM" }
$domainLabel.Location = New-Object System.Drawing.Point(15, 215)
$domainLabel.Size = New-Object System.Drawing.Size(250, 25)
$domainLabel.ForeColor = if ($isDomain) { $script:colorScheme.Success } else { $script:colorScheme.TextDim }
$domainLabel.Font = $script:fontBold
$configPanel.Controls.Add($domainLabel)

# Remote Execution Section
$remoteLabel = New-Object System.Windows.Forms.Label
$remoteLabel.Text = "REMOTE EXECUTION:"
$remoteLabel.Location = New-Object System.Drawing.Point(15, 245)
$remoteLabel.Size = New-Object System.Drawing.Size(150, 20)
$remoteLabel.ForeColor = $script:colorScheme.Accent
$remoteLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$remoteLabel.BackColor = [System.Drawing.Color]::Transparent
$configPanel.Controls.Add($remoteLabel)

# Remote Execution Checkbox
$remoteCheck = New-Object System.Windows.Forms.CheckBox
$remoteCheck.Text = "Execute on Remote Computer"
$remoteCheck.Location = New-Object System.Drawing.Point(15, 270)
$remoteCheck.Size = New-Object System.Drawing.Size(250, 25)
$remoteCheck.ForeColor = $script:colorScheme.Text
$remoteCheck.Checked = $false
$configPanel.Controls.Add($remoteCheck)

# Target Computer Label
$targetLabel = New-Object System.Windows.Forms.Label
$targetLabel.Text = "Target:"
$targetLabel.Location = New-Object System.Drawing.Point(30, 300)
$targetLabel.Size = New-Object System.Drawing.Size(50, 20)
$targetLabel.ForeColor = $script:colorScheme.Text
$targetLabel.BackColor = [System.Drawing.Color]::Transparent
$targetLabel.Enabled = $false
$configPanel.Controls.Add($targetLabel)

# Target Computer TextBox
$targetComputer = New-Object System.Windows.Forms.TextBox
$targetComputer.Location = New-Object System.Drawing.Point(85, 298)
$targetComputer.Size = New-Object System.Drawing.Size(295, 25)
$targetComputer.BackColor = $script:colorScheme.Background
$targetComputer.ForeColor = $script:colorScheme.Primary
$targetComputer.Text = ""
$targetComputer.Enabled = $false
$configPanel.Controls.Add($targetComputer)

# Test Connection Button
$testConnBtn = New-Object System.Windows.Forms.Button
$testConnBtn.Text = "Test Connection"
$testConnBtn.Location = New-Object System.Drawing.Point(30, 330)
$testConnBtn.Size = New-Object System.Drawing.Size(130, 28)
$testConnBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 80, 120)
$testConnBtn.ForeColor = [System.Drawing.Color]::White
$testConnBtn.FlatStyle = 'Flat'
$testConnBtn.Enabled = $false
$configPanel.Controls.Add($testConnBtn)

# Use Alternate Credentials Checkbox
$altCredsCheck = New-Object System.Windows.Forms.CheckBox
$altCredsCheck.Text = "Alternate Credentials"
$altCredsCheck.Location = New-Object System.Drawing.Point(170, 333)
$altCredsCheck.Size = New-Object System.Drawing.Size(220, 25)
$altCredsCheck.ForeColor = $script:colorScheme.Text
$altCredsCheck.Checked = $false
$altCredsCheck.Enabled = $false
$configPanel.Controls.Add($altCredsCheck)

# Store remote credential
$script:remoteCredential = $null
$script:remoteConnectionValid = $false

# Tactic Filter Section
$tacticFilterLabel = New-Object System.Windows.Forms.Label
$tacticFilterLabel.Text = "TACTIC FILTERS:"
$tacticFilterLabel.Location = New-Object System.Drawing.Point(15, 375)
$tacticFilterLabel.Size = New-Object System.Drawing.Size(150, 20)
$tacticFilterLabel.ForeColor = $script:colorScheme.Accent
$tacticFilterLabel.Font = $script:fontBold
$configPanel.Controls.Add($tacticFilterLabel)

# Include/Exclude Radio Buttons
$includeRadio = New-Object System.Windows.Forms.RadioButton
$includeRadio.Text = "Include"
$includeRadio.Location = New-Object System.Drawing.Point(170, 375)
$includeRadio.Size = New-Object System.Drawing.Size(80, 20)
$includeRadio.ForeColor = $script:colorScheme.Success
$includeRadio.Checked = $false
$configPanel.Controls.Add($includeRadio)

$excludeRadio = New-Object System.Windows.Forms.RadioButton
$excludeRadio.Text = "Exclude"
$excludeRadio.Location = New-Object System.Drawing.Point(250, 375)
$excludeRadio.Size = New-Object System.Drawing.Size(80, 20)
$excludeRadio.ForeColor = $script:colorScheme.Error
$excludeRadio.Checked = $true
$configPanel.Controls.Add($excludeRadio)

# Tactic Checklist
$tacticChecklist = New-Object System.Windows.Forms.CheckedListBox
$tacticChecklist.Location = New-Object System.Drawing.Point(15, 400)
$tacticChecklist.Size = New-Object System.Drawing.Size(365, 180)
$tacticChecklist.BackColor = $script:colorScheme.Background
$tacticChecklist.ForeColor = $script:colorScheme.Text
$tacticChecklist.BorderStyle = 'FixedSingle'
$tacticChecklist.CheckOnClick = $true
$tacticChecklist.Items.AddRange(@(
    "Discovery",
    "Execution", 
    "Persistence",
    "Privilege Escalation",
    "Defense Evasion",
    "Credential Access",
    "Lateral Movement",
    "Command and Control",
    "Exfiltration"
))
$configPanel.Controls.Add($tacticChecklist)

# Middle Panel - Technique Selection
$techniquePanel = New-StyledPanel -Title "[TARGET] TECHNIQUE SELECTION" -X 460 -Y 150 -Width 480 -Height 350
$form.Controls.Add($techniquePanel)

# Search Box
$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "SEARCH:"
$searchLabel.Location = New-Object System.Drawing.Point(15, 30)
$searchLabel.Size = New-Object System.Drawing.Size(60, 20)
$searchLabel.ForeColor = $script:colorScheme.Text
$techniquePanel.Controls.Add($searchLabel)

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(80, 28)
$searchBox.Size = New-Object System.Drawing.Size(250, 25)
$searchBox.BackColor = $script:colorScheme.Background
$searchBox.ForeColor = $script:colorScheme.Primary
$searchBox.BorderStyle = 'FixedSingle'
$techniquePanel.Controls.Add($searchBox)

# Select All/None Buttons
$selectAllBtn = New-StyledButton -Text "SELECT ALL" -X 340 -Y 25 -Width 70 -Height 28
$techniquePanel.Controls.Add($selectAllBtn)

$selectNoneBtn = New-StyledButton -Text "CLEAR" -X 415 -Y 25 -Width 70 -Height 28
$techniquePanel.Controls.Add($selectNoneBtn)

# Technique List with checkboxes
$techniqueList = New-Object System.Windows.Forms.CheckedListBox
$techniqueList.Location = New-Object System.Drawing.Point(15, 60)
$techniqueList.Size = New-Object System.Drawing.Size(450, 275)
$techniqueList.BackColor = $script:colorScheme.Background
$techniqueList.ForeColor = $script:colorScheme.Text
$techniqueList.BorderStyle = 'FixedSingle'
$techniqueList.CheckOnClick = $true
$techniqueList.Font = New-Object System.Drawing.Font("Consolas", 8)
$techniquePanel.Controls.Add($techniqueList)

# Right Panel - Statistics
$statsPanel = New-StyledPanel -Title "[STATS] STATISTICS" -X 960 -Y 150 -Width 420 -Height 350
$form.Controls.Add($statsPanel)

# Stats Display
$statsText = New-Object System.Windows.Forms.TextBox
$statsText.Location = New-Object System.Drawing.Point(15, 30)
$statsText.Size = New-Object System.Drawing.Size(390, 305)
$statsText.Multiline = $true
$statsText.ScrollBars = 'Vertical'
$statsText.ReadOnly = $true
$statsText.BackColor = $script:colorScheme.Background
$statsText.ForeColor = $script:colorScheme.Primary
$statsText.Font = New-Object System.Drawing.Font("Consolas", 9)
$statsText.BorderStyle = 'FixedSingle'
$statsText.Text = @"
================================
     SYSTEM ANALYSIS COMPLETE     
================================

> AVAILABLE TECHNIQUES: Loading...
> ADMIN REQUIRED: Loading...
> DOMAIN REQUIRED: Loading...

================================
TACTIC BREAKDOWN:
================================

Loading tactic statistics...

================================
CURRENT SELECTION:
================================

No techniques selected

================================
"@
$statsPanel.Controls.Add($statsText)

# Console Output Panel (spans middle and right columns)
$consolePanel = New-StyledPanel -Title "[CONSOLE] OUTPUT" -X 460 -Y 510 -Width 920 -Height 280
$form.Controls.Add($consolePanel)

$consoleOutput = New-Object System.Windows.Forms.TextBox
$consoleOutput.Location = New-Object System.Drawing.Point(15, 25)
$consoleOutput.Size = New-Object System.Drawing.Size(890, 240)
$consoleOutput.Multiline = $true
$consoleOutput.ScrollBars = 'Both'
$consoleOutput.ReadOnly = $true
$consoleOutput.BackColor = [System.Drawing.Color]::Black
$consoleOutput.ForeColor = $script:colorScheme.Primary
$consoleOutput.Font = New-Object System.Drawing.Font("Consolas", 9)
$consoleOutput.BorderStyle = 'FixedSingle'
$consoleOutput.WordWrap = $false
$consolePanel.Controls.Add($consoleOutput)

# Control Buttons Panel
$controlPanel = New-Object System.Windows.Forms.Panel
$controlPanel.Location = New-Object System.Drawing.Point(20, 805)
$controlPanel.Size = New-Object System.Drawing.Size(1380, 50)
$controlPanel.BackColor = $script:colorScheme.Surface
$form.Controls.Add($controlPanel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 10)
$progressBar.Size = New-Object System.Drawing.Size(500, 30)
$progressBar.Style = 'Continuous'
$progressBar.ForeColor = $script:colorScheme.Primary
$progressBar.BackColor = $script:colorScheme.Background
$controlPanel.Controls.Add($progressBar)

# Execute Button
$executeBtn = New-StyledButton -Text "[!] EXECUTE ATTACK" -X 530 -Y 7 -Width 180 -Height 36 -IsPrimary $true
$controlPanel.Controls.Add($executeBtn)

# Stop Button
$stopBtn = New-StyledButton -Text "[X] STOP" -X 720 -Y 7 -Width 100 -Height 36
$stopBtn.BackColor = $script:colorScheme.Error
$stopBtn.Enabled = $false
$controlPanel.Controls.Add($stopBtn)

# View Log Button
$viewLogBtn = New-StyledButton -Text "[?] VIEW LOG" -X 830 -Y 7 -Width 100 -Height 36
$controlPanel.Controls.Add($viewLogBtn)

# SIEM Logging Button
$siemBtn = New-StyledButton -Text "SIEM LOGGING" -X 940 -Y 7 -Width 130 -Height 36
$siemBtn.BackColor = [System.Drawing.Color]::FromArgb(40, 80, 40)
$controlPanel.Controls.Add($siemBtn)

# Check for Updates Button
$updateBtn = New-StyledButton -Text "[+] CHECK UPDATES" -X 1080 -Y 7 -Width 150 -Height 36
$updateBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 80, 120)
$controlPanel.Controls.Add($updateBtn)

# Exit Button
$exitBtn = New-StyledButton -Text "EXIT" -X 1240 -Y 7 -Width 100 -Height 36
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(80, 0, 0)
$controlPanel.Controls.Add($exitBtn)

# Helper Functions
function Write-Console {
    param(
        [string]$Message,
        [string]$Color = "Default"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Color) {
        "Success" { "[+]" }
        "Error" { "[!]" }
        "Warning" { "[*]" }
        "Info" { "[>]" }
        "APT" { "[APT]" }
        "Attack" { "[ATTACK]" }
        Default { "[>]" }
    }
    
    $logLevel = switch ($Color) {
        "Success" { "SUCCESS" }
        "Error" { "ERROR" }
        "Warning" { "WARN" }
        "Info" { "INFO" }
        "APT" { "APT" }
        "Attack" { "ATTACK" }
        Default { "INFO" }
    }
    
    if ($Color -eq "Attack") {
        $originalColor = $consoleOutput.ForeColor
        $consoleOutput.ForeColor = $script:colorScheme.FlashRed
        $consoleMessage = "[$timestamp] $prefix $Message`r`n"
        $consoleOutput.AppendText($consoleMessage)
        $consoleOutput.ForeColor = $originalColor
    } else {
        $consoleMessage = "[$timestamp] $prefix $Message`r`n"
        $consoleOutput.AppendText($consoleMessage)
    }
    
    $consoleOutput.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    
    Write-Log "CONSOLE: $Message" $logLevel
}

function Test-SiemLogging {
    # Check PowerShell Module Logging
    $moduleLogging = $false
    try {
        $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -ErrorAction SilentlyContinue
        if ($key -and $key.EnableModuleLogging -eq 1) {
            $moduleLogging = $true
        }
    } catch {}

    # Check PowerShell Script Block Logging
    $scriptBlockLogging = $false
    try {
        $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -ErrorAction SilentlyContinue
        if ($key -and $key.EnableScriptBlockLogging -eq 1) {
            $scriptBlockLogging = $true
        }
    } catch {}

    # Check Command Line in Process Creation
    $commandLineLogging = $false
    try {
        $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -ErrorAction SilentlyContinue
        if ($key -and $key.ProcessCreationIncludeCmdLine_Enabled -eq 1) {
            $commandLineLogging = $true
        }
    } catch {}

    # Check Process Creation Auditing
    $processAuditing = $false
    try {
        $auditPolicy = auditpol /get /subcategory:"Process Creation" 2>&1
        if ($auditPolicy -match "Success") {
            $processAuditing = $true
        }
    } catch {}

    return [PSCustomObject]@{
        ModuleLogging = $moduleLogging
        ScriptBlockLogging = $scriptBlockLogging
        CommandLineLogging = $commandLineLogging
        ProcessAuditing = $processAuditing
        AllEnabled = ($moduleLogging -and $scriptBlockLogging -and $commandLineLogging -and $processAuditing)
    }
}

function Enable-SiemLogging {
    try {
        Write-Log "Attempting to enable SIEM logging..." "INFO"

        # Enable PowerShell Module Logging
        $modulePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
        if (-not (Test-Path $modulePath)) {
            New-Item -Path $modulePath -Force | Out-Null
        }
        Set-ItemProperty -Path $modulePath -Name "EnableModuleLogging" -Value 1 -Type DWord -Force

        $moduleNamesPath = "$modulePath\ModuleNames"
        if (-not (Test-Path $moduleNamesPath)) {
            New-Item -Path $moduleNamesPath -Force | Out-Null
        }
        Set-ItemProperty -Path $moduleNamesPath -Name "*" -Value "*" -Type String -Force

        # Enable PowerShell Script Block Logging
        $scriptBlockPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        if (-not (Test-Path $scriptBlockPath)) {
            New-Item -Path $scriptBlockPath -Force | Out-Null
        }
        Set-ItemProperty -Path $scriptBlockPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWord -Force

        # Enable Command Line in Process Creation
        $auditPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
        if (-not (Test-Path $auditPath)) {
            New-Item -Path $auditPath -Force | Out-Null
        }
        Set-ItemProperty -Path $auditPath -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -Type DWord -Force

        # Enable Process Creation Auditing
        $auditResult = auditpol /set /subcategory:"Process Creation" /success:enable 2>&1

        Write-Log "SIEM logging enabled successfully" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to enable SIEM logging: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-RemoteConnection {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        Write-Log "Testing connection to $ComputerName..." "INFO"

        $params = @{
            ComputerName = $ComputerName
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $params.Credential = $Credential
        }

        # Test basic connectivity
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            return @{
                Success = $false
                Error = "Cannot ping $ComputerName. Check network connectivity."
                Details = $null
            }
        }

        # Test WinRM/PS Remoting
        $session = $null
        try {
            $session = New-PSSession @params

            # Test admin rights
            $isAdmin = Invoke-Command -Session $session -ScriptBlock {
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            }

            # Get system info
            $sysInfo = Invoke-Command -Session $session -ScriptBlock {
                @{
                    ComputerName = $env:COMPUTERNAME
                    OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
                    PSVersion = $PSVersionTable.PSVersion.ToString()
                }
            }

            Remove-PSSession -Session $session

            return @{
                Success = $true
                IsAdmin = $isAdmin
                SystemInfo = $sysInfo
                Error = $null
            }

        } catch {
            if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
            throw
        }

    } catch {
        $errorMsg = $_.Exception.Message

        if ($errorMsg -match "WinRM") {
            $errorMsg = "WinRM not enabled on $ComputerName. Run 'Enable-PSRemoting -Force' on the target."
        } elseif ($errorMsg -match "Access is denied") {
            $errorMsg = "Access denied. You need Administrator privileges on $ComputerName."
        } elseif ($errorMsg -match "credentials") {
            $errorMsg = "Authentication failed. Check username and password."
        }

        return @{
            Success = $false
            Error = $errorMsg
            Details = $_.Exception
        }
    }
}

function Test-RemoteSiemLogging {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        $params = @{
            ComputerName = $ComputerName
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $params.Credential = $Credential
        }

        $result = Invoke-Command @params -ScriptBlock {
            # Check PowerShell Module Logging
            $moduleLogging = $false
            try {
                $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -ErrorAction SilentlyContinue
                if ($key -and $key.EnableModuleLogging -eq 1) {
                    $moduleLogging = $true
                }
            } catch {}

            # Check PowerShell Script Block Logging
            $scriptBlockLogging = $false
            try {
                $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -ErrorAction SilentlyContinue
                if ($key -and $key.EnableScriptBlockLogging -eq 1) {
                    $scriptBlockLogging = $true
                }
            } catch {}

            # Check Command Line in Process Creation
            $commandLineLogging = $false
            try {
                $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -ErrorAction SilentlyContinue
                if ($key -and $key.ProcessCreationIncludeCmdLine_Enabled -eq 1) {
                    $commandLineLogging = $true
                }
            } catch {}

            # Check Process Creation Auditing
            $processAuditing = $false
            try {
                $auditPolicy = auditpol /get /subcategory:"Process Creation" 2>&1
                if ($auditPolicy -match "Success") {
                    $processAuditing = $true
                }
            } catch {}

            return [PSCustomObject]@{
                ModuleLogging = $moduleLogging
                ScriptBlockLogging = $scriptBlockLogging
                CommandLineLogging = $commandLineLogging
                ProcessAuditing = $processAuditing
                AllEnabled = ($moduleLogging -and $scriptBlockLogging -and $commandLineLogging -and $processAuditing)
            }
        }

        return $result

    } catch {
        Write-Log "Failed to check remote SIEM logging: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Load-Techniques {
    param([string]$ScriptPath)

    Write-Log "Load-Techniques called with path: $ScriptPath" "INFO"

    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Script file not found: $ScriptPath" "ERROR"
        Write-Console "Script file not found: $ScriptPath" "Error"
        return $false
    }

    Write-Console "Loading techniques from MAGNETO v3 script..." "Info"
    Write-Log "Starting to parse MAGNETO script for techniques" "DEBUG"

    try {
        $scriptContent = Get-Content $ScriptPath -Raw
        Write-Log "Script content loaded, size: $($scriptContent.Length) bytes" "DEBUG"

        # Load industry verticals
        if ($scriptContent -match '\$industryVerticals\s*=\s*@\{([\s\S]*?)\n\}(?=\s*\n)') {
            $verticalsBlock = $matches[0]
            Write-Log "Industry verticals block found" "DEBUG"

            $tempVerticalScript = @"
$verticalsBlock
return `$industryVerticals
"@

            try {
                $script:industryVerticals = & ([scriptblock]::Create($tempVerticalScript))
                Write-Log "Loaded $($script:industryVerticals.Count) industry verticals" "INFO"
            } catch {
                Write-Log "Failed to load industry verticals: $($_.Exception.Message)" "WARNING"
            }
        }

        if ($scriptContent -match '\$techniques\s*=\s*@\(([\s\S]*?)\n\)') {
            $techniquesBlock = $matches[0]
            Write-Log "Techniques block found, length: $($techniquesBlock.Length)" "DEBUG"

            $tempScript = @"
$techniquesBlock
return `$techniques
"@

            Write-Log "Executing technique extraction script" "DEBUG"
            $script:techniques = & ([scriptblock]::Create($tempScript))
            Write-Log "Extracted $($script:techniques.Count) techniques" "INFO"
            
            $techniqueList.Items.Clear()
            foreach ($tech in $script:techniques) {
                $adminTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") { " [ADMIN]" } else { "" }
                $domainTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-DomainJoined") { " [DOMAIN]" } else { "" }
                $aptTag = if ($tech.APTGroup) { " [APT:$($tech.APTGroup)]" } else { "" }
                $displayText = "$($tech.ID) - $($tech.Name) [$($tech.Tactic)]$adminTag$domainTag$aptTag"
                $null = $techniqueList.Items.Add($displayText)
            }
            
            Update-Statistics
            Write-Console "Loaded $($script:techniques.Count) techniques successfully" "Success"
            Write-Log "Technique loading completed successfully" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Could not find techniques array in script using regex" "ERROR"
            Write-Console "Could not parse techniques from script" "Error"
            return $false
        }
    }
    catch {
        Write-Log "Exception in Load-Techniques: $($_.Exception.Message)" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        Write-Console "Error loading techniques: $_" "Error"
        return $false
    }
}

function Update-Statistics {
    $totalTechniques = $script:techniques.Count
    $adminRequired = ($script:techniques | Where-Object { 
        $_.ValidationRequired -and $_.ValidationRequired.ToString() -match "Test-AdminPrivileges" 
    }).Count
    $domainRequired = ($script:techniques | Where-Object { 
        $_.ValidationRequired -and $_.ValidationRequired.ToString() -match "Test-DomainJoined" 
    }).Count
    
    $tacticGroups = $script:techniques | Group-Object -Property { $_.Tactic } | Sort-Object Name

    $tacticBreakdown = ""
    foreach ($group in $tacticGroups) {
        $tacticBreakdown += "> $($group.Name): $($group.Count) techniques" + [Environment]::NewLine
    }

    # Build APT Campaign breakdown
    $aptBreakdown = ""
    if ($script:aptCampaigns) {
        foreach ($aptName in ($script:aptCampaigns.Keys | Sort-Object)) {
            $campaign = $script:aptCampaigns[$aptName]
            $count = $campaign.Techniques.Count
            $aptBreakdown += "> $aptName`: $count techniques" + [Environment]::NewLine
        }
    }

    # Build Industry Vertical breakdown
    $verticalBreakdown = ""
    if ($script:industryVerticals) {
        foreach ($verticalName in ($script:industryVerticals.Keys | Sort-Object)) {
            $vertical = $script:industryVerticals[$verticalName]
            $count = $vertical.Techniques.Count
            $verticalBreakdown += "> $verticalName`: $count techniques" + [Environment]::NewLine
        }
    }
    
    $selectedCount = $techniqueList.CheckedItems.Count
    $selectedInfo = if ($selectedCount -gt 0) {
        "> Selected: $selectedCount techniques`r`n"
    } else {
        "> No techniques selected`r`n"
    }
    
    $aptInfo = ""
    if ($aptCombo.SelectedItem -ne "None") {
        $campaign = $script:aptCampaigns[$aptCombo.SelectedItem]
        $techniqueCount = $campaign.Techniques.Count

        # Build list of technique details
        $techniqueDetails = ""
        foreach ($techID in $campaign.Techniques) {
            $techDetail = $script:techniques | Where-Object { $_.ID -eq $techID } | Select-Object -First 1
            if ($techDetail) {
                $techniqueDetails += "> $techID - $($techDetail.Name)`r`n"
            } else {
                $techniqueDetails += "> $techID - (Details loading...)`r`n"
            }
        }

        $aptInfo = "`r`n-------------------------------------------`r`nAPT CAMPAIGN: $($aptCombo.SelectedItem)`r`n-------------------------------------------`r`nCampaign: $($campaign.Name)`r`nDescription: $($campaign.Description)`r`n`r`nTECHNIQUES TO EXECUTE: $techniqueCount`r`n-------------------------------------------`r`n$techniqueDetails"
    }
    
    # Build stats text with explicit line breaks for Windows Forms
    $statsTextContent = ""
    $statsTextContent += "===========================================" + [Environment]::NewLine
    $statsTextContent += "  SYSTEM ANALYSIS COMPLETE" + [Environment]::NewLine
    $statsTextContent += "===========================================" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += "> AVAILABLE TECHNIQUES: $totalTechniques" + [Environment]::NewLine
    $statsTextContent += "> ADMIN REQUIRED: $adminRequired" + [Environment]::NewLine
    $statsTextContent += "> DOMAIN REQUIRED: $domainRequired" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += "TACTIC BREAKDOWN:" + [Environment]::NewLine
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += $tacticBreakdown
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += "APT CAMPAIGNS:" + [Environment]::NewLine
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += $aptBreakdown
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += "INDUSTRY VERTICALS:" + [Environment]::NewLine
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += $verticalBreakdown
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += "CURRENT SELECTION:" + [Environment]::NewLine
    $statsTextContent += "-------------------------------------------" + [Environment]::NewLine
    $statsTextContent += [Environment]::NewLine
    $statsTextContent += $selectedInfo
    $statsTextContent += $aptInfo
    $statsTextContent += "==========================================="

    $statsText.Text = $statsTextContent

    # Auto-scroll to the end
    $statsText.SelectionStart = $statsText.Text.Length
    $statsText.ScrollToCaret()
}

function Check-ForUpdates {
    param(
        [switch]$Silent
    )

    try {
        Write-Log "Checking for updates from $script:versionCheckUrl" "INFO"

        $updateInfo = Invoke-RestMethod -Uri $script:versionCheckUrl -TimeoutSec 10 -ErrorAction Stop

        Write-Log "Current version: $script:currentVersion, Latest version: $($updateInfo.version)" "INFO"

        if ([version]$updateInfo.version -gt [version]$script:currentVersion) {
            Write-Log "New version available: $($updateInfo.version)" "INFO"

            $changelogText = $updateInfo.changelog -replace '\\n', "`r`n"

            $message = @"
New MAGNETO version available!

Current Version: $script:currentVersion
Latest Version: $($updateInfo.version)
Release Date: $($updateInfo.releaseDate)

What's New:
$changelogText

Would you like to download and install the update now?

Note: A backup of your current version will be created automatically.
"@

            $result = [System.Windows.Forms.MessageBox]::Show(
                $message,
                "MAGNETO Update Available",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-Update -UpdateInfo $updateInfo
            } else {
                Write-Log "User declined update" "INFO"
            }
        } else {
            Write-Log "No updates available. Running latest version." "INFO"
            if (-not $Silent) {
                [System.Windows.Forms.MessageBox]::Show(
                    "You are already running the latest version of MAGNETO ($script:currentVersion).",
                    "No Updates Available",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        }
    } catch {
        Write-Log "Update check failed: $_" "WARN"
        if (-not $Silent) {
            [System.Windows.Forms.MessageBox]::Show(
                "Unable to check for updates.`n`nError: $_`n`nPlease check your internet connection or visit:`n$script:githubRepoUrl",
                "Update Check Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    }
}

function Start-Update {
    param($UpdateInfo)

    try {
        Write-Log "Starting update process to version $($UpdateInfo.version)" "INFO"

        $tempDir = Join-Path $env:TEMP "MAGNETO_Update_$(Get-Date -Format 'yyyyMMddHHmmss')"
        $zipFile = Join-Path $tempDir "update.zip"

        # Create update progress form
        $updateForm = New-Object System.Windows.Forms.Form
        $updateForm.Text = "Updating MAGNETO..."
        $updateForm.Size = New-Object System.Drawing.Size(450, 180)
        $updateForm.StartPosition = "CenterScreen"
        $updateForm.FormBorderStyle = "FixedDialog"
        $updateForm.MaximizeBox = $false
        $updateForm.MinimizeBox = $false
        $updateForm.BackColor = $script:colorScheme.Background

        $updateLabel = New-Object System.Windows.Forms.Label
        $updateLabel.Text = "Preparing to download update..."
        $updateLabel.Location = New-Object System.Drawing.Point(20, 30)
        $updateLabel.Size = New-Object System.Drawing.Size(410, 60)
        $updateLabel.Font = New-Object System.Drawing.Font("Consolas", 10)
        $updateLabel.ForeColor = $script:colorScheme.Accent
        $updateForm.Controls.Add($updateLabel)

        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(20, 100)
        $progressBar.Size = New-Object System.Drawing.Size(410, 25)
        $progressBar.Style = "Marquee"
        $updateForm.Controls.Add($progressBar)

        $updateForm.Show()
        $updateForm.Refresh()

        # Step 1: Download
        $updateLabel.Text = "Downloading update from GitHub...`n($($UpdateInfo.downloadUrl))"
        $updateForm.Refresh()
        Write-Log "Downloading update from $($UpdateInfo.downloadUrl)" "INFO"

        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Invoke-WebRequest -Uri $UpdateInfo.downloadUrl -OutFile $zipFile -TimeoutSec 60

        # Step 2: Extract
        $updateLabel.Text = "Extracting files..."
        $updateForm.Refresh()
        Write-Log "Extracting update archive" "INFO"

        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

        # Step 3: Backup
        $updateLabel.Text = "Creating backup of current version..."
        $updateForm.Refresh()
        Write-Log "Creating backup" "INFO"

        $backupDir = Join-Path $PSScriptRoot "MAGNETO_Backup_v$($script:currentVersion)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

        @("*.ps1", "*.bat") | ForEach-Object {
            Get-ChildItem -Path $PSScriptRoot -Filter $_ -ErrorAction SilentlyContinue | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $backupDir -Force
            }
        }

        # Step 4: Install
        $updateLabel.Text = "Installing update files..."
        $updateForm.Refresh()
        Write-Log "Installing new files" "INFO"

        # Find the extracted folder (GitHub creates a folder inside the zip)
        $extractedPath = Get-ChildItem -Path $tempDir -Directory | Where-Object { $_.Name -like "Magneto3-*" } | Select-Object -First 1

        if ($extractedPath) {
            # Copy new files (preserving logs and user data)
            @("*.ps1", "*.bat", "*.json") | ForEach-Object {
                Get-ChildItem -Path $extractedPath.FullName -Filter $_ -ErrorAction SilentlyContinue | ForEach-Object {
                    Copy-Item -Path $_.FullName -Destination $PSScriptRoot -Force
                    Write-Log "Updated file: $($_.Name)" "INFO"
                }
            }
        }

        # Step 5: Cleanup
        $updateLabel.Text = "Cleaning up temporary files..."
        $updateForm.Refresh()
        Write-Log "Cleaning up temporary files" "INFO"

        Start-Sleep -Seconds 1
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        $updateForm.Close()
        $updateForm.Dispose()

        Write-Log "Update completed successfully to version $($UpdateInfo.version)" "SUCCESS"

        # Show completion message
        $restartResult = [System.Windows.Forms.MessageBox]::Show(
            "Update completed successfully!`n`n" +
            "Updated to version: $($UpdateInfo.version)`n" +
            "Backup saved to: $backupDir`n`n" +
            "MAGNETO will now restart to apply changes.`n`n" +
            "Click OK to restart now.",
            "Update Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        # Restart MAGNETO
        $launchScript = Join-Path $PSScriptRoot "Launch_MAGNETO_v3.bat"
        if (Test-Path $launchScript) {
            Start-Process -FilePath $launchScript
        } else {
            Start-Process powershell -ArgumentList "-File `"$(Join-Path $PSScriptRoot 'MAGNETO_GUI_v3.ps1')`""
        }

        # Close current instance
        $form.Close()

    } catch {
        Write-Log "Update failed: $_" "ERROR"

        if ($updateForm) {
            $updateForm.Close()
            $updateForm.Dispose()
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Update failed!`n`n" +
            "Error: $_`n`n" +
            "Please try again or download manually from:`n$script:githubRepoUrl",
            "Update Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Generate-HTMLReport {
    param(
        [array]$ExecutedTechniques,
        [string]$OutputPath
    )

    Write-Log "Generating HTML report" "INFO"

    # Determine which MITRE ATT&CK tactics are covered by executed techniques
    $coveredTactics = @{}
    foreach ($tech in $ExecutedTechniques) {
        if ($tech.Tactic) {
            $coveredTactics[$tech.Tactic] = $true
        }
    }

    # MITRE ATT&CK Tactics in order (14 tactics)
    $mitreOrder = @(
        "Reconnaissance",
        "Resource Development",
        "Initial Access",
        "Execution",
        "Persistence",
        "Privilege Escalation",
        "Defense Evasion",
        "Credential Access",
        "Discovery",
        "Lateral Movement",
        "Collection",
        "Command and Control",
        "Exfiltration",
        "Impact"
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MAGNETO Attack Simulation Report</title>
    <style>
        body { background-color: #0a0a0a; color: #00ff00; font-family: 'Consolas', 'Courier New', monospace; padding: 20px; line-height: 1.6; }
        h1 { color: #00ff00; text-align: center; text-shadow: 0 0 10px #00ff00; font-size: 2.5em; margin-bottom: 10px; }
        h2 { color: #00ffaa; border-bottom: 2px solid #00ff00; padding-bottom: 10px; margin-top: 30px; }
        .info-section { background-color: #1a1a1a; border: 1px solid #00ff00; border-radius: 5px; padding: 15px; margin: 20px 0; }
        .technique-card { background-color: #1a1a1a; border: 1px solid #00ff00; border-radius: 5px; padding: 15px; margin: 15px 0; transition: all 0.3s; }
        .technique-card:hover { background-color: #2a2a2a; box-shadow: 0 0 15px #00ff00; }
        .technique-id { color: #ffff00; font-weight: bold; font-size: 1.2em; }
        .technique-name { color: #00ffff; font-size: 1.1em; margin-left: 10px; }
        .tactic { color: #ff00ff; font-style: italic; margin-left: 20px; }
        .mitre-link { background-color: #00ff00; color: #000; padding: 5px 15px; text-decoration: none; border-radius: 3px; display: inline-block; margin-top: 10px; font-weight: bold; transition: all 0.3s; }
        .mitre-link:hover { background-color: #00ffaa; box-shadow: 0 0 10px #00ff00; transform: scale(1.05); }
        .command { background-color: #0a0a0a; color: #00ff00; padding: 10px; border-left: 3px solid #00ff00; margin: 10px 0; font-family: monospace; overflow-x: auto; }
        .details { margin-top: 15px; padding: 12px; padding-left: 15px; border-left: 3px solid #ffff00; color: #e0e0e0; font-size: 1.05em; line-height: 1.6; }
        .details-label { color: #ffff00; font-weight: bold; font-size: 1.1em; }
        .timestamp { color: #888; font-size: 0.9em; }
        .success { color: #00ff00; }
        .error { color: #ff0000; }
        .warning { color: #ffff00; }
        .apt-badge { background-color: #8a2be2; color: #fff; padding: 3px 8px; border-radius: 3px; font-size: 0.9em; margin-left: 10px; }
        .footer { text-align: center; margin-top: 50px; padding-top: 20px; border-top: 1px solid #00ff00; color: #888; }

        /* MITRE ATT&CK Matrix Styles */
        .mitre-matrix-container { background-color: #1a1a1a; border: 2px solid #00ff00; border-radius: 10px; padding: 20px; margin: 20px 0; overflow-x: auto; }
        .mitre-matrix-title { text-align: center; font-size: 1.8em; color: #00ff00; margin-bottom: 20px; font-weight: bold; }
        .mitre-tactics-row { display: flex; align-items: center; justify-content: flex-start; gap: 5px; margin: 20px 0; flex-wrap: nowrap; padding: 0 20px 0 20px; padding-right: 40px !important; }
        .mitre-tactic { position: relative; min-width: 90px; height: 90px; border-radius: 8px; background-color: #2a2a2a; border: 2px solid #555; display: flex; align-items: center; justify-content: center; text-align: center; font-size: 0.7em; color: #888; transition: all 0.3s; padding: 5px; flex-shrink: 0; margin-right: 2px; }
        .mitre-tactic.active { background-color: #1a4d1a; border: 2px solid #00ff00; color: #00ff00; font-weight: bold; box-shadow: 0 0 15px #00ff00; animation: pulse 2s infinite; }
        .mitre-arrow { font-size: 1.5em; color: #555; flex-shrink: 0; }
        .mitre-arrow.active { color: #00ff00; }
        .mitre-legend { text-align: center; margin-top: 15px; font-size: 0.9em; color: #888; }
        .legend-active { color: #00ff00; font-weight: bold; }
        @keyframes pulse { 0%, 100% { box-shadow: 0 0 15px #00ff00; } 50% { box-shadow: 0 0 25px #00ff00, 0 0 35px #00ff00; } }

        /* NIST Mapping Styles */
        .nist-mapping { background-color: #1a1a2a; border: 2px solid #6495ed; border-radius: 10px; padding: 20px; margin: 20px 0; }
        .nist-header { color: #6495ed; font-size: 1.5em; margin-bottom: 15px; padding: 15px; background-color: #2a2a4a; border-radius: 5px; cursor: pointer; transition: all 0.3s; user-select: none; }
        .nist-header:hover { background-color: #3a3a5a; box-shadow: 0 0 10px #6495ed; }
        .nist-toggle { display: inline-block; width: 25px; font-weight: bold; color: #ffd700; transition: transform 0.3s; }
        .nist-content { overflow: hidden; transition: max-height 0.3s ease-out; }
        .nist-mapping h3 { color: #6495ed; font-size: 1.5em; margin-bottom: 15px; border-bottom: 2px solid #6495ed; padding-bottom: 10px; }
        .nist-mapping h4 { color: #87ceeb; font-size: 1.2em; margin-top: 15px; margin-bottom: 10px; }
        .nist-summary { background-color: #0f0f1f; border-left: 4px solid #6495ed; padding: 15px; margin-bottom: 20px; }
        .nist-summary p { color: #87ceeb; font-size: 1.1em; margin: 0; }
        .nist-table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        .nist-table th { background-color: #2a2a4a; color: #87ceeb; padding: 12px; text-align: left; border: 1px solid #6495ed; }
        .nist-table td { padding: 10px; border: 1px solid #444; color: #ccc; }
        .nist-table tr:nth-child(even) { background-color: #1a1a2a; }
        .nist-table tr:hover { background-color: #2a2a3a; }
        .control-family { background-color: #4169e1; color: #fff; padding: 2px 6px; border-radius: 3px; font-size: 0.85em; font-weight: bold; }
        .csf-functions { display: flex; flex-wrap: wrap; gap: 15px; margin: 15px 0; }
        .csf-function { background-color: #2a2a4a; border: 2px solid #6495ed; border-radius: 8px; padding: 15px; flex: 1; min-width: 200px; }
        .csf-badge { color: #ffd700; font-weight: bold; font-size: 1.1em; margin-bottom: 8px; text-transform: uppercase; }
        .csf-desc { color: #ccc; font-size: 0.9em; line-height: 1.4; }
        .compliance-note { background-color: #0f0f1f; border: 1px solid #6495ed; border-radius: 5px; padding: 15px; margin-top: 20px; }
        .compliance-note p { color: #87ceeb; margin: 8px 0; }
        .nist-stats-banner { background: linear-gradient(135deg, #1e3a5f 0%, #2a4a7a 100%); border: 3px solid #6495ed; border-radius: 10px; padding: 25px; margin: 20px 0; text-align: center; box-shadow: 0 0 20px rgba(100, 149, 237, 0.3); }
        .nist-stats-banner h2 { color: #ffd700; font-size: 1.8em; margin-bottom: 15px; text-shadow: 0 0 10px #ffd700; }
        .nist-stat-item { display: inline-block; margin: 10px 20px; }
        .nist-stat-number { color: #00ff00; font-size: 2.5em; font-weight: bold; text-shadow: 0 0 10px #00ff00; }
        .nist-stat-label { color: #87ceeb; font-size: 1.1em; margin-top: 5px; }
    </style>
</head>
<body>
    <h1>MAGNETO v3 ATTACK SIMULATION REPORT</h1>

    <!-- MITRE ATT&CK Tactics Visualization -->
    <div class="mitre-matrix-container">
        <div class="mitre-matrix-title">MITRE ATT&CK Enterprise Tactics</div>
        <div class="mitre-tactics-row">
"@

    for ($i = 0; $i -lt $mitreOrder.Count; $i++) {
        $tactic = $mitreOrder[$i]
        $isActive = if ($coveredTactics.ContainsKey($tactic)) { 'active' } else { '' }

        $html += @"
            <div class="mitre-tactic $isActive">$tactic</div>
"@

        # Add arrow between tactics (except after the last one)
        if ($i -lt ($mitreOrder.Count - 1)) {
            $nextTactic = $mitreOrder[$i + 1]
            $arrowActive = if ($coveredTactics.ContainsKey($tactic) -and $coveredTactics.ContainsKey($nextTactic)) { 'active' } else { '' }
            $html += @"
            <span class="mitre-arrow $arrowActive">&gt;</span>
"@
        }
    }

    # Add spacer div at the end to ensure proper spacing
    $html += @"
            <div style="min-width: 40px; flex-shrink: 0;"></div>
        </div>
        <div class="mitre-legend">
            <span class="legend-active">[*] Highlighted tactics</span> indicate areas covered by this simulation
        </div>
    </div>

    <div class="info-section">
        <h2>Execution Summary</h2>
        <p><span class="timestamp">Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span></p>
        <p>System: <strong>$env:COMPUTERNAME</strong></p>
        <p>User: <strong>$env:USERNAME</strong></p>
        <p>Total Techniques Executed: <strong>$($ExecutedTechniques.Count)</strong></p>
"@
    
    if ($aptCombo.SelectedItem -ne "None") {
        $campaign = $script:aptCampaigns[$aptCombo.SelectedItem]
        $html += @"
        <p>APT Campaign: <span class="apt-badge">$($aptCombo.SelectedItem) - $($campaign.Name)</span></p>
"@
    }

    $html += @"
    </div>
"@

    # Add detailed APT Group information section if APT campaign was selected
    if ($aptCombo.SelectedItem -ne "None") {
        $campaign = $script:aptCampaigns[$aptCombo.SelectedItem]

        $html += @"
    <div class="info-section" style="background: linear-gradient(135deg, #1a0a2e 0%, #2a1a3e 100%); border: 2px solid #8a2be2;">
        <h2 style="color: #da70d6; text-shadow: 0 0 10px #da70d6;">
            <span style="font-size: 1.5em;">&#128274;</span> APT GROUP INTELLIGENCE: $($aptCombo.SelectedItem)
        </h2>

        <div style="margin: 20px 0; padding: 15px; background-color: #0f0a1f; border-left: 4px solid #8a2be2; border-radius: 5px;">
            <h3 style="color: #da70d6; margin-top: 0;">Overview</h3>
            <p style="color: #e0e0e0; font-size: 1.1em; line-height: 1.6;">$($campaign.Overview)</p>
        </div>

        <div style="margin: 20px 0; padding: 15px; background-color: #0f0a1f; border-left: 4px solid #ff6347; border-radius: 5px;">
            <h3 style="color: #ff6347; margin-top: 0;">
                <span style="font-size: 1.2em;">&#127919;</span> Primary Targets
            </h3>
            <p style="color: #e0e0e0; font-size: 1.05em; line-height: 1.6;">$($campaign.Targets)</p>
        </div>

        <div style="margin: 20px 0; padding: 15px; background-color: #0f0a1f; border-left: 4px solid #ffa500; border-radius: 5px;">
            <h3 style="color: #ffa500; margin-top: 0;">
                <span style="font-size: 1.2em;">&#9876;</span> Attack Methodologies
            </h3>
            <p style="color: #e0e0e0; font-size: 1.05em; line-height: 1.6;">$($campaign.AttackMethods)</p>
        </div>

        <div style="margin: 20px 0; padding: 15px; background-color: #0f0a1f; border-left: 4px solid #00bfff; border-radius: 5px;">
            <h3 style="color: #00bfff; margin-top: 0;">
                <span style="font-size: 1.2em;">&#128279;</span> Attribution
            </h3>
            <p style="color: #e0e0e0; font-size: 1.05em; line-height: 1.6;">$($campaign.Attribution)</p>
        </div>

        <div style="margin: 20px 0; padding: 15px; background-color: #0f0a1f; border-left: 4px solid #32cd32; border-radius: 5px;">
            <h3 style="color: #32cd32; margin-top: 0;">
                <span style="font-size: 1.2em;">&#128221;</span> Known Campaigns & Operations
            </h3>
            <p style="color: #e0e0e0; font-size: 1.05em; line-height: 1.6;">$($campaign.KnownCampaigns)</p>
        </div>

        <div style="margin-top: 20px; padding: 12px; background-color: #2a1a3e; border: 1px solid #8a2be2; border-radius: 5px; text-align: center;">
            <p style="color: #da70d6; font-size: 0.95em; margin: 0;">
                <strong>NOTE:</strong> This simulation replicates techniques associated with $($aptCombo.SelectedItem) for defensive testing purposes only.
                Understanding real-world APT behaviors helps organizations validate detection capabilities and improve defensive posture.
            </p>
        </div>
    </div>
"@
    }

    # Add NIST Control Summary if mappings are enabled
    if ($script:nistMappingsEnabled) {
        try {
            $totalControls = 0
            $allFamilies = @{}
            $allCSFFunctions = @{}

            foreach ($tech in $ExecutedTechniques) {
                $summary = Get-NistControlSummary -TechniqueId $tech.ID
                $totalControls += $summary.TotalControls

                foreach ($family in $summary.ControlFamilies) {
                    if (!$allFamilies.ContainsKey($family.Family)) {
                        $allFamilies[$family.Family] = 0
                    }
                    $allFamilies[$family.Family] += $family.Count
                }

                foreach ($func in $summary.CSFFunctions) {
                    $allCSFFunctions[$func] = $true
                }
            }

            $uniqueControls = $totalControls
            $uniqueFamilies = $allFamilies.Count
            $uniqueFunctions = $allCSFFunctions.Count

            $html += @"
    <div class="nist-stats-banner">
        <h2>[NIST] Compliance Validation Summary</h2>
        <div style="margin-top: 20px;">
            <div class="nist-stat-item">
                <div class="nist-stat-number">$uniqueControls</div>
                <div class="nist-stat-label">NIST 800-53 Rev 5<br/>Controls Validated</div>
            </div>
            <div class="nist-stat-item">
                <div class="nist-stat-number">$uniqueFamilies</div>
                <div class="nist-stat-label">Control Families<br/>Tested</div>
            </div>
            <div class="nist-stat-item">
                <div class="nist-stat-number">$uniqueFunctions</div>
                <div class="nist-stat-label">NIST CSF 2.0<br/>Functions Covered</div>
            </div>
        </div>
        <p style="color: #87ceeb; margin-top: 20px; font-size: 1.1em;">This simulation provides evidence of security control effectiveness for compliance audits</p>
    </div>
"@
        } catch {
            Write-Log "Error generating NIST summary: $_" "WARNING"
        }
    }

    $html += @"
    <h2>Executed MITRE ATT&CK Techniques</h2>
"@
    
    foreach ($tech in $ExecutedTechniques) {
        # Generate correct MITRE ATT&CK URL
        # Format: T1234 -> https://attack.mitre.org/techniques/T1234/
        # Format: T1234.001 -> https://attack.mitre.org/techniques/T1234/001/
        if ($tech.ID -match '^T(\d+)\.(\d+)$') {
            # Sub-technique format
            $mitreUrl = "https://attack.mitre.org/techniques/T$($matches[1])/$($matches[2])/"
        } elseif ($tech.ID -match '^T(\d+)$') {
            # Main technique format
            $mitreUrl = "https://attack.mitre.org/techniques/$($tech.ID)/"
        } else {
            # Fallback for any unexpected format
            $mitreUrl = "https://attack.mitre.org/techniques/$($tech.ID)/"
        }
        
        $html += @"
    <div class="technique-card">
        <div>
            <span class="technique-id">$($tech.ID)</span>
            <span class="technique-name">$($tech.Name)</span>
            <span class="tactic">[$($tech.Tactic)]</span>
"@
        
        if ($tech.APTGroup) {
            $html += @"
            <span class="apt-badge">$($tech.APTGroup)</span>
"@
        }
        
        $html += @"
        </div>
        <div class="command">Command: $($tech.Command)</div>
        <div class="details">
            <span class="details-label">Why Track:</span> $($tech.Description.WhyTrack)
        </div>
        <div class="details">
            <span class="details-label">Real-World Usage:</span> $($tech.Description.RealWorldUsage)
        </div>
        <div>Status: <span class="$($tech.Status.ToLower())">$($tech.Status)</span> | <span class="timestamp">Executed: $($tech.Timestamp)</span></div>
        <a href="$mitreUrl" target="_blank" class="mitre-link">View on MITRE ATT&CK</a>
"@

        # Add NIST controls for this technique
        if ($script:nistMappingsEnabled) {
            try {
                $nistHtml = Get-NistHtmlSection -TechniqueId $tech.ID
                $html += $nistHtml
            } catch {
                Write-Log "Error generating NIST section for $($tech.ID): $_" "WARNING"
            }
        }

        $html += @"
    </div>
"@
    }
    
    $html += @"
    <div class="footer">
        <p>MAGNETO v3 - Advanced APT Campaign Simulator</p>
        <p>Report generated by MAGNETO GUI</p>
    </div>

    <script type="text/javascript">
        function toggleNistSection(sectionId) {
            try {
                var content = document.getElementById(sectionId);
                var toggle = document.getElementById(sectionId + '-toggle');

                if (!content || !toggle) {
                    console.error('NIST elements not found:', sectionId);
                    alert('Error: NIST section not found. Section ID: ' + sectionId);
                    return;
                }

                if (content.style.display === 'none' || content.style.display === '') {
                    content.style.display = 'block';
                    if (toggle.textContent !== undefined) {
                        toggle.textContent = '[-]';
                    } else {
                        toggle.innerText = '[-]';  // IE fallback
                    }
                } else {
                    content.style.display = 'none';
                    if (toggle.textContent !== undefined) {
                        toggle.textContent = '[+]';
                    } else {
                        toggle.innerText = '[+]';  // IE fallback
                    }
                }
            } catch (error) {
                console.error('Error in toggleNistSection:', error);
                alert('JavaScript Error: ' + error.message);
            }
        }

        // Test function to verify JavaScript is working
        function testJavaScript() {
            alert('JavaScript is working! Click OK to continue.');
        }

        // Log when page loads
        if (window.addEventListener) {
            window.addEventListener('load', function() {
                console.log('MAGNETO report loaded successfully');
                console.log('Toggle function defined:', typeof toggleNistSection);
            });
        } else if (window.attachEvent) {
            // IE8 and below
            window.attachEvent('onload', function() {
                console.log('MAGNETO report loaded (IE mode)');
            });
        }
    </script>
</body>
</html>
"@
    
    try {
        # Use UTF8 with BOM for better cross-platform compatibility
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($OutputPath, $html, $utf8WithBom)
        Write-Log "HTML report generated: $OutputPath" "SUCCESS"

        # Verify file was written correctly
        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length
            Write-Log "HTML file size: $fileSize bytes" "DEBUG"

            # Check if JavaScript is in the file
            $content = Get-Content $OutputPath -Raw
            if ($content -match '<script type="text/javascript">') {
                Write-Log "JavaScript section verified in HTML" "DEBUG"
            } else {
                Write-Log "WARNING: JavaScript section not found in generated HTML!" "WARNING"
            }
        }

        return $true
    } catch {
        Write-Log "Failed to generate HTML report: $_" "ERROR"
        return $false
    }
}

function Build-CommandLine {
    Write-Log "Build-CommandLine called" "DEBUG"
    $params = @{}

    $selectedAPT = $aptCombo.SelectedItem
    $selectedVertical = $verticalCombo.SelectedItem

    if ($selectedAPT -ne "None") {
        Write-Log "APT Campaign selected: $selectedAPT" "INFO"
        $params.APTCampaign = $selectedAPT
    } elseif ($selectedVertical -ne "None") {
        Write-Log "Industry Vertical selected: $selectedVertical" "INFO"
        $params.IndustryVertical = $selectedVertical
        # Industry Vertical runs ALL techniques for that vertical (no count limit)
    } else {
        $selectedMode = $modeCombo.SelectedItem
        Write-Log "Selected mode: $selectedMode" "INFO"
        
        switch ($selectedMode) {
            "Random - Chaos Mode" {
                $params.AttackMode = "Random"
                $params.TechniqueCount = $countUpDown.Value
            }
            "Chain - Attack Lifecycle" {
                $params.AttackMode = "Chain"
            }
            "Specific Techniques Only" {
                $selectedTechIDs = @()
                for ($i = 0; $i -lt $techniqueList.Items.Count; $i++) {
                    if ($techniqueList.GetItemChecked($i)) {
                        $item = $techniqueList.Items[$i]
                        if ($item -match '^(T\d+(?:\.\d+)?)') {
                            $selectedTechIDs += $matches[1]
                        }
                    }
                }
                if ($selectedTechIDs.Count -gt 0) {
                    $params.IncludeTechniques = $selectedTechIDs
                }
            }
            "Run All Techniques" {
                $params.RunAll = $true
            }
            "Run All in Selected Tactics" {
                $params.RunAllForTactics = $true
            }
        }
        
        $checkedTactics = @()
        for ($i = 0; $i -lt $tacticChecklist.Items.Count; $i++) {
            if ($tacticChecklist.GetItemChecked($i)) {
                $checkedTactics += $tacticChecklist.Items[$i]
            }
        }
        
        if ($checkedTactics.Count -gt 0) {
            if ($includeRadio.Checked) {
                $params.IncludeTactics = $checkedTactics
            } else {
                $params.ExcludeTactics = $checkedTactics
            }
        }
    }
    
    $params.DelayBetweenTechniques = $delayUpDown.Value

    if ($cleanupCheck.Checked) {
        $params.Cleanup = $true
    }

    # Add remote execution parameters
    if ($remoteCheck.Checked -and -not [string]::IsNullOrWhiteSpace($targetComputer.Text)) {
        $params.RemoteComputer = $targetComputer.Text
        Write-Log "Remote execution enabled for: $($targetComputer.Text)" "INFO"

        if ($script:remoteCredential) {
            $params.RemoteCredential = $script:remoteCredential
            Write-Log "Using alternate credentials: $($script:remoteCredential.UserName)" "INFO"
        }
    }

    $logString = $params.GetEnumerator() | ForEach-Object {
        if ($_.Key -eq "RemoteCredential") {
            "-RemoteCredential [PSCredential]"
        } else {
            "-$($_.Key) $($_.Value)"
        }
    } | Out-String
    Write-Log "Final command line parameters: $($logString.Trim())" "INFO"
    return $params
}

function Complete-AttackSimulation {
    param ([string]$Reason)

    if ($script:completionHandled) { return }
    $script:completionHandled = $true

    Write-Log "Attack simulation completing. Reason: $Reason" "INFO"
    Stop-FlashAlert
    
    Write-Log "Running completion logic. Number of executed techniques found: $($script:executedTechniques.Count)" "INFO"

    if ($script:executedTechniques.Count -gt 0) {
        Write-Log "Found $($script:executedTechniques.Count) techniques, proceeding with HTML report generation." "DEBUG"

        # Mark any techniques still in EXECUTING status as SUCCESS
        foreach ($tech in $script:executedTechniques) {
            if ($tech.Status -eq "EXECUTING") {
                $tech.Status = "SUCCESS"
                Write-Log "Marked technique $($tech.ID) as SUCCESS (was still EXECUTING)" "DEBUG"
            }
            # If Command is still empty, provide a default message
            if ([string]::IsNullOrWhiteSpace($tech.Command)) {
                $tech.Command = "Technique executed via $($tech.Name) simulation"
                Write-Log "Added default command description for $($tech.ID)" "DEBUG"
            }
        }

        $reportPath = Join-Path $PSScriptRoot "Reports\MAGNETO_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        if (Generate-HTMLReport -ExecutedTechniques $script:executedTechniques -OutputPath $reportPath) {
            Write-Console "HTML Report generated: $reportPath" "Success"
            try {
                Start-Process $reportPath
                Write-Console "Opening HTML report in browser..." "Info"
            } catch {
                Write-Log "Failed to open HTML report: $_" "ERROR"
            }
        }
    } else {
        Write-Log "No executed techniques found in the array. Skipping HTML report." "WARN"
    }
    
    # Log file is generated but not auto-opened (HTML report opens instead)
    if ($script:generatedLogFile -and (Test-Path $script:generatedLogFile)) {
        Write-Console "Attack log saved: $script:generatedLogFile" "Success"
    }
    
    if ($script:jobTimer) {
        $script:jobTimer.Stop(); $script:jobTimer.Dispose(); $script:jobTimer = $null
    }
    if ($script:job) {
        Stop-Job -Job $script:job -PassThru | Wait-Job -Timeout 2 | Out-Null
        Remove-Job -Job $script:job -Force -ErrorAction SilentlyContinue
        $script:job = $null
    }
    
    $script:isRunning = $false
    $executeBtn.Enabled = $true
    $stopBtn.Enabled = $false
    
    if ($progressBar.Maximum -gt 0) {
        $progressBar.Value = $progressBar.Maximum
    }
    
    Write-Console "================================================" "Success"
    Write-Console "[+] ATTACK SIMULATION COMPLETE" "Success"
    Write-Console "================================================" "Success"
    
    $statusLabel.Text = "COMPLETE | Check Exabeam UEBA for anomalies"
    $statusLabel.ForeColor = $script:colorScheme.Success
    
    [System.Media.SystemSounds]::Exclamation.Play()
    Write-Log "Attack simulation completed successfully" "SUCCESS"
}

function Process-JobOutput {
    param($OutputLines)

    foreach ($line in $OutputLines) {
        $msg = $line.ToString()

        if ($msg -match '\[(T\d+(?:\.\d+)?)\]') {
            $techID = $matches[1]
            Write-Log "Detected technique in output: $techID" "DEBUG"
            $techDetails = $script:techniques | Where-Object { $_.ID -eq $techID } | Select-Object -First 1
            if ($techDetails -and -not ($script:executedTechniques | Where-Object { $_.ID -eq $techID })) {
                $newTech = [PSCustomObject]@{
                    ID = $techID
                    Name = $techDetails.Name
                    Tactic = $techDetails.Tactic
                    Description = $techDetails.Description
                    Command = ""
                    Status = "EXECUTING"
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    APTGroup = $techDetails.APTGroup
                }
                $script:executedTechniques += $newTech
            }
        }

        if ($msg -match 'Command:\s*(.+)') {
            $command = $matches[1].Trim()
            $tech = $script:executedTechniques | Where-Object { $_.ID -and $_.Command -eq "" } | Select-Object -Last 1
            if ($tech) {
                $tech.Command = $command
                $tech.Status = "SUCCESS"
            }
        }

        if ($msg -match 'Log generated:\s*(.+)') {
            $logFilePath = $matches[1].Trim()
            # Path is already absolute from MAGNETO_v3.ps1
            $script:generatedLogFile = $logFilePath
            Write-Log "Captured log file path: $($script:generatedLogFile)" "INFO"
        }
        
        if ($msg -match '\[(\d+)/(\d+)\]') {
            $current = [int]$matches[1]; $total = [int]$matches[2]
            if ($total -gt 0) { $progressBar.Maximum = $total; $progressBar.Value = [Math]::Min($current, $total) }
        }

        if ($msg -and $msg.Trim()) {
            if ($msg -match 'Executing:|\[T\d+') {
                 Write-Console $msg "Attack"
            } else {
                 Write-Console $msg "Info"
            }
        }
    }
}

# Event Handlers
$aptCombo.Add_SelectedIndexChanged({
    $selectedAPT = $aptCombo.SelectedItem
    if ($selectedAPT -ne "None") {
        $verticalCombo.Enabled = $false
        $modeCombo.Enabled = $false; $techniqueList.Enabled = $false; $countUpDown.Enabled = $false
        $tacticChecklist.Enabled = $false; $includeRadio.Enabled = $false; $excludeRadio.Enabled = $false
        $statusLabel.Text = "APT MODE | $selectedAPT Campaign Selected"
        $statusLabel.ForeColor = $script:colorScheme.APTHighlight

        $campaign = $script:aptCampaigns[$selectedAPT]
        $techniqueCount = $campaign.Techniques.Count

        Write-Console "================================================" "APT"
        Write-Console "APT Campaign Selected: $selectedAPT" "APT"
        Write-Console "Campaign Name: $($campaign.Name)" "Info"
        Write-Console "Description: $($campaign.Description)" "Info"
        Write-Console "Techniques to Execute: $techniqueCount" "Success"
        Write-Console "================================================" "APT"

        # List all techniques
        foreach ($techID in $campaign.Techniques) {
            $techDetail = $script:techniques | Where-Object { $_.ID -eq $techID } | Select-Object -First 1
            if ($techDetail) {
                Write-Console "  > $techID - $($techDetail.Name)" "Info"
            }
        }
        Write-Console "================================================" "APT"
    } else {
        $verticalCombo.Enabled = $true
        $modeCombo.Enabled = $true; $techniqueList.Enabled = $true; $countUpDown.Enabled = $true
        $tacticChecklist.Enabled = $true; $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true
        $statusLabel.Text = "READY | Standard MAGNETO Mode"
        $statusLabel.ForeColor = $script:colorScheme.Accent
    }
    Update-Statistics
})

# Industry Vertical Selection Event Handler
$verticalCombo.Add_SelectedIndexChanged({
    $selectedVertical = $verticalCombo.SelectedItem
    if ($selectedVertical -ne "None") {
        # Disable other modes and slider
        $aptCombo.Enabled = $false
        $modeCombo.Enabled = $false
        $techniqueList.Enabled = $false
        $countUpDown.Enabled = $false
        $tacticChecklist.Enabled = $false
        $includeRadio.Enabled = $false
        $excludeRadio.Enabled = $false

        $statusLabel.Text = "INDUSTRY VERTICAL MODE | $selectedVertical Selected"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100)

        if ($script:industryVerticals.ContainsKey($selectedVertical)) {
            $vertical = $script:industryVerticals[$selectedVertical]
            $verticalTechniqueIds = $vertical.Techniques
            $verticalTechniques = $script:techniques | Where-Object { $_.ID -in $verticalTechniqueIds }

            Write-Console "================================================" "Success"
            Write-Console "Industry Vertical Selected: $selectedVertical" "Success"
            Write-Console "Display Name: $($vertical.DisplayName)" "Info"
            Write-Console "Description: $($vertical.Description)" "Info"
            Write-Console "Risk Profile: $($vertical.RiskProfile)" "Warning"
            Write-Console "APT Groups: $($vertical.APTGroups -join ', ')" "Info"
            Write-Console "Primary Threats: $($vertical.PrimaryThreats -join ', ')" "Info"
            Write-Console "Available Techniques: $($verticalTechniques.Count)" "Success"
            Write-Console "================================================" "Success"
            Write-Console "" "Info"
            Write-Console "Techniques for this Industry:" "Success"
            Write-Console "-------------------------------------------" "Info"

            # List all techniques for this vertical
            foreach ($tech in $verticalTechniques) {
                Write-Console "  > $($tech.ID) - $($tech.Name) [$($tech.Tactic)]" "Info"
            }
            Write-Console "-------------------------------------------" "Info"
            Write-Console "" "Info"
            Write-Console "All $($verticalTechniques.Count) techniques will be executed for this vertical" "Success"
            Write-Console "================================================" "Success"
        }
    } else {
        # Re-enable other modes and slider
        $aptCombo.Enabled = $true
        $modeCombo.Enabled = $true
        $techniqueList.Enabled = $true
        $countUpDown.Enabled = $true
        $tacticChecklist.Enabled = $true
        $includeRadio.Enabled = $true
        $excludeRadio.Enabled = $true

        $statusLabel.Text = "READY | Standard MAGNETO Mode"
        $statusLabel.ForeColor = $script:colorScheme.Accent
    }
    Update-Statistics
})

$searchBox.Add_TextChanged({
    $searchTerm = $searchBox.Text.Trim()
    $techniqueList.BeginUpdate()

    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        # Show all techniques when search is empty
        $techniqueList.Items.Clear()
        foreach ($tech in $script:techniques) {
            $adminTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") { " [ADMIN]" } else { "" }
            $domainTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-DomainJoined") { " [DOMAIN]" } else { "" }
            $aptTag = if ($tech.APTGroup) { " [APT:$($tech.APTGroup)]" } else { "" }
            $displayText = "$($tech.ID) - $($tech.Name) [$($tech.Tactic)]$adminTag$domainTag$aptTag"
            $techniqueList.Items.Add($displayText) | Out-Null
        }
    } else {
        # Filter techniques based on search term
        $techniqueList.Items.Clear()
        $filteredTechniques = $script:techniques | Where-Object {
            $_.ID -like "*$searchTerm*" -or
            $_.Name -like "*$searchTerm*" -or
            $_.Tactic -like "*$searchTerm*"
        }

        foreach ($tech in $filteredTechniques) {
            $adminTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-AdminPrivileges") { " [ADMIN]" } else { "" }
            $domainTag = if ($tech.ValidationRequired -and $tech.ValidationRequired.ToString() -match "Test-DomainJoined") { " [DOMAIN]" } else { "" }
            $aptTag = if ($tech.APTGroup) { " [APT:$($tech.APTGroup)]" } else { "" }
            $displayText = "$($tech.ID) - $($tech.Name) [$($tech.Tactic)]$adminTag$domainTag$aptTag"
            $techniqueList.Items.Add($displayText) | Out-Null
        }
    }

    $techniqueList.EndUpdate()
    Update-Statistics
})
$selectAllBtn.Add_Click({ for ($i = 0; $i -lt $techniqueList.Items.Count; $i++) { $null = $techniqueList.SetItemChecked($i, $true) }; Update-Statistics })
$selectNoneBtn.Add_Click({ for ($i = 0; $i -lt $techniqueList.Items.Count; $i++) { $null = $techniqueList.SetItemChecked($i, $false) }; Update-Statistics })
$techniqueList.Add_ItemCheck({ Start-Sleep -Milliseconds 100; Update-Statistics })
# Remote Execution Event Handlers
$remoteCheck.Add_CheckedChanged({
    $enabled = $remoteCheck.Checked
    $targetLabel.Enabled = $enabled
    $targetComputer.Enabled = $enabled
    $testConnBtn.Enabled = $enabled
    $altCredsCheck.Enabled = $enabled

    if (-not $enabled) {
        $targetComputer.Text = ""
        $altCredsCheck.Checked = $false
        $script:remoteCredential = $null
        $script:remoteConnectionValid = $false
    }
})

$altCredsCheck.Add_CheckedChanged({
    if ($altCredsCheck.Checked) {
        try {
            $script:remoteCredential = Get-Credential -Message "Enter credentials for remote computer"
            if (-not $script:remoteCredential) {
                $altCredsCheck.Checked = $false
                Write-Console "Credential prompt cancelled" "Warning"
            } else {
                Write-Console "Credentials captured for user: $($script:remoteCredential.UserName)" "Success"
                $script:remoteConnectionValid = $false  # Need to re-test with new creds
            }
        } catch {
            $altCredsCheck.Checked = $false
            Write-Console "Failed to get credentials: $_" "Error"
        }
    } else {
        $script:remoteCredential = $null
        $script:remoteConnectionValid = $false
    }
})

$testConnBtn.Add_Click({
    if ([string]::IsNullOrWhiteSpace($targetComputer.Text)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter a target computer name or IP address.",
            "Missing Target",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    Write-Console "================================================" "Info"
    Write-Console "TESTING REMOTE CONNECTION" "Success"
    Write-Console "Target: $($targetComputer.Text)" "Info"
    Write-Console "================================================" "Info"

    $cursor = $form.Cursor
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $testConnBtn.Enabled = $false

    try {
        # Test connection
        $result = Test-RemoteConnection -ComputerName $targetComputer.Text -Credential $script:remoteCredential

        if ($result.Success) {
            Write-Console "[+] Connection successful!" "Success"
            Write-Console "Computer: $($result.SystemInfo.ComputerName)" "Info"
            Write-Console "OS: $($result.SystemInfo.OSVersion)" "Info"
            Write-Console "PowerShell: v$($result.SystemInfo.PSVersion)" "Info"

            if ($result.IsAdmin) {
                Write-Console "[+] Administrator privileges: CONFIRMED" "Success"
                $script:remoteConnectionValid = $true

                # Check SIEM logging on remote machine
                Write-Console "-------------------------------------------" "Info"
                Write-Console "Checking SIEM logging on remote machine..." "Info"

                $siemStatus = Test-RemoteSiemLogging -ComputerName $targetComputer.Text -Credential $script:remoteCredential

                if ($siemStatus) {
                    Write-Console "PowerShell Module Logging: $(if($siemStatus.ModuleLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($siemStatus.ModuleLogging){'Success'}else{'Warning'})
                    Write-Console "Script Block Logging: $(if($siemStatus.ScriptBlockLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($siemStatus.ScriptBlockLogging){'Success'}else{'Warning'})
                    Write-Console "Command Line Logging: $(if($siemStatus.CommandLineLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($siemStatus.CommandLineLogging){'Success'}else{'Warning'})
                    Write-Console "Process Auditing: $(if($siemStatus.ProcessAuditing){'[ENABLED]'}else{'[DISABLED]'})" $(if($siemStatus.ProcessAuditing){'Success'}else{'Warning'})

                    if ($siemStatus.AllEnabled) {
                        Write-Console "[+] All SIEM logging enabled on remote machine!" "Success"
                    } else {
                        Write-Console "[!] Some SIEM logging disabled - attacks will still run" "Warning"
                    }
                }

                Write-Console "================================================" "Info"
                Write-Console "[+] READY FOR REMOTE EXECUTION" "Success"
                Write-Console "================================================" "Info"

                [System.Windows.Forms.MessageBox]::Show(
                    "Connection test successful!`n`n" +
                    "Computer: $($result.SystemInfo.ComputerName)`n" +
                    "OS: $($result.SystemInfo.OSVersion)`n" +
                    "PowerShell: v$($result.SystemInfo.PSVersion)`n`n" +
                    "Administrator privileges: CONFIRMED`n`n" +
                    $(if ($siemStatus.AllEnabled) { "SIEM Logging: ALL ENABLED" } else { "SIEM Logging: PARTIAL (see console)" }) + "`n`n" +
                    "You can now execute attack simulations on this remote computer.",
                    "Connection Test - Success",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

            } else {
                Write-Console "[!] Administrator privileges: MISSING" "Error"
                $script:remoteConnectionValid = $false

                $currentUser = if ($script:remoteCredential) { $script:remoteCredential.UserName } else { [System.Security.Principal.WindowsIdentity]::GetCurrent().Name }

                [System.Windows.Forms.MessageBox]::Show(
                    "Connection successful but you do NOT have Administrator privileges on $($targetComputer.Text).`n`n" +
                    "Current user: $currentUser`n`n" +
                    "Attack simulations require Administrator rights.`n`n" +
                    "Please:`n" +
                    "1. Check 'Use Alternate Credentials' checkbox`n" +
                    "2. Provide credentials with Administrator rights`n" +
                    "3. Test connection again",
                    "Insufficient Privileges",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }

        } else {
            Write-Console "[!] Connection failed: $($result.Error)" "Error"
            $script:remoteConnectionValid = $false

            $errorMessage = "Connection test failed:`n`n$($result.Error)`n`n"

            if ($result.Error -match "WinRM") {
                $errorMessage += "To enable WinRM on the target computer, run:`nEnable-PSRemoting -Force"
            } elseif ($result.Error -match "Access is denied") {
                $errorMessage += "Try using alternate credentials with Administrator rights."
            }

            [System.Windows.Forms.MessageBox]::Show(
                $errorMessage,
                "Connection Test - Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }

    } catch {
        Write-Console "[!] Unexpected error: $($_.Exception.Message)" "Error"
        $script:remoteConnectionValid = $false

        [System.Windows.Forms.MessageBox]::Show(
            "Unexpected error during connection test:`n`n$($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } finally {
        $form.Cursor = $cursor
        $testConnBtn.Enabled = $true
    }
})

$modeCombo.Add_SelectedIndexChanged({
    $selectedMode = $modeCombo.SelectedItem
    Write-Console "Mode selected: $selectedMode" "Info"

    switch ($selectedMode) {
        "Chain - Attack Lifecycle" {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $true; $countUpDown.Enabled = $false
            $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true

            # Show technique information for Chain mode
            Write-Console "-------------------------------------------" "Info"
            Write-Console "CHAIN MODE: Attack Lifecycle" "Success"

            $availableTactics = @('Discovery', 'Execution', 'Persistence', 'Privilege Escalation', 'Defense Evasion', 'Credential Access', 'Lateral Movement', 'Command and Control', 'Exfiltration')
            $chainCount = 0

            $todaySeed = (Get-Date).DayOfYear
            Write-Console "Chain mode executes 1 technique per tactic (date-based seed: $todaySeed)" "Info"
            Write-Console "Same techniques will run all day, different tomorrow" "Info"
            Write-Console "-------------------------------------------" "Info"
            Write-Console "Tactics in attack lifecycle:" "Success"

            foreach ($tactic in $availableTactics) {
                $tacticTechs = $script:techniques | Where-Object { $_.Tactic -eq $tactic }
                if ($tacticTechs) {
                    $chainCount++
                    $techList = ($tacticTechs | ForEach-Object { $_.ID }) -join ", "
                    Write-Console "  $tactic - Available: $techList" "Info"
                }
            }

            Write-Console "-------------------------------------------" "Info"
            Write-Console "Total techniques to execute: $chainCount (1 per tactic, consistent today)" "Success"
            Write-Console "-------------------------------------------" "Info"
        }
        "Random - Chaos Mode" {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $true; $countUpDown.Enabled = $true
            $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true
            Write-Console "Random mode - adjust Technique Count to select number of techniques" "Info"
        }
        "Specific Techniques Only" {
            $techniqueList.Enabled = $true; $tacticChecklist.Enabled = $false; $countUpDown.Enabled = $false
            $includeRadio.Enabled = $false; $excludeRadio.Enabled = $false
        }
        "Run All Techniques" {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $false; $countUpDown.Enabled = $false
            $includeRadio.Enabled = $false; $excludeRadio.Enabled = $false
            Write-Console "Run All mode will execute all $($script:techniques.Count) available techniques" "Info"
        }
        "Run All in Selected Tactics" {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $true; $countUpDown.Enabled = $false
            $includeRadio.Checked = $true; $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true
        }
        Default {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $true; $countUpDown.Enabled = $true
            $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true
        }
    }
})

$executeBtn.Add_Click({
    Write-Log "Execute button clicked" "INFO"
    try {
        if (-not (Test-Path $script:magnetoScriptPath)) {
            Write-Log "MAGNETO_v3.ps1 not found at: $script:magnetoScriptPath" "ERROR"
            Write-Console "MAGNETO_v3.ps1 not found. Please load the script first." "Error"
            return
        }

        # Validate Random mode technique count before starting
        if ($aptCombo.SelectedItem -eq "None" -and $modeCombo.SelectedItem -eq "Random - Chaos Mode") {
            $maxTechniques = $script:techniques.Count
            if ($countUpDown.Value -gt $maxTechniques) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Maximum number of available techniques is $maxTechniques.`n`nYour selection of $($countUpDown.Value) exceeds this limit.`n`nPlease enter a value between 1 and $maxTechniques.",
                    "Invalid Technique Count",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }
        }

        # Validate remote execution before starting
        if ($remoteCheck.Checked) {
            if ([string]::IsNullOrWhiteSpace($targetComputer.Text)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Remote execution is enabled but no target computer specified.`n`n" +
                    "Please enter a target computer name or IP address.",
                    "Remote Execution - Missing Target",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }

            if (-not $script:remoteConnectionValid) {
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Remote execution is enabled but connection has not been tested.`n`n" +
                    "Target: $($targetComputer.Text)`n`n" +
                    "Would you like to test the connection now?`n`n" +
                    "Click YES to test connection`n" +
                    "Click NO to proceed anyway (not recommended)`n" +
                    "Click CANCEL to abort",
                    "Remote Execution - Connection Not Tested",
                    [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )

                if ($result -eq 'Yes') {
                    # Trigger test connection
                    $testConnBtn.PerformClick()

                    # Check if validation succeeded
                    if (-not $script:remoteConnectionValid) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Connection test failed or insufficient privileges.`n`n" +
                            "Please review the console output and fix the issues before executing.",
                            "Remote Execution - Cannot Proceed",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        )
                        return
                    }
                } elseif ($result -eq 'Cancel') {
                    return
                }
                # If 'No', continue anyway (user accepts the risk)
            }

            Write-Console "REMOTE EXECUTION MODE ENABLED" "Success"
            Write-Console "Target: $($targetComputer.Text)" "Info"
            if ($script:remoteCredential) {
                Write-Console "Using credentials: $($script:remoteCredential.UserName)" "Info"
            } else {
                Write-Console "Using current credentials: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" "Info"
            }
        }

        $script:executedTechniques = @(); $script:completionHandled = $false; $script:generatedLogFile = $null

        Write-Log "Starting attack simulation" "INFO"
        Write-Console "================================================" "Attack"
        Write-Console "ATTACK SIMULATION INITIATING" "Attack"
        if ($aptCombo.SelectedItem -ne "None") {
            Write-Console "LAUNCHING $($aptCombo.SelectedItem) APT CAMPAIGN" "Attack"
        } elseif ($verticalCombo.SelectedItem -ne "None") {
            Write-Console "LAUNCHING $($verticalCombo.SelectedItem) INDUSTRY VERTICAL SIMULATION" "Attack"
            if ($script:industryVerticals.ContainsKey($verticalCombo.SelectedItem)) {
                $vertical = $script:industryVerticals[$verticalCombo.SelectedItem]
                Write-Console "APT Groups: $($vertical.APTGroups -join ', ')" "Info"
                Write-Console "Threats: $($vertical.PrimaryThreats[0..2] -join ', ')..." "Info"
            }
        } else {
            Write-Console "LAUNCHING ATTACK SIMULATION" "Attack"
        }
        Write-Console "================================================" "Attack"

        # Show technique count and details based on mode
        if ($verticalCombo.SelectedItem -ne "None") {
            # Industry Vertical mode - ALL techniques for this vertical
            if ($script:industryVerticals.ContainsKey($verticalCombo.SelectedItem)) {
                $vertical = $script:industryVerticals[$verticalCombo.SelectedItem]
                $verticalTechniqueIds = $vertical.Techniques
                $verticalTechniques = $script:techniques | Where-Object { $_.ID -in $verticalTechniqueIds }

                Write-Console "" "Info"
                Write-Console "MODE: Industry Vertical - $($verticalCombo.SelectedItem)" "Success"
                Write-Console "Executing ALL $($verticalTechniques.Count) techniques for this vertical" "Success"
                Write-Console "-------------------------------------------" "Info"

                foreach ($tech in $verticalTechniques) {
                    Write-Console "  $($tech.ID) - $($tech.Name) [$($tech.Tactic)]" "Info"
                }
                Write-Console "-------------------------------------------" "Info"
                Write-Console "" "Info"
            }
        } elseif ($aptCombo.SelectedItem -eq "None") {
            $selectedMode = $modeCombo.SelectedItem

            if ($selectedMode -eq "Chain - Attack Lifecycle") {
                Write-Console "" "Info"
                Write-Console "MODE: Chain - Attack Lifecycle" "Success"

                $availableTactics = @('Discovery', 'Execution', 'Persistence', 'Privilege Escalation', 'Defense Evasion', 'Credential Access', 'Lateral Movement', 'Command and Control', 'Exfiltration')
                $chainTechniques = @()

                foreach ($tactic in $availableTactics) {
                    $tacticTechs = $script:techniques | Where-Object { $_.Tactic -eq $tactic }
                    if ($tacticTechs) {
                        $selected = $tacticTechs | Get-Random -Count 1
                        $chainTechniques += $selected
                    }
                }

                Write-Console "Techniques to Execute: $($chainTechniques.Count)" "Success"
                Write-Console "-------------------------------------------" "Info"

                foreach ($tech in $chainTechniques) {
                    Write-Console "  $($tech.ID) - $($tech.Name) [$($tech.Tactic)]" "Info"
                }
                Write-Console "-------------------------------------------" "Info"
                Write-Console "" "Info"
            }
            elseif ($selectedMode -eq "Random - Chaos Mode") {
                Write-Console "" "Info"
                Write-Console "MODE: Random - Chaos Mode" "Success"
                Write-Console "Techniques to Execute: $($countUpDown.Value)" "Success"
                Write-Console "-------------------------------------------" "Info"
                Write-Console "" "Info"
            }
        }

        Start-FlashAlert

        $script:isRunning = $true; $executeBtn.Enabled = $false; $stopBtn.Enabled = $true; $progressBar.Value = 0

        # Determine simulation type for status display
        $simulationType = ""
        if ($aptCombo.SelectedItem -ne "None") {
            $simulationType = "APT CAMPAIGN: $($aptCombo.SelectedItem)"
        } elseif ($verticalCombo.SelectedItem -ne "None") {
            $simulationType = "INDUSTRY VERTICAL: $($verticalCombo.SelectedItem)"
        } elseif ($modeCombo.SelectedItem -eq "Chain - Attack Lifecycle") {
            $simulationType = "ATTACK LIFECYCLE CHAIN"
        } elseif ($modeCombo.SelectedItem -eq "Random - Chaos Mode") {
            $simulationType = "RANDOM CHAOS MODE"
        } elseif ($techniqueList.CheckedItems.Count -gt 0) {
            $simulationType = "SPECIFIC TECHNIQUES ($($techniqueList.CheckedItems.Count))"
        } else {
            $simulationType = "ATTACK SIMULATION"
        }

        $statusLabel.Text = "ATTACK IN PROGRESS - $simulationType"

        $jobParams = Build-CommandLine
        $consoleParams = ($jobParams.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join " "
        Write-Console "Command parameters: $consoleParams" "Info"
        Write-Console "Script path: $($script:magnetoScriptPath)" "Info"
        
        $scriptBlock = {
            param($ScriptPath, $Parameters)
            Push-Location (Split-Path $ScriptPath -Parent)
            try { & $ScriptPath @Parameters *>&1 } 
            finally { Pop-Location }
        }
        
        Write-Log "Starting PowerShell job" "DEBUG"
        $script:job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $script:magnetoScriptPath, $jobParams
        Write-Log "Job started with ID: $($script:job.Id)" "INFO"
        
        Write-Log "Creating monitoring timer" "DEBUG"
        $script:jobTimer = New-Object System.Windows.Forms.Timer
        $script:jobTimer.Interval = 250
        $script:jobTimer.Add_Tick({
            try {
                if (-not $script:isRunning) {
                    if ($script:jobTimer) { $script:jobTimer.Stop(); $script:jobTimer.Dispose(); $script:jobTimer = $null }
                    return
                }
                
                if ($script:job) {
                    $output = Receive-Job -Job $script:job
                    if ($output) { Process-JobOutput -OutputLines $output }
                    
                    if ($script:job.State -in @("Completed", "Failed", "Stopped") -and (-not $script:completionHandled)) {
                        Write-Log "Job state is $($script:job.State). Processing final output..." "INFO"
                        
                        $finalOutput = Receive-Job -Job $script:job
                        if ($finalOutput) { Process-JobOutput -OutputLines $finalOutput }

                        Complete-AttackSimulation -Reason "Job state changed to $($script:job.State)"
                    }
                }
            } catch { Write-Log "Timer tick error: $($_.Exception.Message)" "ERROR" }
        })
        $script:jobTimer.Start()
        Write-Log "Monitoring timer started" "DEBUG"
        
    } catch {
        Write-Log "Fatal error in executeBtn click: $($_.Exception.Message)" "ERROR"
        Stop-FlashAlert
        Write-Console "Failed to start attack simulation: $_" "Error"
        $script:isRunning = $false; $executeBtn.Enabled = $true; $stopBtn.Enabled = $false
        $statusLabel.Text = "ERROR | Failed to start simulation"; $statusLabel.ForeColor = $script:colorScheme.Error
        [System.Windows.Forms.MessageBox]::Show("Failed to start attack simulation:`n`n$($_.Exception.Message)","Execution Error", 0, 16)
    }
})

$stopBtn.Add_Click({
    try {
        Write-Console "Stopping attack simulation..." "Warning"
        Stop-FlashAlert
        if ($script:job) {
            Stop-Job -Job $script:job -EA SilentlyContinue; Remove-Job -Job $script:job -Force -EA SilentlyContinue
            $script:job = $null; Write-Console "Background job terminated" "Warning"
        }
        if ($script:jobTimer) { $script:jobTimer.Stop(); $script:jobTimer.Dispose(); $script:jobTimer = $null }
        if ($script:process -and -not $script:process.HasExited) { $script:process.Kill(); $script:process.Dispose(); $script:process = $null }
        $script:isRunning = $false; $executeBtn.Enabled = $true; $stopBtn.Enabled = $false; $progressBar.Value = 0
        $statusLabel.Text = "STOPPED | Attack simulation terminated"; $statusLabel.ForeColor = $script:colorScheme.Warning
        Write-Console "Attack simulation stopped by user" "Warning"
    }
    catch { Write-Console "Error stopping simulation: $_" "Error" }
})

$viewLogBtn.Add_Click({
    Write-Log "View Log button clicked" "INFO"
    if (Test-Path $script:logFile) {
        Write-Console "Opening verbose log file..." "Info"
        try { Start-Process notepad.exe -ArgumentList $script:logFile }
        catch { [System.Windows.Forms.MessageBox]::Show("Failed to open log file: $_`n`nLog location: $script:logFile", "Error", 0, 16) }
    }
    else { [System.Windows.Forms.MessageBox]::Show("Log file not found at: $script:logFile", "Log Not Found", 0, 48) }
})

$updateBtn.Add_Click({
    Write-Log "User manually triggered update check" "INFO"
    Write-Console "Checking for updates..." "Info"
    Check-ForUpdates
})

$siemBtn.Add_Click({
    Write-Log "SIEM Logging button clicked" "INFO"
    Write-Console "================================================" "Info"
    Write-Console "SIEM LOGGING STATUS CHECK" "Success"
    Write-Console "================================================" "Info"

    $status = Test-SiemLogging

    Write-Console "PowerShell Module Logging: $(if($status.ModuleLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($status.ModuleLogging){'Success'}else{'Warning'})
    Write-Console "PowerShell Script Block Logging: $(if($status.ScriptBlockLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($status.ScriptBlockLogging){'Success'}else{'Warning'})
    Write-Console "Command Line in Process Events: $(if($status.CommandLineLogging){'[ENABLED]'}else{'[DISABLED]'})" $(if($status.CommandLineLogging){'Success'}else{'Warning'})
    Write-Console "Process Creation Auditing: $(if($status.ProcessAuditing){'[ENABLED]'}else{'[DISABLED]'})" $(if($status.ProcessAuditing){'Success'}else{'Warning'})
    Write-Console "================================================" "Info"

    if ($status.AllEnabled) {
        Write-Console "All SIEM logging is properly configured!" "Success"
        [System.Windows.Forms.MessageBox]::Show(
            "All SIEM logging features are enabled:`n`n" +
            "[+] PowerShell Module Logging`n" +
            "[+] PowerShell Script Block Logging`n" +
            "[+] Command Line in Process Events`n" +
            "[+] Process Creation Auditing`n`n" +
            "Your SIEM will capture all attack simulation events.",
            "SIEM Logging - Status OK",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } else {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Some SIEM logging features are disabled.`n`n" +
            "PowerShell Module Logging: $(if($status.ModuleLogging){'ENABLED'}else{'DISABLED'})`n" +
            "Script Block Logging: $(if($status.ScriptBlockLogging){'ENABLED'}else{'DISABLED'})`n" +
            "Command Line Logging: $(if($status.CommandLineLogging){'ENABLED'}else{'DISABLED'})`n" +
            "Process Auditing: $(if($status.ProcessAuditing){'ENABLED'}else{'DISABLED'})`n`n" +
            "Would you like to enable all logging now?`n`n" +
            "Note: Requires Administrator privileges",
            "SIEM Logging - Configuration Needed",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($result -eq 'Yes') {
            Write-Console "Enabling SIEM logging..." "Info"

            if (Enable-SiemLogging) {
                Write-Console "SIEM logging enabled successfully!" "Success"
                Write-Console "Verifying configuration..." "Info"

                $newStatus = Test-SiemLogging
                if ($newStatus.AllEnabled) {
                    Write-Console "All settings verified and active!" "Success"
                    [System.Windows.Forms.MessageBox]::Show(
                        "SIEM logging has been enabled successfully!`n`n" +
                        "All attack simulation events will now be logged to:`n" +
                        "- Event Viewer > Windows PowerShell`n" +
                        "- Event Viewer > Microsoft-Windows-PowerShell/Operational`n" +
                        "- Event Viewer > Security (Event ID 4688)`n`n" +
                        "Your SIEM can now monitor all MAGNETO activities.",
                        "Success - SIEM Logging Enabled",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                } else {
                    Write-Console "Some settings may require a reboot to take effect" "Warning"
                }
            } else {
                Write-Console "Failed to enable SIEM logging. Check admin privileges." "Error"
                [System.Windows.Forms.MessageBox]::Show(
                    "Failed to enable SIEM logging.`n`n" +
                    "Please ensure:`n" +
                    "1. MAGNETO is running as Administrator`n" +
                    "2. Group Policy is not overriding settings`n" +
                    "3. No security software is blocking changes`n`n" +
                    "Check the console output for details.",
                    "Error - SIEM Logging Failed",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
    }
})

$exitBtn.Add_Click({
    Stop-FlashAlert
    if ($script:isRunning) {
        $result = [System.Windows.Forms.MessageBox]::Show("Attack simulation is still running. Are you sure you want to exit?", "Confirm Exit", 4, 32)
        if ($result -eq 'Yes') {
            if ($script:job) { Stop-Job -Job $script:job -EA SilentlyContinue; Remove-Job -Job $script:job -Force -EA SilentlyContinue }
            if ($script:jobTimer) { $script:jobTimer.Stop(); $script:jobTimer.Dispose() }
            if ($script:process -and -not $script:process.HasExited) { $script:process.Kill(); $script:process.Dispose() }
            $form.Close()
        }
    }
    else { $form.Close() }
})

# Initialize
Write-Log "GUI initialization starting" "INFO"
Write-Console "MAGNETO GUI v3 initialized" "Success"
Write-Console "System: $env:COMPUTERNAME | User: $env:USERNAME" "Info"
Write-Console "PowerShell Version: $($PSVersionTable.PSVersion)" "Info"
Write-Console "Log file: $script:logFile" "Info"
if ($script:nistMappingsEnabled) {
    Write-Console "[NIST] 800-53 Rev 5 Mappings Loaded (ATT&CK 16.1)" "Success"
} else {
    Write-Console "NIST mappings not available (optional feature)" "Info"
}
Write-Console "[!] Red Flash Alert Enabled for Attack Simulations [!]" "Warning"

# Check SIEM Logging Status on Startup
$siemStatus = Test-SiemLogging
if ($siemStatus.AllEnabled) {
    Write-Console "[SIEM] All logging enabled - Events will be captured" "Success"
} else {
    Write-Console "[SIEM] Logging not fully enabled - Click SIEM LOGGING button to configure" "Warning"
}

if (Test-Path $script:magnetoScriptPath) {
    Write-Console "Found MAGNETO_v3.ps1 in script directory" "Success"
    Write-Log "Auto-loading MAGNETO_v3.ps1 from: $script:magnetoScriptPath" "INFO"
    if (Load-Techniques $script:magnetoScriptPath) {
        $executeBtn.Enabled = $true
        $statusLabel.Text = "READY | Script auto-loaded successfully"
        Write-Log "MAGNETO_v3.ps1 loaded successfully" "SUCCESS"
    }
} else {
    Write-Console "MAGNETO_v3.ps1 not found in script directory. Please load manually." "Warning"
    Write-Log "MAGNETO_v3.ps1 not found in script directory: $script:magnetoScriptPath" "WARN"
    $executeBtn.Enabled = $false
}

$form.Add_FormClosing({
    param($sender, $e)
    Write-Log "Form closing event triggered" "INFO"
    Stop-FlashAlert
    if ($script:job) { Write-Log "Stopping job before closing" "INFO"; Stop-Job -Job $script:job -EA SilentlyContinue; Remove-Job -Job $script:job -Force -EA SilentlyContinue }
    if ($script:jobTimer) { Write-Log "Disposing timer before closing" "DEBUG"; $script:jobTimer.Stop(); $script:jobTimer.Dispose() }
    if ($script:flashTimer) { Write-Log "Disposing flash timer before closing" "DEBUG"; $script:flashTimer.Stop(); $script:flashTimer.Dispose() }
    if ($script:process -and -not $script:process.HasExited) { Write-Log "Killing process before closing" "INFO"; $script:process.Kill(); $script:process.Dispose() }
    Write-Log "========================================" "INFO"
    Write-Log "MAGNETO GUI Closing" "INFO"
    Write-Log "Session ended at: $(Get-Date)" "INFO"
    Write-Log "========================================" "INFO"
})

# Form Load Event - Check for updates on startup
$form.Add_Shown({
    Write-Log "Form shown, checking for updates silently..." "INFO"
    # Check for updates silently (doesn't show dialog if up-to-date)
    Check-ForUpdates -Silent
})

# Show splash screen
$splash = New-Object System.Windows.Forms.Form
$splash.FormBorderStyle = 'None'
$splash.StartPosition = 'CenterScreen'
$splash.Size = New-Object System.Drawing.Size(600, 400)
$splash.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$splash.TopMost = $true

# MAGNETO logo/title - Matrix green theme
$logoLabel = New-Object System.Windows.Forms.Label
$logoLabel.Text = "MAGNETO v3"
$logoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 48, [System.Drawing.FontStyle]::Bold)
$logoLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 65)
$logoLabel.AutoSize = $false
$logoLabel.Size = New-Object System.Drawing.Size(600, 80)
$logoLabel.TextAlign = 'MiddleCenter'
$logoLabel.Location = New-Object System.Drawing.Point(0, 60)
$splash.Controls.Add($logoLabel)

# Tagline 1
$tagline1 = New-Object System.Windows.Forms.Label
$tagline1.Text = "Living Off The Land Attack Simulator"
$tagline1.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
$tagline1.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$tagline1.AutoSize = $false
$tagline1.Size = New-Object System.Drawing.Size(600, 40)
$tagline1.TextAlign = 'MiddleCenter'
$tagline1.Location = New-Object System.Drawing.Point(0, 160)
$splash.Controls.Add($tagline1)

# Tagline 2
$tagline2 = New-Object System.Windows.Forms.Label
$tagline2.Text = "100% REAL  |  100% SAFE"
$tagline2.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$tagline2.ForeColor = [System.Drawing.Color]::FromArgb(50, 205, 50)
$tagline2.AutoSize = $false
$tagline2.Size = New-Object System.Drawing.Size(600, 40)
$tagline2.TextAlign = 'MiddleCenter'
$tagline2.Location = New-Object System.Drawing.Point(0, 210)
$splash.Controls.Add($tagline2)

# Version/Loading text
$loadingLabel = New-Object System.Windows.Forms.Label
$loadingLabel.Text = "Initializing Attack Simulation Platform..."
$loadingLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$loadingLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$loadingLabel.AutoSize = $false
$loadingLabel.Size = New-Object System.Drawing.Size(600, 30)
$loadingLabel.TextAlign = 'MiddleCenter'
$loadingLabel.Location = New-Object System.Drawing.Point(0, 320)
$splash.Controls.Add($loadingLabel)

# Timer to close splash screen
$splashTimer = New-Object System.Windows.Forms.Timer
$splashTimer.Interval = 4000  # 4 seconds
$splashTimer.Add_Tick({
    $splash.Close()
    $splashTimer.Stop()
    $splashTimer.Dispose()
})

$splash.Add_Shown({
    $splashTimer.Start()
})

Write-Log "Showing splash screen" "INFO"
$splash.ShowDialog()

Write-Log "Showing form to user" "INFO"
[System.Windows.Forms.Application]::Run($form)
Write-Log "Application terminated" "INFO"