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

$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$namePrefix = $Args[1]

if ($Args.Length -lt 2) {
    Write-Warning "Usage: deploy-all.ps1 {location} {namePrefix}"
    exit
}

switch ($location) {
    'eastus' {
        $regionCode = 'eus'
    }
    'eastus2' {
        $regionCode = 'eus2'
    }
    'centralus' {
        $regionCode = 'cus'
    }
    'westus' {
        $regionCode = 'wus'
    }
    'westus2' {
        $regionCode = 'wus2'
    }
    'westus3' {
        $regionCode = 'wus3'
    }
    'northcentralus' {
        $regionCode = 'ncus'
    }

    Default {
        throw "Invalid Target Location Specified"
    }
}

DecoratedOutput "Deploying Environment..."
$deploy_output = az deployment sub create --name "$timeStamp-$appPrefix" --location $location --template-file main.bicep --parameters main.parameters.json location=$location namePrefix=$namePrefix regionCode=$regionCode
DecoratedOutput "Environment Deployed."