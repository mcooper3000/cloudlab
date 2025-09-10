
Write-Host "Changing directory to DSC scripts..."
Set-Location -Path "c:\admin\scripts\DSC"

# Install required modules   
Install-Module PSDesiredStateConfiguration, xActiveDirectory,FailoverClusterDsc -Force -AcceptLicense -Confirm:$false

# Configuration Data
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
        }
    )
}
Clear-Host

$DomainName = Read-Host "Enter Domain Name"
$domainCred = Get-Credential -Message "Enter domain admin credentials"


. .\DCPromo.ps1
DCPromo -DomainName $DomainName -AdminPassword $domainCred -ConfigurationData $ConfigData
Start-DscConfiguration -Path .\DCPromo -Wait -Verbose -Force


. .\ADConfig.ps1
ADConfig -DomainName $DomainName -AdminPassword $domainCred -ConfigurationData $ConfigData
Start-DscConfiguration -Path .\ADConfig -Wait -Verbose -Force