# Disable Allow Telemetry during OOBE
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
Write-Host "Telemetry disabled successfully."

# Disable Windows Error Reporting
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Force
Write-Host "Windows Error Reporting disabled successfully."

# Disable Windows Defender
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Force
Write-Host "Windows Defender disabled successfully."

# Disable Windows SmartScreen
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SmartScreenEnabled" -Value "Off" -Force
Write-Host "Windows SmartScreen disabled successfully."

# Disable Windows Update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Force
Write-Host "Windows Update disabled successfully."

# Disable OneDrive
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Force
Write-Host "OneDrive disabled successfully."

# Disable Windows Feedback
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Feedback" -Name "Disabled" -Value 1 -Force
Write-Host "Windows Feedback disabled successfully."

# Disable Windows Ink Workspace
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Name "AllowWindowsInkWorkspace" -Value 0 -Force
Write-Host "Windows Ink Workspace disabled successfully."

# Disable Remote Assistance
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Remote Assistance" -Name "Disabled" -Value 1 -Force
Write-Host "Remote Assistance disabled successfully."

# Disable Windows Media Player
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Media Player" -Name "DisableMediaPlayer" -Value 1 -Force
Write-Host "Windows Media Player disabled successfully."

# Disable Windows Media Center
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Media Center" -Name "DisableMediaCenter" -Value 1 -Force
Write-Host "Windows Media Center disabled successfully."

# Disable Windows Photo Viewer
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Photo Viewer" -Name "DisablePhotoViewer" -Value 1 -Force
Write-Host "Windows Photo Viewer disabled successfully."

# Disable Windows Fax and Scan
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Fax" -Name "DisableFax" -Value 1 -Force
Write-Host "Windows Fax and Scan disabled successfully."

# Disable Windows Media Player Network Sharing Service
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Media Player" -Name "DisableNetworkSharing" -Value 1 -Force
Write-Host "Windows Media Player Network Sharing Service disabled successfully."

#  Disable Windows Remote Management
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -Name "AllowUnencryptedTraffic" -Value 0 -Force
Write-Host "Windows Remote Management disabled successfully."

# Disable Windows Remote Assistance
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fAllowUnsolicited" -Value 0 -Force
Write-Host "Windows Remote Assistance disabled successfully."

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
Write-Host "Sample script created successfully."

