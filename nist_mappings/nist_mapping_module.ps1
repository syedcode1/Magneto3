# NIST 800-53 to MITRE ATT&CK Mapping Module
# Auto-updating NIST control mappings for MAGNETO v3
# Version 1.0 - October 2025

# Mapping version information
$script:nistMappingVersion = @{
    Version = "16.1-rev5"
    AttackVersion = "16.1"
    NistRevision = "Rev 5"
    LastUpdate = "2025-10-02"
    SourceUrl = "https://center-for-threat-informed-defense.github.io/mappings-explorer/data/nist_800_53/attack-16.1/nist_800_53-rev5/enterprise/nist_800_53-rev5_attack-16.1-enterprise_json.json"
}

# Global mapping cache
$script:nistMappingCache = $null
$script:nistMappingPath = Join-Path $PSScriptRoot "nist_800_53_mappings.json"

# NIST Control Family Descriptions
$script:controlFamilies = @{
    "AC" = "Access Control"
    "AU" = "Audit and Accountability"
    "CA" = "Security Assessment and Authorization"
    "CM" = "Configuration Management"
    "CP" = "Contingency Planning"
    "IA" = "Identification and Authentication"
    "IR" = "Incident Response"
    "MA" = "Maintenance"
    "MP" = "Media Protection"
    "PE" = "Physical and Environmental Protection"
    "PL" = "Planning"
    "PM" = "Program Management"
    "PS" = "Personnel Security"
    "PT" = "PII Processing and Transparency"
    "RA" = "Risk Assessment"
    "SA" = "System and Services Acquisition"
    "SC" = "System and Communications Protection"
    "SI" = "System and Information Integrity"
    "SR" = "Supply Chain Risk Management"
}

# NIST CSF 2.0 Function Descriptions
$script:csfFunctions = @{
    "GOVERN" = @{
        Name = "Govern"
        Description = "Establish and monitor organization's cybersecurity risk management strategy, expectations, and policy"
    }
    "IDENTIFY" = @{
        Name = "Identify"
        Description = "Develop organizational understanding to manage cybersecurity risk"
    }
    "PROTECT" = @{
        Name = "Protect"
        Description = "Develop and implement safeguards to ensure delivery of services"
    }
    "DETECT" = @{
        Name = "Detect"
        Description = "Develop and implement activities to identify cybersecurity events"
    }
    "RESPOND" = @{
        Name = "Respond"
        Description = "Develop and implement activities to take action regarding detected cybersecurity incidents"
    }
    "RECOVER" = @{
        Name = "Recover"
        Description = "Develop and implement activities to restore capabilities impaired due to a cybersecurity incident"
    }
}

<#
.SYNOPSIS
    Loads NIST 800-53 mappings from JSON file

.DESCRIPTION
    Loads and caches the NIST 800-53 to ATT&CK mappings from the local JSON file
