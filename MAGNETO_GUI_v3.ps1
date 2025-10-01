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
$script:originalStatusFont = $null  # Store original font
$script:originalStatusColor = $null  # Store original color
$script:completionHandled = $false  # Track if completion has been handled
$script:generatedLogFile = $null  # Track the generated log file path
$script:aptCampaigns = @{
    "None" = @{Name="Standard MAGNETO Mode"; Description="Use standard technique selection"; Techniques=@()}
    "APT41" = @{Name="Shadow Harvest"; Description="Chinese espionage with Google Calendar C2"; Techniques=@("T1049", "T1087.001", "T1218.011", "T1546.015", "T1055.100", "T1550.002", "T1021.002", "T1041")}
    "Lazarus" = @{Name="DEV#POPPER"; Description="North Korean financial targeting"; Techniques=@("T1574.002", "T1053.005", "T1003.003", "T1021.002", "T1560.002")}
    "APT29" = @{Name="GRAPELOADER"; Description="Russian diplomatic espionage"; Techniques=@("T1546.015", "T1053.005", "T1134.001", "T1070.004")}
    "StealthFalcon" = @{Name="Project Raven"; Description="Middle East dissident targeting"; Techniques=@("T1548.002", "T1027", "T1112")}
    "FIN7" = @{Name="Carbanak"; Description="Financial crime syndicate"; Techniques=@("T1059.001", "T1105", "T1543.003")}
    "APT28" = @{Name="Fancy Bear"; Description="Russian military intelligence"; Techniques=@("T1059.001", "T1548.002", "T1021.002")}
}

# Initialize Logging and Artifacts folders
$script:logPath = Join-Path $PSScriptRoot "MAGNETO_GUI_Logs"
if (-not (Test-Path $script:logPath)) {
    New-Item -ItemType Directory -Path $script:logPath -Force | Out-Null
}
$script:artifactsPath = Join-Path $PSScriptRoot "artifacts"
if (-not (Test-Path $script:artifactsPath)) {
    New-Item -ItemType Directory -Path $script:artifactsPath -Force | Out-Null
}
$script:logFile = Join-Path $script:logPath "MAGNETO_GUI_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:verboseLogging = $true

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
$form.Size = New-Object System.Drawing.Size(1400, 900)
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
    $bannerImage.Size = New-Object System.Drawing.Size(1360, 100)
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
    $bannerLabel.Size = New-Object System.Drawing.Size(1360, 100)
    $bannerLabel.ForeColor = $script:colorScheme.Warning
    $bannerLabel.Font = $script:fontTitle
    $bannerLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($bannerLabel)
}

# Status Bar
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "READY | Breach. Evade. Exfil. All Native. All Stealth."
$statusLabel.Location = New-Object System.Drawing.Point(20, 110)
$statusLabel.Size = New-Object System.Drawing.Size(1360, 25)
$statusLabel.ForeColor = $script:colorScheme.Accent
$statusLabel.Font = $script:fontBold
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusLabel.BackColor = $script:colorScheme.Surface
$statusLabel.BorderStyle = 'FixedSingle'
$form.Controls.Add($statusLabel)

# Left Panel - Configuration (Original layout)
$configPanel = New-StyledPanel -Title "[CONFIG] CONFIGURATION" -X 20 -Y 150 -Width 400 -Height 350
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
    $aptCombo.Items.Add($_)
}
$aptCombo.SelectedItem = "None"
$configPanel.Controls.Add($aptCombo)

# Mode Selection
$modeLabel = New-Object System.Windows.Forms.Label
$modeLabel.Text = "ATTACK MODE:"
$modeLabel.Location = New-Object System.Drawing.Point(15, 55)
$modeLabel.Size = New-Object System.Drawing.Size(100, 20)
$modeLabel.ForeColor = $script:colorScheme.Text
$configPanel.Controls.Add($modeLabel)

$modeCombo = New-Object System.Windows.Forms.ComboBox
$modeCombo.Location = New-Object System.Drawing.Point(120, 53)
$modeCombo.Size = New-Object System.Drawing.Size(250, 25)
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
$countLabel.Location = New-Object System.Drawing.Point(15, 90)
$countLabel.Size = New-Object System.Drawing.Size(140, 20)
$countLabel.ForeColor = $script:colorScheme.Text
$countLabel.BackColor = [System.Drawing.Color]::Transparent
$configPanel.Controls.Add($countLabel)

$countUpDown = New-Object System.Windows.Forms.NumericUpDown
$countUpDown.Location = New-Object System.Drawing.Point(160, 88)
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
$delayLabel.Location = New-Object System.Drawing.Point(250, 90)
$delayLabel.Size = New-Object System.Drawing.Size(70, 20)
$delayLabel.ForeColor = $script:colorScheme.Text
$delayLabel.BackColor = [System.Drawing.Color]::Transparent
$configPanel.Controls.Add($delayLabel)

