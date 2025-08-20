# Initialize log content
$logContent = @()


# Make admin directory
New-Item -Path "C:\admin" -ItemType Directory -Force
New-Item -Path "C:\admin\scripts" -ItemType Directory -Force
New-Item -Path "C:\admin\logs" -ItemType Directory -Force
New-Item -Path "C:\admin\temp" -ItemType Directory -Force
New-Item -Path "C:\admin\backup" -ItemType Directory -Force
New-Item -Path "C:\admin\config" -ItemType Directory -Force

# Create a sample script in the scripts directory
$scriptContent = @"
# Sample PowerShell script
Write-Host "Hello, World!"
pause
"@

# Save the sample script
$scriptPath = "C:\admin\scripts\sample.ps1"
Set-Content -Path $scriptPath -Value $scriptContent
$logContent += "Sample script created successfully."

# Disable Allow Telemetry during OOBE
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
$logContent += "Telemetry disabled successfully."

# Disable Windows Error Reporting
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Force
$logContent += "Windows Error Reporting disabled successfully."

# Disable Windows SmartScreen
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SmartScreenEnabled" -Value "Off" -Force
$logContent += "Windows SmartScreen disabled successfully."

# Write log content to file
$logFilePath = "C:\admin\logs\osprep.log"
$logContent | Out-File -FilePath $logFilePath -Encoding UTF8 -Force
$logContent
Start-Sleep -Seconds 5
exit 0