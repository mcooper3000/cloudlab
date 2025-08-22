$resourceGroup = (Get-AzResourceGroup).ResourceGroupName

# Get all VMs in the resource group
$vms = Get-AzVM -ResourceGroupName $resourceGroup

$results = @()
# Loop through each VM and extract IP info
foreach ($vm in $vms) {
    $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nicName = ($nicId -split "/")[-1]
    $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup

    $privateIp = $nic.IpConfigurations[0].PrivateIpAddress
    $publicIpId = $nic.IpConfigurations[0].PublicIpAddress.Id

    if ($publicIpId) {
        $publicIpName = ($publicIpId -split "/")[-1]
        $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroup
        $publicIpAddress = $publicIp.IpAddress
    } else {
        $publicIpAddress = "None"
    }

    $results += [PSCustomObject]@{
        VMName        = $vm.Name
        PrivateIP     = $privateIp
        PublicIP      = $publicIpAddress
        Location      = $vm.Location
        ResourceGroup = $resourceGroup
    }
}

$results | Format-Table -AutoSize