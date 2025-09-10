Configuration DCPromo {
    param (
        [string]$DomainName,
        [PSCredential]$AdminPassword
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory

    xADComputer "JoinComputer" {
        ComputerName =  $env:COMPUTERNAME
        Ensure = "Present"
        Location = "OU=Computers,$DomainDN"
    }

}