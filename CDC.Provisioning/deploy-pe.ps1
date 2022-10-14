Function DecoratedOutput {
    param(
        [Parameter (Mandatory = $true)] [String]$baseMessage,
        [Parameter (Mandatory = $false)] [String]$secondaryMessage
    )

    Write-Host "$(Get-Date -Format G): " -ForegroundColor Yellow -NoNewline

    if ($secondaryMessage) {
        Write-Host "$baseMessage " -NoNewLine
        Write-Host "$secondaryMessage" -ForegroundColor Green
    }
    else {
        Write-Host "$baseMessage"
    }    
}

if ($Args.Length -lt 4) {
    Write-Host "Usage: .\deploy-all.ps1 {appIdentifier} {tenantId} {subscriptionId} {targetRegion: eus|wus|wus2|wus3|ncus|scus|wcus}"
    Exit
}

$appName = $Args[0]
$tenantId = $Args[1]
$subscriptionId = $Args[2]
$targetRegion = $Args[3]
$principalId = $Args[4]
$targetResourceGroup = "$appName-$targetRegion-rg"
$timeStamp = Get-Date -Format "yyyyMMddHHmm"

DecoratedOutput "Beginning Deployment..."

switch ($targetRegion) {
    'eus' {
        $location = 'East US'
    }
    'wus' {
        $location = 'West US'
    }
    'wus2' {
        $location = 'West US 2'
    }
    'wus3' {
        $location = 'West US 3'
    }
    'ncus' {
        $location = 'North Central US'
    }
    'scus' {
        $location = 'South Central US'
    }
    'wcus' {
        $location = 'West Central US'
    }
    Default {
        throw "Invalid Target Location Specified"
    }
}

<#
# Login
$login_output = az login --tenant $tenantId
DecoratedOutput "Logged into Tenant:" "$tenantId"
#>

# Set Subscription.  TODO: determine if both PowerShell and Azure CLI commands need to be run
$setAccount_output = Set-AzContext -Subscription $subscriptionId
$setAzAccount_output = az account set --subscription $subscriptionId
DecoratedOutput "Set Subscription to:" "$subscriptionId"

$deploy_output = az deployment group create --template-file private-networking.bicep --name "$timeStamp-$appName-$targetRegion-main" --parameters appName=$appName regionCode=$targetRegion subscriptionId=$subscriptionId
DecoratedOutput "Executed Private Endpoint Bicep Script"