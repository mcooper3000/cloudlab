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


# Deploy the ARM template
# Define parameters for the ARM template deployment
$templateFile = ".\Templates\windows-lab-template.json"

# Prompt for the computer name
$computerName = Read-Host -Prompt "Enter the computer name for the VM [Blank]"
if ($computerName -eq "") {
    $adminUsername = "trainer" # Default admin username
    [array]$Servers = "dc01", "dc02", "mem01", "mem02"
    $location = "West US"
    $vmSize = "Standard_D2s_v3"
    $windowsOSVersion = "2025-Datacenter"
    $addressPrefix = "10.0.0.0/16"
    $subnetPrefix = "10.0.0.0/24"
}

# Prompt for admin credentials
if (!$adminUsername) {
    $adminUsername = Read-Host -Prompt "Enter the local admin username to set i.e. [trainer]"
}
$adminPassword = Read-Host -Prompt "Enter the $adminUsername password to set" -AsSecureString
# Convert SecureString to plain text
$plainAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
)


# Prompt for additional parameters
if ($computerName) {
    $validRegions = @("Canada East", "Central US", "East US", "East US 2", "North Central US", "South Central US", "West Central US", "West US 2")
    $DefaultLocation = "West US"
    $location = Read-Host -Prompt "Enter the Azure region (e.g. $($validRegions -join ', ') [$DefaultLocation])"
    if (-not $location) {
        $location = $DefaultLocation
        Write-Host "No region entered. Defaulting to $DefaultLocation." -ForegroundColor Yellow
    }
    elseif (-Not ($validRegions -contains $location)) {
        Write-Host "Invalid region selected. Please choose from the following: $($validRegions -join ', ')" -ForegroundColor Red
        exit 1
    }

    $validVmSizes = @("Standard_A0", "Standard_A1_v2", "Standard_B1ms", "Standard_B1s", "Standard_B2ms", "Standard_B2s", "Standard_D1_v2", "Standard_DS1_v2", "Standard_D2", "Standard_DS1", "Standard_D2s_v3", "Standard_DS3_v2", "Standard_F2")
    $DefaultvmSize = "Standard_D2s_v3"
    $vmSize = Read-Host -Prompt "Enter the VM size (e.g. $($validVmSizes -join ', ') [$DefaultvmSize])"
    if (-not $vmSize) {
        $vmSize = $DefaultvmSize
        Write-Host "No VM size entered. Defaulting to $DefaultvmSize." -ForegroundColor Yellow
    }
    elseif (-not ($validVmSizes -contains $vmSize)) {
        Write-Host "Invalid VM size selected. Please choose from the following: $($validVmSizes -join ', ')" -ForegroundColor Red
        exit 1
    }

    $validWindowsOSVersions = @("2022-Datacenter", "2025-Datacenter", "2019-Datacenter", "2016-Datacenter")
    $DefaultWindowsOSVersion = "2025-Datacenter"
    $windowsOSVersion = Read-Host -Prompt "Enter the Windows OS version (e.g., $($validWindowsOSVersions -join ', ') [$DefaultWindowsOSVersion])"
    if (-not $windowsOSVersion) {
        $windowsOSVersion = $DefaultWindowsOSVersion
        Write-Host "No Windows OS version entered. Defaulting to $DefaultWindowsOSVersion." -ForegroundColor Yellow
    }
    elseif (-not ($validWindowsOSVersions -contains $windowsOSVersion)) {
        Write-Host "Invalid Windows OS version selected. Please choose from the following: $($validWindowsOSVersions -join ', ')" -ForegroundColor Red
        exit 1
    }

    $addressPrefix = "10.0.0.0/16" # Default address prefix
    $subnetPrefix = Read-Host -Prompt "Enter the subnet address prefix (e.g., 10.0.0.0/24)"
    if (-not $subnetPrefix) {
        $subnetPrefix = "10.0.0.0/24"
        Write-Host "No subnet prefix entered. Defaulting to 10.0.0.0/24." -ForegroundColor Yellow
    }
    elseif (-not ($validSubnetPrefixes -contains $subnetPrefix)) {
        Write-Host "Invalid subnet prefix selected. Please choose from the following: $($validSubnetPrefixes -join ', ')" -ForegroundColor Red
        exit 1
    }
}
elseif ([string]::IsNullOrWhiteSpace($computerName)) {
    [array]$computerName = $Servers
}

################################################
$startTime = Get-Date

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

<# Deploy the ARM template for each computer
foreach ($Computer in $computerName) {
    # Configure each computer
    Write-Host "Configuring $Computer..." -ForegroundColor Cyan
    # Pass these parameters to the ARM template
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
    }
    Write-Host "Deploying ARM template to resource group: $ResourceGroupName..." -ForegroundColor Cyan
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $TemplateParameters -ErrorAction Stop

    Write-Host "Deployment of $Computer completed successfully." -ForegroundColor Green

}
#>
################################################

$jobs = @()
foreach ($Computer in $computerName) {
    Write-Host "Starting deployment for $Computer..." -ForegroundColor Cyan
    $job = Start-Job -ScriptBlock {
        param($Computer, $adminUsername, $plainAdminPassword, $location, $vmSize, $windowsOSVersion, $addressPrefix, $subnetPrefix, $storageAccountName, $ResourceGroupName, $TemplateFile)

        

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
        }

        $result = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
            -TemplateFile $TemplateFile `
            -TemplateParameterObject $TemplateParameters `
            -Name "deploy-$Computer" `
            -ErrorAction Stop
        
        return $result

    } -ArgumentList $Computer, $adminUsername, $plainAdminPassword, $location, $vmSize, $windowsOSVersion, $addressPrefix, $subnetPrefix, $storageAccountName, $ResourceGroupName, $TemplateFile -Name $computer

    $jobs += $job
}

# Wait for all jobs to complete
$jobs | ForEach-Object { Wait-Job $_ }

# Retrieve job results
$jobs | ForEach-Object {
    Receive-Job $_
    Remove-Job $_
} | select Name,State,PSBeginTime,PSEndTime,@{Name="Duration";Expression={New-TimeSpan -Start $_.PSBeginTime -End $_.PSEndTime}}


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