$delayUpDown = New-Object System.Windows.Forms.NumericUpDown
$delayUpDown.Location = New-Object System.Drawing.Point(320, 88)
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
$cleanupCheck.Location = New-Object System.Drawing.Point(15, 125)
$cleanupCheck.Size = New-Object System.Drawing.Size(300, 25)
$cleanupCheck.ForeColor = $script:colorScheme.Warning
$cleanupCheck.Checked = $true
$configPanel.Controls.Add($cleanupCheck)

# Admin Mode Indicator
$adminLabel = New-Object System.Windows.Forms.Label
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminLabel.Text = if ($isAdmin) { "[OK] ADMIN MODE ACTIVE" } else { "[!] LIMITED MODE (Non-Admin)" }
$adminLabel.Location = New-Object System.Drawing.Point(15, 160)
$adminLabel.Size = New-Object System.Drawing.Size(250, 25)
$adminLabel.ForeColor = if ($isAdmin) { $script:colorScheme.Success } else { $script:colorScheme.Warning }
$adminLabel.Font = $script:fontBold
$configPanel.Controls.Add($adminLabel)

# Domain Status
$domainLabel = New-Object System.Windows.Forms.Label
$isDomain = ($env:USERDOMAIN -ne $env:COMPUTERNAME)
$domainLabel.Text = if ($isDomain) { "[OK] DOMAIN JOINED" } else { "[--] STANDALONE SYSTEM" }
$domainLabel.Location = New-Object System.Drawing.Point(15, 185)
$domainLabel.Size = New-Object System.Drawing.Size(250, 25)
$domainLabel.ForeColor = if ($isDomain) { $script:colorScheme.Success } else { $script:colorScheme.TextDim }
$domainLabel.Font = $script:fontBold
$configPanel.Controls.Add($domainLabel)

# Tactic Filter Section
$tacticFilterLabel = New-Object System.Windows.Forms.Label
$tacticFilterLabel.Text = "TACTIC FILTERS:"
$tacticFilterLabel.Location = New-Object System.Drawing.Point(15, 220)
$tacticFilterLabel.Size = New-Object System.Drawing.Size(150, 20)
$tacticFilterLabel.ForeColor = $script:colorScheme.Accent
$tacticFilterLabel.Font = $script:fontBold
$configPanel.Controls.Add($tacticFilterLabel)

# Include/Exclude Radio Buttons
$includeRadio = New-Object System.Windows.Forms.RadioButton
$includeRadio.Text = "Include"
$includeRadio.Location = New-Object System.Drawing.Point(170, 220)
$includeRadio.Size = New-Object System.Drawing.Size(80, 20)
$includeRadio.ForeColor = $script:colorScheme.Success
$includeRadio.Checked = $false
$configPanel.Controls.Add($includeRadio)

$excludeRadio = New-Object System.Windows.Forms.RadioButton
$excludeRadio.Text = "Exclude"
$excludeRadio.Location = New-Object System.Drawing.Point(250, 220)
$excludeRadio.Size = New-Object System.Drawing.Size(80, 20)
$excludeRadio.ForeColor = $script:colorScheme.Error
$excludeRadio.Checked = $true
$configPanel.Controls.Add($excludeRadio)

# Tactic Checklist
$tacticChecklist = New-Object System.Windows.Forms.CheckedListBox
$tacticChecklist.Location = New-Object System.Drawing.Point(15, 245)
$tacticChecklist.Size = New-Object System.Drawing.Size(365, 90)
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
$techniquePanel = New-StyledPanel -Title "[TARGET] TECHNIQUE SELECTION" -X 440 -Y 150 -Width 500 -Height 350
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
$techniqueList.Size = New-Object System.Drawing.Size(470, 275)
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

# Console Output Panel
$consolePanel = New-StyledPanel -Title "[CONSOLE] OUTPUT" -X 20 -Y 510 -Width 1360 -Height 280
$form.Controls.Add($consolePanel)

$consoleOutput = New-Object System.Windows.Forms.TextBox
$consoleOutput.Location = New-Object System.Drawing.Point(15, 25)
$consoleOutput.Size = New-Object System.Drawing.Size(1330, 245)
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
$controlPanel.Location = New-Object System.Drawing.Point(20, 800)
$controlPanel.Size = New-Object System.Drawing.Size(1360, 50)
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

# Export Log Button
$exportBtn = New-StyledButton -Text "[>] EXPORT LOG" -X 830 -Y 7 -Width 130 -Height 36
$controlPanel.Controls.Add($exportBtn)

# View Log Button
$viewLogBtn = New-StyledButton -Text "[?] VIEW LOG" -X 970 -Y 7 -Width 100 -Height 36
$controlPanel.Controls.Add($viewLogBtn)

# Check for Updates Button
$updateBtn = New-StyledButton -Text "[↻] CHECK UPDATES" -X 1080 -Y 7 -Width 150 -Height 36
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
                $techniqueList.Items.Add($displayText)
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
        $tacticBreakdown += "> $($group.Name): $($group.Count) techniques`r`n"
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
    
    $statsText.Text = @"
===========================================
  SYSTEM ANALYSIS COMPLETE
===========================================

> AVAILABLE TECHNIQUES: $totalTechniques
> ADMIN REQUIRED: $adminRequired
> DOMAIN REQUIRED: $domainRequired

