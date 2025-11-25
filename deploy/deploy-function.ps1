#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName
)

$ErrorActionPreference = "Stop"

# Get current Azure context
$account = az account show | ConvertFrom-Json
Write-Host "Current Tenant: $($account.tenantId)" -ForegroundColor Cyan
Write-Host "Current Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan
Write-Host ""

# If function app name not provided, try to get it from the resource group
if (-not $FunctionAppName) {
    Write-Host "Discovering Function App in resource group..." -ForegroundColor Yellow
    $functionApps = az functionapp list --resource-group $ResourceGroupName --query "[].name" -o tsv
    
    if (-not $functionApps) {
        Write-Host "No Function App found in resource group $ResourceGroupName" -ForegroundColor Red
        exit 1
    }
    
    $FunctionAppName = $functionApps | Select-Object -First 1
    Write-Host "Found Function App: $FunctionAppName" -ForegroundColor Green
}

# Set paths relative to script location
$functionDir = Join-Path $PSScriptRoot ".." "src" "FunctionApp"
$publishDir = Join-Path $functionDir "publish"
$zipFile = Join-Path $functionDir "function.zip"
$csprojFile = Join-Path $functionDir "FunctionApp.csproj"

Write-Host "`nBuilding Function App..." -ForegroundColor Yellow
dotnet build $csprojFile --configuration Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nPublishing Function App..." -ForegroundColor Yellow
dotnet publish $csprojFile --configuration Release --output $publishDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Publish failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path "$publishDir\*" -DestinationPath $zipFile -Force

Write-Host "`nDeploying to Azure Function App: $FunctionAppName..." -ForegroundColor Yellow
az functionapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $FunctionAppName `
    --src $zipFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nFunction App deployed successfully!" -ForegroundColor Green
    Write-Host "Function App URL: https://$FunctionAppName.azurewebsites.net" -ForegroundColor Cyan
    
    # Cleanup
    Remove-Item $zipFile -Force
    Remove-Item $publishDir -Recurse -Force
} else {
    Write-Host "`nDeployment failed!" -ForegroundColor Red
    exit 1
}
