Configuration ADConfig {
    param (
        [string]$DomainName,
        [PSCredential]$AdminPassword
    )
    

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory

    Node localhost {
        # Install AD DS
        WindowsFeature ADDSInstall {
            Name                 = "AD-Domain-Services"
            IncludeAllSubFeature = $true
            Ensure               = "Present"
        }

        # Domain Structure Variables
        Import-Module ActiveDirectory
        $NetBIOSName = Get-ADDomain | Select-Object -ExpandProperty NetBIOSName
        $DomainDN = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
        $ParentOU = "OU=$NetBIOSName,$DomainDN"


        xADOrganizationalUnit "NetBIOSNameOU" {
            Name      = "$NetBIOSName"
            Path      = "$DomainDN"
            Ensure    = "Present"
        }
        xADOrganizationalUnit "GroupsOU" {
            Name      = "Groups"
            Path      = "$ParentOU"
            Ensure    = "Present"
            DependsOn = "[xADOrganizationalUnit]NetBIOSNameOU"
        }

        # Create Organizational Units
        $OUs = @("Dev", "Ops")
        foreach ($OU in $OUs) {
            xADOrganizationalUnit "$($OU)OU" {
                Name      = $OU
                Path      = "$ParentOU"
                Ensure    = "Present"
                DependsOn = "[xADOrganizationalUnit]NetBIOSNameOU"
            }

            # Create Users
            foreach ($i in 1..10) {
                xADUser "$($OU)$i" {
                    UserName          = "$($OU)$i"
                    Password          = $AdminPassword
                    DomainName        = $DomainName
                    Path              = "OU=$OU,$ParentOU"
                    Ensure            = "Present"
                    DependsOn         = "[xADOrganizationalUnit]$($OU)OU"
                    DisplayName       = "$($OU) User $i"
                    Enabled           = $true
                    UserPrincipalName = "$($OU)$i@$DomainName"
                    Department        = "$($OU) Team"
                }
            }

            # Create Groups
            xADGroup "$($OU)Group" {
                GroupName = $OU + " Team"
                Path      = "OU=Groups,$ParentOU"
                Ensure    = "Present"
                Members   = @( (1..10) | ForEach-Object { "$($OU)$_" } )
                GroupScope = "Global"
                Category = "Security"
                DependsOn = "[xADOrganizationalUnit]$($OU)OU"
            }
        }
    }
}