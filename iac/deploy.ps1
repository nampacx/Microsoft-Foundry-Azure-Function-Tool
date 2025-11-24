#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Azure Function App and Storage Account infrastructure.

.DESCRIPTION
    This script deploys the infrastructure defined in main.bicep to Azure.
    It creates an Azure Function App and a Storage Account with two queues: tool-input and tool-output.

.PARAMETER ResourceGroupName
    The name of the resource group to deploy to. If it doesn't exist, it will be created.

.PARAMETER Location
    The Azure region where resources will be deployed. Default is 'eastus'.

.PARAMETER FunctionAppName
    Optional. The name of the Function App. If not provided, a unique name will be generated.

.PARAMETER StorageAccountName
    Optional. The name of the Storage Account. If not provided, a unique name will be generated.

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "rg-foundry-tool" -Location "eastus"

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "rg-foundry-tool" -Location "westus" -FunctionAppName "my-func-app" -StorageAccountName "mystorageaccount"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Function App Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if user is logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Host "Not logged in to Azure. Please login..." -ForegroundColor Yellow
        Connect-AzAccount
    } else {
        Write-Host "Already logged in to Azure as: $($context.Account.Id)" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking Azure login: $_" -ForegroundColor Red
    Write-Host "Please run 'Connect-AzAccount' to login to Azure" -ForegroundColor Yellow
    exit 1
}

# Check if resource group exists, create if it doesn't
Write-Host "Checking if resource group '$ResourceGroupName' exists..." -ForegroundColor Yellow
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $rg) {
    Write-Host "Resource group does not exist. Creating..." -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Resource group created successfully." -ForegroundColor Green
} else {
    Write-Host "Resource group already exists." -ForegroundColor Green
}

# Prepare deployment parameters
$deploymentParams = @{
    ResourceGroupName = $ResourceGroupName
    TemplateFile      = Join-Path $scriptDir "main.bicep"
    Verbose           = $true
}

# Add optional parameters if provided
if ($FunctionAppName) {
    $deploymentParams.Add("functionAppName", $FunctionAppName)
}
if ($StorageAccountName) {
    $deploymentParams.Add("storageAccountName", $StorageAccountName)
}

# Deploy the Bicep template
Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host ""

try {
    $deployment = New-AzResourceGroupDeployment @deploymentParams
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "  Function App Name: $($deployment.Outputs.functionAppName.Value)" -ForegroundColor White
    Write-Host "  Storage Account Name: $($deployment.Outputs.storageAccountName.Value)" -ForegroundColor White
    Write-Host "  Tool Input Queue: $($deployment.Outputs.toolInputQueueName.Value)" -ForegroundColor White
    Write-Host "  Tool Output Queue: $($deployment.Outputs.toolOutputQueueName.Value)" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
