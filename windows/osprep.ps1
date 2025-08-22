# Initialize log content
$logContent = @()

# Identify the RAW (uninitialized) disk
$disk = Get-Disk | Where-Object PartitionStyle -Eq 'RAW'

if ($disk) {
    # Initialize as GPT
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
        New-Partition -UseMaximumSize -DriveLetter S |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false

    $logContent += "Disk initialized, partitioned, and mounted as S: with label 'Data'"
} else {
    $logContent += "No RAW disk found. Skipping disk setup."
}

# Make admin directory
New-Item -Path "C:\admin" -ItemType Directory -Force
New-Item -Path "C:\admin\scripts" -ItemType Directory -Force
New-Item -Path "C:\admin\logs" -ItemType Directory -Force
New-Item -Path "C:\admin\temp" -ItemType Directory -Force
New-Item -Path "C:\admin\backup" -ItemType Directory -Force
New-Item -Path "C:\admin\config" -ItemType Directory -Force

# Set PrivacyConsentStatus during OOBE
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "PrivacyConsentStatus" -Value 1

# Disable Allow Telemetry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
$logContent += "Telemetry disabled successfully."

# Disable Windows Error Reporting
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Force
$logContent += "Windows Error Reporting disabled successfully."

# Disable Windows SmartScreen
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SmartScreenEnabled" -Value "Off" -Force
$logContent += "Windows SmartScreen disabled successfully."

# Disable Windows Update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Force
$logContent += "Windows Update disabled successfully."


# Write log content to file
$logFilePath = "C:\admin\logs\osprep.log"
$logContent | Out-File -FilePath $logFilePath -Encoding UTF8 -Force
$logContent
