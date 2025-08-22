# This script automates the promotion of a Windows Server to a Domain Controller using PowerShell.

# Variables
$DomainName = "mctraining.co.uk"
$SafeModePassword = (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)

# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote the first Domain Controller
#
# Windows PowerShell script for AD DS Deployment
#
if ($env:computername -eq "DC01") {


    Import-Module ADDSDeployment
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "Win2025" `
        -DomainName "mctesting.co.uk" `
        -DomainNetbiosName "MCTESTING" `
        -ForestMode "Win2025" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -SafeModeAdministratorPassword $SafeModePassword
}

