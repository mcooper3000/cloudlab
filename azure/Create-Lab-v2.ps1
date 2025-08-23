Clear-Host
Clear-History
# Change to the azure directory if not already there
if ((Get-Location).Path -notmatch "azure$" ) {
    Write-Host "Changing directory to azure..."
    Set-Location -Path "$((Get-Location).Path)\azure"
}

# Load the functions script
$functionsPath = ".\functions.ps1"
if (-Not (Test-Path $functionsPath)) {
    Write-Host "The functions.ps1 file was not found at $functionsPath. Please ensure it exists." -ForegroundColor Red
    exit 1
}
. $functionsPath

# Authenticate to Azure
if (!$Azure) {
    $Azure = Connect-Azure
}

# Get the current Azure subscription
$AzSubscription = Get-AzSubscription

Set-AzContext -SubscriptionId $AzSubscription.Id

# Locate the resource group
$resourceGroup = Get-AzResourceGroup
$resourceGroupName = $resourceGroup.ResourceGroupName

# Get the location
$Location = $resourceGroup.Location

# Define parameters
# Import VM hostnames from CSV
$vmHosts = Import-Csv ".\vmHosts.csv"

# Prompt for admin credentials
$adminUsername = "trainer" # Default admin username
$adminPassword = Read-Host -Prompt "Enter the $adminUsername password to set" -AsSecureString
# Convert SecureString to plain text
$plainAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
)


$startTime = Get-Date

###################################################################################################
# Configure Storage Account
$storageAccountNamePrefix = "mctesting"
$existingStorageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName | Where-Object { $_.StorageAccountName -like "$storageAccountNamePrefix*" } -ErrorAction SilentlyContinue
if ($existingStorageAccounts) {
    Write-Host "Storage account '$storageAccountName' already exists." -ForegroundColor Green
    $storageAccountName = $existingStorageAccounts[0].StorageAccountName
}
else {
    $storageAccountName = "$storageAccountNamePrefix$(Get-Random  -Minimum 11111 -Maximum 999999 )"
    write-Host "Creating storage account '$storageAccountName'..." -ForegroundColor Cyan
    New-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $storageAccountName `
        -Location $Location `
        -SkuName "Standard_LRS" `
        -Kind "StorageV2" `
        -AccessTier "Hot" -AllowBlobPublicAccess $true | Out-Null
    Write-Host "Storage account '$storageAccountName' created successfully." -ForegroundColor Green
    $existingStorageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName | Where-Object { $_.StorageAccountName -like "$storageAccountName" } -ErrorAction SilentlyContinue
}

# Enable public blob access
Set-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $storageAccountName `
    -AllowBlobPublicAccess $true | out-null

# Get storage context
$ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

# List containers to verify
$containerName = "buildartifacts"
$containers = Get-AzStorageContainer -Context $ctx -Name $containerName -ErrorAction SilentlyContinue
if ($containers) {
    Write-Host "Container '$containerName' already exists." -ForegroundColor Green
}
else {
    # Create the container
    write-Host "Creating container '$containerName'..." -ForegroundColor Cyan
    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Off  | Out-Null
}

# Set container ACL
Set-AzStorageContainerAcl `
    -Name "buildartifacts" `
    -Context $ctx `
    -Permission Blob

# Upload all files recursively
$localFolder = "..\windows"
Get-ChildItem -Path $localFolder -Recurse | ForEach-Object {
    write-Host "Uploading $($_.FullName) to container '$containerName'..." -ForegroundColor Cyan
    Set-AzStorageBlobContent -File $_.FullName -Container $containerName -Blob $_.Name -Context $ctx -Force  | Out-Null
}

$check = Invoke-WebRequest -Uri "https://$($storageAccountName).blob.core.windows.net/$($containerName)/osprep.ps1" -UseBasicParsing
if ($check.StatusCode -eq 200) {
    Write-Host "File 'osprep.ps1' exists in the container." -ForegroundColor Green
}
else {
    Write-Host "File 'osprep.ps1' does not exist in the container." -ForegroundColor Red
    break
}
###################################################################################################


# Start deployment jobs
$jobs = @()
foreach ($Computer in $vmHosts) {
    Write-Host "Starting deployment for $Computer..." -ForegroundColor Cyan
    $job = Start-Job -ScriptBlock {
        param($Computer, $adminUsername, $plainAdminPassword, $location, $vmSize, $windowsOSVersion, $addressPrefix, $subnetPrefix, $storageAccountName, $ResourceGroupName, $armTemplate,$vlanName)

        $templateFile = ".\Templates\$armTemplate"

        $TemplateParameters = @{
            "vmName"           = $Computer
            "adminUsername"    = $adminUsername
            "adminPassword"    = $plainAdminPassword
            "location"         = $location
            "vmSize"           = $vmSize
            "windowsOSVersion" = $windowsOSVersion
            "addressPrefix"    = $addressPrefix
            "subnetPrefix"     = $subnetPrefix
            "storageAccount"   = $storageAccountName
            "vlanName"         = $vlanName
        }

        $result = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
            -TemplateFile $TemplateFile `
            -TemplateParameterObject $TemplateParameters `
            -Name "deploy-$Computer" `
            -ErrorAction Stop
        
        return $result

    } -ArgumentList $Computer.computerName, $adminUsername, $plainAdminPassword, $Computer.location, $Computer.vmSize, $Computer.OSVersion, $Computer.addressPrefix, $Computer.subnetPrefix, $storageAccountName, $ResourceGroupName, $Computer.armTemplate,$Computer.vlanName -Name $computer

    $jobs += $job
}

# Wait for all jobs to complete
$jobs | ForEach-Object { Wait-Job $_ } | Select-Object Name,State

# Retrieve job results
$jobs | ForEach-Object {
    Receive-Job $_
    Remove-Job $_
} | Select-Object Name,State,PSBeginTime,PSEndTime,@{Name="Duration";Expression={New-TimeSpan -Start $_.PSBeginTime -End $_.PSEndTime}}


$endTime = Get-Date
$duration = New-timespan $endTime  $startTime
Write-Host "Deployment completed in $($duration.TotalMinutes) minutes." -ForegroundColor Green


################################################
# Retrieve the public IP address of the VM
$vmPublicIPs = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName
$AvailableIPs = $vmPublicIPs.Name | % { $_.split("-")[0] }

$targetVm = Read-Host "Enter the name of the VM to RDP to ($($AvailableIPs -join ","))"
$targetVM = $vmPublicIPs | Where-Object { $_.Name -match $targetVm } 
if (-not $targetVM.IpAddress) {
    Write-Host "Unable to retrieve the public IP address of the VM." -ForegroundColor Red
}
else {
    Write-Host "Public IP address of the VM is: " -ForegroundColor Green 
    $targetVM.IpAddress

    # Start the RDP session
    Write-Host "Starting RDP session to $($targetVM.IpAddress)..."

    Start-Process mstsc -ArgumentList "/v:$($targetVM.IpAddress) /admin /f"


    New-RdpSession -IPAddress $targetVM.IpAddress -Username $adminUsername

}
