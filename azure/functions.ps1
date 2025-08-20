<#
.SYNOPSIS
This script contains functions to provision an Azure lab environment using ARM templates.
It provisions domain controllers, member servers, and client systems in a reusable manner.

.DESCRIPTION
The script uses Azure Resource Manager (ARM) templates to deploy resources in a structured way.
Functions are modular to allow reuse and customization.

#>

# Load the Az module
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Host "Installing Az module..." -ForegroundColor Yellow
    Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}
Import-Module -Name Az -ErrorAction Stop

# Function to authenticate to Azure
function Connect-Azure {
    Write-Host "Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount -ErrorAction Stop
}

# Function to create a resource group
function Create-ResourceGroup {
    param (
        [string]$ResourceGroupName,
        [string]$Location = "EastUS"
    )
    Write-Host "Creating resource group: $ResourceGroupName in $Location..." -ForegroundColor Cyan
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
}

# Function to deploy an ARM template
function Deploy-ArmTemplate {
    param (
        [string]$ResourceGroupName,
        [string]$TemplateFile,
        [hashtable]$TemplateParameters
    )
    Write-Host "Deploying ARM template to resource group: $ResourceGroupName..." -ForegroundColor Cyan
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $TemplateParameters -ErrorAction Stop
}

# Function to provision domain controllers
function Deploy-DomainControllers {
    param (
        [string]$ResourceGroupName,
        [string]$TemplateFilePath,
        [string]$TemplateParametersFilePath
    )
    Write-Host "Deploying domain controllers..." -ForegroundColor Cyan
    Deploy-ArmTemplate -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFilePath `
        -TemplateParametersFilePath $TemplateParametersFilePath
}

# Function to provision member servers
function Deploy-MemberServers {
    param (
        [string]$ResourceGroupName,
        [string]$TemplateFilePath,
        [string]$TemplateParametersFilePath
    )
    Write-Host "Deploying member servers..." -ForegroundColor Cyan
    Deploy-ArmTemplate -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFilePath `
        -TemplateParametersFilePath $TemplateParametersFilePath
}

# Function to provision client systems
function Deploy-ClientSystems {
    param (
        [string]$ResourceGroupName,
        [string]$TemplateFilePath,
        [string]$TemplateParametersFilePath
    )
    Write-Host "Deploying client systems..." -ForegroundColor Cyan
    Deploy-ArmTemplate -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFilePath `
        -TemplateParametersFilePath $TemplateParametersFilePath
}

# Main script execution
function Initialize-Lab {
    param (
        [string]$ResourceGroupName,
        [string]$Location,
        [string]$DomainControllerTemplate,
        [string]$DomainControllerParameters,
        [string]$MemberServerTemplate,
        [string]$MemberServerParameters,
        [string]$ClientSystemTemplate,
        [string]$ClientSystemParameters
    )

    Connect-Azure
    Create-ResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location

    Deploy-DomainControllers -ResourceGroupName $ResourceGroupName `
        -TemplateFilePath $DomainControllerTemplate `
        -TemplateParametersFilePath $DomainControllerParameters

    Deploy-MemberServers -ResourceGroupName $ResourceGroupName `
        -TemplateFilePath $MemberServerTemplate `
        -TemplateParametersFilePath $MemberServerParameters

    Deploy-ClientSystems -ResourceGroupName $ResourceGroupName `
        -TemplateFilePath $ClientSystemTemplate `
        -TemplateParametersFilePath $ClientSystemParameters

    Write-Host "Lab environment initialized successfully!" -ForegroundColor Green
}