-------------------------------------------
TACTIC BREAKDOWN:
-------------------------------------------

$tacticBreakdown
-------------------------------------------
CURRENT SELECTION:
-------------------------------------------

$selectedInfo$aptInfo
===========================================
"@

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
        .details { margin-top: 10px; padding-left: 10px; border-left: 2px solid #ffff00; color: #ccc; font-size: 0.9em; }
        .details-label { color: #ffff00; font-weight: bold; }
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
            <span class="legend-active">● Highlighted tactics</span> indicate areas covered by this simulation
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
    </div>
"@
    }
    
    $html += @"
    <div class="footer">
        <p>MAGNETO v3 - Advanced APT Campaign Simulator</p>
        <p>Report generated by MAGNETO GUI</p>
    </div>
</body>
</html>
"@
    
    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "HTML report generated: $OutputPath" "SUCCESS"
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
    if ($selectedAPT -ne "None") {
        Write-Log "APT Campaign selected: $selectedAPT" "INFO"
        $params.APTCampaign = $selectedAPT
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
    
    $logString = $params.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" } | Out-String
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

        $reportPath = Join-Path $PSScriptRoot "MAGNETO_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
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
    
    if ($script:generatedLogFile -and (Test-Path $script:generatedLogFile)) {
        try {
            $logFileName = Split-Path $script:generatedLogFile -Leaf
            if (-not (Get-Process notepad -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*$($logFileName)*" })) {
                Start-Process notepad.exe -ArgumentList $script:generatedLogFile
                Write-Console "Opening log file: $script:generatedLogFile" "Info"
            }
        } catch {
            Write-Log "Failed to open log file: $_" "ERROR"
        }
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
    Write-Console "✅ ATTACK SIMULATION COMPLETE" "Success"
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
            $logFileName = $matches[1].Trim()
            $script:generatedLogFile = Join-Path $PSScriptRoot $logFileName
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
        $modeCombo.Enabled = $true; $techniqueList.Enabled = $true; $countUpDown.Enabled = $true
        $tacticChecklist.Enabled = $true; $includeRadio.Enabled = $true; $excludeRadio.Enabled = $true
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
$selectAllBtn.Add_Click({ for ($i = 0; $i -lt $techniqueList.Items.Count; $i++) { $techniqueList.SetItemChecked($i, $true) }; Update-Statistics })
$selectNoneBtn.Add_Click({ for ($i = 0; $i -lt $techniqueList.Items.Count; $i++) { $techniqueList.SetItemChecked($i, $false) }; Update-Statistics })
$techniqueList.Add_ItemCheck({ Start-Sleep -Milliseconds 100; Update-Statistics })
$modeCombo.Add_SelectedIndexChanged({
    $selectedMode = $modeCombo.SelectedItem
    switch ($selectedMode) {
        "Specific Techniques Only" {
            $techniqueList.Enabled = $true; $tacticChecklist.Enabled = $false; $countUpDown.Enabled = $false
            $includeRadio.Enabled = $false; $excludeRadio.Enabled = $false
        }
        "Run All Techniques" {
            $techniqueList.Enabled = $false; $tacticChecklist.Enabled = $false; $countUpDown.Enabled = $false
            $includeRadio.Enabled = $false; $excludeRadio.Enabled = $false
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
        
        $script:executedTechniques = @(); $script:completionHandled = $false; $script:generatedLogFile = $null
        
        Write-Log "Starting attack simulation" "INFO"
        Write-Console "================================================" "Attack"
        Write-Console "ATTACK SIMULATION INITIATING" "Attack"
        if ($aptCombo.SelectedItem -ne "None") { Write-Console "LAUNCHING $($aptCombo.SelectedItem) APT CAMPAIGN" "Attack" }
        else { Write-Console "LAUNCHING ATTACK SIMULATION" "Attack" }
        Write-Console "================================================" "Attack"
        
        Start-FlashAlert
        
        $script:isRunning = $true; $executeBtn.Enabled = $false; $stopBtn.Enabled = $true; $progressBar.Value = 0
        $statusLabel.Text = "ATTACK IN PROGRESS - SIMULATION RUNNING"
        
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

$exportBtn.Add_Click({
    Write-Log "Export button clicked" "INFO"
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "Text Files (*.txt)|*.txt|Log Files (*.log)|*.log|All Files (*.*)|*.*"
    $saveFileDialog.FileName = "MAGNETO_GUI_Console_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        try {
            $consoleOutput.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
            Write-Console "Log exported to: $($saveFileDialog.FileName)" "Success"
            Write-Log "Console output exported to: $($saveFileDialog.FileName)" "SUCCESS"
            [System.Windows.Forms.MessageBox]::Show("Log exported successfully!", "Export Complete", 0, 64)
        }
        catch { Write-Console "Failed to export log: $_" "Error" }
    }
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
Write-Console "⚡ Red Flash Alert Enabled for Attack Simulations ⚡" "Warning"

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

Write-Log "Showing form to user" "INFO"
[System.Windows.Forms.Application]::Run($form)
Write-Log "Application terminated" "INFO"