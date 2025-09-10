#Requires -Module FailoverClusterDsc

<#
    .DESCRIPTION
        This example shows how to create the failover cluster on the first node.
#>

Configuration Cluster_CreateFirstNodeOfAFailoverClusterConfig
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ActiveDirectoryAdministratorCredential
    )

    Import-DscResource -ModuleName FailoverClusterDsc

    Node localhost
    {
        WindowsFeature AddFailoverFeature
        {
            Ensure = 'Present'
            Name   = 'Failover-clustering'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]AddFailoverFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
        }

        Cluster CreateCluster
        {
            Name                          = 'Cluster01'
            StaticIPAddress               = '192.168.100.20/24'

            <#
                This user must have the permission to create the CNO (Cluster Name Object) in Active Directory,
                unless it is prestaged.
            #>
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential

            DependsOn                     = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }
    }
}