# Test NIST Mapping Module
. "$PSScriptRoot\nist_mapping_module.ps1"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing NIST Mapping Module" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test T1003 (OS Credential Dumping)
Write-Host "Test 1: T1003 - OS Credential Dumping`n" -ForegroundColor Yellow
$summary = Get-NistControlSummary -TechniqueId "T1003"
Write-Host "Total Controls: $($summary.TotalControls)" -ForegroundColor Green
Write-Host "CSF Functions: $($summary.CSFFunctions -join ', ')" -ForegroundColor Green
Write-Host "`nFirst 5 Controls:" -ForegroundColor Cyan
$summary.Controls | Select-Object -First 5 | Format-Table capability_id, capability_description, capability_group -AutoSize

# Test T1087.001 (Local Account Discovery)
Write-Host "`nTest 2: T1087.001 - Local Account Discovery`n" -ForegroundColor Yellow
$summary2 = Get-NistControlSummary -TechniqueId "T1087.001"
Write-Host "Total Controls: $($summary2.TotalControls)" -ForegroundColor Green
Write-Host "CSF Functions: $($summary2.CSFFunctions -join ', ')" -ForegroundColor Green

# Test HTML Generation
Write-Host "`n`nTest 3: HTML Generation for T1003`n" -ForegroundColor Yellow
$html = Get-NistHtmlSection -TechniqueId "T1003"
Write-Host "HTML Length: $($html.Length) characters" -ForegroundColor Green
Write-Host "Preview (first 500 chars):" -ForegroundColor Cyan
Write-Host $html.Substring(0, [Math]::Min(500, $html.Length))

Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "All tests completed!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