#>
function Load-NistMappings {
    if ($script:nistMappingCache) {
        return $script:nistMappingCache
    }

    if (!(Test-Path $script:nistMappingPath)) {
        Write-Warning "NIST mapping file not found at: $script:nistMappingPath"
        return $null
    }

    try {
        $json = Get-Content $script:nistMappingPath -Raw | ConvertFrom-Json
        $script:nistMappingCache = $json
        return $json
    } catch {
        Write-Warning "Error loading NIST mappings: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Gets NIST 800-53 controls mapped to a specific ATT&CK technique

.PARAMETER TechniqueId
    The ATT&CK technique ID (e.g., "T1003", "T1087.001")

.EXAMPLE
    Get-NistControlsForTechnique -TechniqueId "T1003"
#>
function Get-NistControlsForTechnique {
    param(
        [string]$TechniqueId
    )

    $mappings = Load-NistMappings
    if (!$mappings) {
        return @()
    }

    # Normalize technique ID (remove any whitespace)
    $TechniqueId = $TechniqueId.Trim()

    # Find all mappings for this technique
    $controls = $mappings.mapping_objects | Where-Object {
        $_.attack_object_id -eq $TechniqueId -and
        $_.mapping_type -eq "mitigates" -and
        $_.capability_id
    } | Select-Object -Property capability_id, capability_description, capability_group, comments | Sort-Object capability_id -Unique

    return $controls
}

<#
.SYNOPSIS
    Gets a summary of NIST controls mapped to a technique

.PARAMETER TechniqueId
    The ATT&CK technique ID

.OUTPUTS
    Returns a hashtable with control summary information
#>
function Get-NistControlSummary {
    param(
        [string]$TechniqueId
    )

    $controls = Get-NistControlsForTechnique -TechniqueId $TechniqueId

    if ($controls.Count -eq 0) {
        return @{
            TechniqueId = $TechniqueId
            TotalControls = 0
            Controls = @()
            ControlFamilies = @()
            CSFFunctions = @()
        }
    }

    # Group by control family
    $families = $controls | Group-Object {$_.capability_id -replace '-.*',''} |
                Select-Object @{Name='Family';Expression={$_.Name}},
                              @{Name='Count';Expression={$_.Count}}

    # Map to CSF 2.0 functions based on control families
    $csfFunctions = @()
    foreach ($family in $families) {
        switch ($family.Family) {
            { $_ -in @("AC", "IA", "SC") } {
                if ("PROTECT" -notin $csfFunctions) { $csfFunctions += "PROTECT" }
                if ("IDENTIFY" -notin $csfFunctions) { $csfFunctions += "IDENTIFY" }
            }
            { $_ -in @("AU", "CA", "SI") } {
                if ("DETECT" -notin $csfFunctions) { $csfFunctions += "DETECT" }
            }
            { $_ -in @("IR") } {
                if ("RESPOND" -notin $csfFunctions) { $csfFunctions += "RESPOND" }
            }
            { $_ -in @("CP") } {
                if ("RECOVER" -notin $csfFunctions) { $csfFunctions += "RECOVER" }
            }
            { $_ -in @("RA", "PM", "PL") } {
                if ("GOVERN" -notin $csfFunctions) { $csfFunctions += "GOVERN" }
                if ("IDENTIFY" -notin $csfFunctions) { $csfFunctions += "IDENTIFY" }
            }
            { $_ -in @("CM", "SA") } {
                if ("PROTECT" -notin $csfFunctions) { $csfFunctions += "PROTECT" }
            }
        }
    }

    return @{
        TechniqueId = $TechniqueId
        TotalControls = $controls.Count
        Controls = $controls
        ControlFamilies = $families
        CSFFunctions = $csfFunctions
    }
}

<#
.SYNOPSIS
    Generates HTML section for NIST controls

.PARAMETER TechniqueId
    The ATT&CK technique ID

.OUTPUTS
    Returns HTML string with NIST control information
#>
function Get-NistHtmlSection {
    param(
        [string]$TechniqueId
    )

    $summary = Get-NistControlSummary -TechniqueId $TechniqueId

    if ($summary.TotalControls -eq 0) {
        return ""
    }

    # Generate unique ID for this technique's section
    $sectionId = "nist-$($TechniqueId -replace '\.', '-')"

    $toggleId = "$sectionId-toggle"
    $html = @"
<div class="nist-mapping">
    <h3 class="nist-header" onclick="toggleNistSection('$sectionId')">
        <span class="nist-toggle" id="$toggleId">[+]</span> [NIST] Control Validation - $($summary.TotalControls) Controls Mapped
    </h3>
    <div class="nist-content" id="$sectionId" style="display: none;">
    <div class="nist-summary">
        <p><strong>This simulation validates $($summary.TotalControls) NIST 800-53 Rev 5 security controls</strong></p>
    </div>

    <div class="nist-controls">
        <h4>NIST 800-53 Rev 5 Controls</h4>
        <table class="nist-table">
            <thead>
                <tr>
                    <th>Control ID</th>
                    <th>Control Name</th>
                    <th>Family</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($control in $summary.Controls) {
        $familyName = $script:controlFamilies[$control.capability_group]
        $html += @"
                <tr>
                    <td><strong>$($control.capability_id)</strong></td>
                    <td>$($control.capability_description)</td>
                    <td><span class="control-family">$($control.capability_group)</span> - $familyName</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
    </div>
"@

    if ($summary.CSFFunctions.Count -gt 0) {
        $html += @"

    <div class="nist-csf">
        <h4>NIST CSF 2.0 Functions</h4>
        <div class="csf-functions">
"@

        foreach ($func in $summary.CSFFunctions) {
            $funcInfo = $script:csfFunctions[$func]
            $html += @"
            <div class="csf-function">
                <div class="csf-badge">$($funcInfo.Name)</div>
                <div class="csf-desc">$($funcInfo.Description)</div>
            </div>
"@
        }

        $html += @"
        </div>
    </div>
"@
    }

    # Add control family summary
    if ($summary.ControlFamilies.Count -gt 0) {
        $familyList = ($summary.ControlFamilies | ForEach-Object {
            "$($script:controlFamilies[$_.Family]) ($($_.Count))"
        }) -join ", "

        $html += @"

    <div class="compliance-note">
        <p>[+] <strong>Control Families Tested:</strong> $familyList</p>
        <p>[+] <strong>Compliance Coverage:</strong> $($summary.CSFFunctions.Count) CSF Functions, $($summary.TotalControls) Security Controls</p>
    </div>
"@
    }

    $html += @"
    </div>
</div>
"@

    return $html
}

<#
.SYNOPSIS
    Checks for updated NIST mappings from MITRE

.OUTPUTS
    Returns version information if newer mapping is available
#>
function Check-NistMappingUpdates {
    $versionUrl = "https://raw.githubusercontent.com/syedcode1/Magneto3/main/nist_mappings/mapping_version.json"

    try {
        $webResponse = Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $remoteVersion = $webResponse.Content | ConvertFrom-Json

        $current = $script:nistMappingVersion.Version
        $remote = $remoteVersion.version

        if ($remote -ne $current) {
            return @{
                UpdateAvailable = $true
                CurrentVersion = $current
                NewVersion = $remote
                ReleaseDate = $remoteVersion.release_date
                Changelog = $remoteVersion.changelog
                DownloadUrl = $remoteVersion.download_url
            }
        } else {
            return @{
                UpdateAvailable = $false
                CurrentVersion = $current
            }
        }
    } catch {
        Write-Warning "Could not check for NIST mapping updates: $($_.Exception.Message)"
        return @{
            UpdateAvailable = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Downloads and installs updated NIST mappings

.PARAMETER DownloadUrl
    URL to download the mapping JSON from
#>
function Update-NistMappings {
    param(
        [string]$DownloadUrl
    )

    try {
        Write-Host "Downloading updated NIST mappings..." -ForegroundColor Cyan

        # Backup current mapping
        if (Test-Path $script:nistMappingPath) {
            $backupPath = "$($script:nistMappingPath).backup"
            Copy-Item $script:nistMappingPath $backupPath -Force
            Write-Host "[+] Created backup of current mappings" -ForegroundColor Green
        }

        # Download new mapping
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $script:nistMappingPath -UseBasicParsing -ErrorAction Stop

        # Clear cache to force reload
        $script:nistMappingCache = $null

        # Test load the new mapping
        $testLoad = Load-NistMappings
        if ($testLoad) {
            Write-Host "[+] Successfully updated NIST mappings" -ForegroundColor Green
            return $true
        } else {
            throw "Failed to load new mapping file"
        }
    } catch {
        Write-Error "Failed to update NIST mappings: $($_.Exception.Message)"

        # Restore backup if it exists
        $backupPath = "$($script:nistMappingPath).backup"
        if (Test-Path $backupPath) {
            Copy-Item $backupPath $script:nistMappingPath -Force
            Write-Host "[-] Restored previous mapping from backup" -ForegroundColor Yellow
        }

        return $false
    }
}

# Functions are auto-exported when dot-sourced
