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
$computerName = Read-Host -Prompt "Enter the computer name for the VM"

# Prompt for admin credentials
$adminUsername = "trainer" # Replace with dynamic input if needed
$adminPassword = Read-Host -Prompt "Enter the local trainer password to set" -AsSecureString
# Convert SecureString to plain text
$plainAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
)


# Prompt for additional parameters

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

# Pass these parameters to the ARM template
$DeploymentDetails = Deploy-ArmTemplate -ResourceGroupName $resourceGroupName `
                   -TemplateFile $templateFile `
                   -TemplateParameters @{
                       "vmName" = $computerName
                       "adminUsername" = $adminUsername
                       "adminPassword" = $plainAdminPassword
                       "location" = $location
                       "vmSize" = $vmSize
                       "windowsOSVersion" = $windowsOSVersion
                       "addressPrefix" = $addressPrefix
                       "subnetPrefix" = $subnetPrefix
                   }
Write-Host "Deployment complete. Training lab is ready."


# Retrieve the public IP address of the VM
$vmPublicIP = $DeploymentDetails.Outputs.vmPublicIP.Value

if (-not $vmPublicIP) {
    Write-Host "Unable to retrieve the public IP address of the VM." -ForegroundColor Red
    exit 1
}

# Start the RDP session
Write-Host "Starting RDP session to $vmPublicIP..."
Start-Process mstsc -ArgumentList "/v:$vmPublicIP /admin /f"