# This script automates the promotion of a Windows Server to a Domain Controller using PowerShell.

# Variables
$DomainName = "mctraining.co.uk"
$SafeModePassword = (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)

# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote the server to a Domain Controller
Install-ADDSForest `
    -DomainName $DomainName `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force `
    -InstallDns