#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Purges all deleted Azure Cognitive Services accounts.

.DESCRIPTION
    This script retrieves all deleted Cognitive Services accounts and purges them.
    It extracts the necessary parameters (name, resource group, location) from the
    deleted account's ID and performs the purge operation.

.EXAMPLE
    .\purge-deleted-accounts.ps1
#>

Write-Host "Retrieving deleted Cognitive Services accounts..." -ForegroundColor Cyan

# Get all deleted accounts with their IDs
$deletedAccounts = az cognitiveservices account list-deleted --query "[].{Name:name, Location:location, Id:id}" | ConvertFrom-Json

if (-not $deletedAccounts -or $deletedAccounts.Count -eq 0) {
    Write-Host "No deleted Cognitive Services accounts found." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($deletedAccounts.Count) deleted account(s):" -ForegroundColor Yellow
$deletedAccounts | ForEach-Object {
    Write-Host "  - Name: $($_.Name), Location: $($_.Location)" -ForegroundColor Gray
}

Write-Host ""
$confirm = Read-Host "Do you want to purge all these accounts? This action cannot be undone. (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Purge operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
foreach ($account in $deletedAccounts) {
    Write-Host "Processing: $($account.Name)..." -ForegroundColor Cyan
    
    $name = $account.Name
    $location = $account.Location
    
    # Extract resource group from ID
    # ID format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.CognitiveServices/accounts/{name}
    if ($account.Id -match '/resourceGroups/([^/]+)/') {
        $resourceGroup = $matches[1]
        Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Gray
        Write-Host "  Location: $location" -ForegroundColor Gray
        
        try {
            Write-Host "  Purging..." -ForegroundColor Yellow
            az cognitiveservices account purge --name $name --resource-group $resourceGroup --location $location
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Successfully purged: $name" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Failed to purge: $name" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  ✗ Error purging $name : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  ✗ Could not extract resource group from ID: $($account.Id)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "Purge operation completed." -ForegroundColor Green
