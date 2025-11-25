#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "swedencentral"
)

$iacDir = Join-Path $PSScriptRoot ".." "iac"

# Get current Azure context
$account = az account show | ConvertFrom-Json
Write-Host "Current Tenant: $($account.tenantId)" -ForegroundColor Cyan
Write-Host "Current Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan
Write-Host ""

# Create resource group
az group create --name $ResourceGroupName --location $Location --output none

# Run what-if
Write-Host "Running deployment what-if analysis..." -ForegroundColor Yellow
az deployment group what-if `
    --resource-group $ResourceGroupName `
    --template-file (Join-Path $iacDir "main.bicep") `
    --parameters (Join-Path $iacDir "main.bicepparam")

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nWhat-if analysis failed!" -ForegroundColor Red
    exit 1
}

# Prompt to continue
Write-Host ""
$confirm = Read-Host "Do you want to proceed with the deployment? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

# Deploy
Write-Host "`nStarting deployment..." -ForegroundColor Yellow
az deployment group create `
    --name "deploy-$(Get-Date -Format 'yyyyMMddHHmmss')" `
    --resource-group $ResourceGroupName `
    --template-file (Join-Path $iacDir "main.bicep") `
    --parameters (Join-Path $iacDir "main.bicepparam")

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nDeployment failed!" -ForegroundColor Red
    exit 1
}
