# This script automates the promotion of a Windows Server to a Domain Controller using PowerShell.

# Variables
$DomainName = Read-Host "Enter the domain name"
$SafeModePassword = Read-Host "Enter the Safe Mode Administrator Password" -AsSecureString

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
        -DomainName $DomainName `
        -DomainNetbiosName $DomainName.Split('.')[0].ToUpper() `
        -ForestMode "Win2025" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -SafeModeAdministratorPassword $SafeModePassword
}
