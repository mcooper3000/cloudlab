Configuration DCPromo {
    param (
        [string]$DomainName,
        [PSCredential]$AdminPassword
    )
    $DomainNameUPN = "DC=" + $DomainName -replace '\.', ',DC='
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory

    Node localhost {
        # Install AD DS
        WindowsFeature ADDSInstall {
            Name   = "AD-Domain-Services"
            IncludeAllSubFeature = $true
            Ensure = "Present"
        }

        # Promote First Domain Controller
        if ($env:COMPUTERNAME -eq "DC01") {
            xADDomain FirstDC {
                DomainName                    = $DomainName
                DomainAdministratorCredential = $AdminPassword
                SafemodeAdministratorPassword = $AdminPassword
                ForestMode                    = "Win2025"
                DomainMode                    = "Win2025"
                DomainNetbiosName             = $DomainName.Split('.')[0].ToUpper()
                DatabasePath                  = "C:\Windows\NTDS"
                LogPath                       = "C:\Windows\NTDS"
                SysvolPath                    = "C:\Windows\SYSVOL"
                DependsOn                     = "[WindowsFeature]ADDSInstall"
            }
        }
        elseif ($env:COMPUTERNAME -eq "DC02") {
            xADDomainController AdditionalDC {
                DomainName                    = $DomainName
                DomainAdministratorCredential = $AdminPassword
                SafemodeAdministratorPassword = $AdminPassword
                IsGlobalCatalog               = $true
                DatabasePath                  = "C:\Windows\NTDS"
                LogPath                       = "C:\Windows\NTDS"
                SysvolPath                    = "C:\Windows\SYSVOL"
                DependsOn                     = "[WindowsFeature]ADDSInstall"
            }
        }
    }
}