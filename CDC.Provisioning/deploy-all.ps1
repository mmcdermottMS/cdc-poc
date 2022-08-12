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

if($Args.Length -lt 4) {
    Write-Host "Usage: .\deploy-all.ps1 {appIdentifier} {targetLocation: eus|wus|ncus|scus|wcus} {subscriptionName} {commonResourcePrefix}"
    Write-Host "Common resource prefix is the prefix to a resource group name that must end in -rg and contains a common KeyVault and Azure Container Registry.  This script does not create that RG or those resources."
    Exit
}

$appName = $Args[0]
$targetLocation = $Args[1]
$subscriptionName = $Args[2]
$commonResourcePrefix = $Args[3]
$targetResourceGroup = "$appName-$targetLocation-rg"
$commonResourceGroup = "$commonResourcePrefix-rg"
$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$subscriptionId = (az account show --query id --output tsv)

DecoratedOutput "Beginning Deployment..."

# Uncomment if necessary
# az login

switch ($targetLocation) {
    'eus' {
        $location = 'East US'
    }
    'wus' {
        $location = 'West US'
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

az account set --subscription $subscriptionName
DecoratedOutput "Set Subscription to" "$subscriptionName"

$groupCreate_output = az group create --name $targetResourceGroup --location "$location"
DecoratedOutput "Created Resource Group" "$targetResourceGroup in $location"

az configure --defaults group=$targetResourceGroup
DecoratedOutput "Set Default Resource Group to" "$targetResourceGroup"

$deploy_output = az deployment group create --template-file main.bicep --parameters main.parameters.json --name "$timeStamp-$appName-$targetLocation-main" --parameters appName=$appName locationCode=$targetLocation
DecoratedOutput "Executed Bicep Script"

# TODO - refactor this to convert to JSON and pass it into the main bicep file so we only maintain this list in one spot
$functionApps = @(
    [PSCustomObject]@{
        AppNameSuffix     = 'ehConsumer';
        StorageNameSuffix = 'ehconsumer';
    }
    [PSCustomObject]@{
        AppNameSuffix     = 'sbConsumer';
        StorageNameSuffix = 'sbconsumer';
    }
)

$serviceBusName = "$appName-$targetLocation-sbns-01"
$eventHubName = "$appName-$targetLocation-ehns-01"
$cosmosAccountName = "$appName-$targetLocation-acdb"

$cosmosRoleId = (az cosmosdb sql role definition create --account-name $cosmosAccountName --resource-group $targetResourceGroup --body "@cosmos.role.definition.json" --query id --output tsv)
DecoratedOutput "Created Custom Cosmos Read/Write Role" $functionAppNameSuffix

$functionApps | ForEach-Object {
    $functionAppNameSuffix = $_.AppNameSuffix
    $storageAccountSuffix = $_.StorageNameSuffix
    $storageAccountPrefix = $appName.ToString().ToLower().Replace("-", "")
    $storageAccountName = $storageAccountPrefix + $targetLocation + "sa" + $storageAccountSuffix

    $functionAppIdentityId = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$targetLocation-fx-$functionAppNameSuffix" --query principalId --output tsv)
    DecoratedOutput "Created $functionAppNameSuffix identity:" $functionAppIdentityId

    $storageBlobDataOwnerRoleId = (az role definition list --name "Storage Blob Data Owner" --query [0].id --output tsv)
    DecoratedOutput "Got Storage Blog Data Role Id:" $storageBlobDataOwnerRoleId

    $storageBlobRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $storageBlobDataOwnerRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    DecoratedOutput "Completed role assignment of $functionAppNameSuffix to" $storageAccountName

    $serviceBusDataSenderRoleId = (az role definition list --name "Azure Service Bus Data Sender" --query [0].id --output tsv)
    DecoratedOutput "Got Service Bus Data Sender Role Id:" $serviceBusDataSenderRoleId

    $serviceBusRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $serviceBusDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusName"
    DecoratedOutput "Completed sender role assignment of $functionAppNameSuffix to" $serviceBusName

    $serviceBusDataReceiverRoleId = (az role definition list --name "Azure Service Bus Data Receiver" --query [0].id --output tsv)
    DecoratedOutput "Got Service Bus Data Receiver Role Id:" $serviceBusDataReceiverRoleId

    $serviceBusRecieverRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $serviceBusDataReceiverRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusName"
    DecoratedOutput "Completed receiver role assignment of $functionAppNameSuffix to" $serviceBusName

    $eventHubDataSenderRoleId = (az role definition list --name "Azure Event Hubs Data Sender" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Sender Role Id:" $eventHubDataSenderRoleId

    $eventHubDataSenderRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Sender role assignment of $functionAppNameSuffix to" $eventHubName

    $eventHubDataReceiverRoleId = (az role definition list --name "Azure Event Hubs Data Receiver" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Receiver Role Id:" $eventHubDataReceiverRoleId

    $eventHubDataReceiverRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataReceiverRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Receiver role assignment of $functionAppNameSuffix to" $eventHubName

    $acrPullRoleId = (az role definition list --name "AcrPull" --query [0].id --output tsv)
    DecoratedOutput "Got AcrPull Role Id:" $acrPullRoleId

    $acrPullRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $acrPullRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$commonResourceGroup/providers/Microsoft.ContainerRegistry/registries/commoninfra"
    DecoratedOutput "Completed role assignment of $functionAppNameSuffix to" "Azure Container Registry"

    $keyVaultSecretsRoleId = (az role definition list --name "Key Vault Secrets User" --query [0].id --output tsv)
    DecoratedOutput "Got Key Vault Secrets User Role Id:" $keyVaultSecretsRoleId

    $keyVaultRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $keyVaultSecretsRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$commonResourceGroup/providers/Microsoft.KeyVault/vaults/common-infra-kv-01"
    DecoratedOutput "Completed role assignment of $functionAppNameSuffix to" "Key Vault"
    
    $cosmosRoleAssiment_output = az cosmosdb sql role assignment create --account-name $cosmosAccountName --resource-group $targetResourceGroup --scope "/" --principal-id $functionAppIdentityId --role-definition-id $cosmosRoleId
    DecoratedOutput "Assigned Custom Cosmos Role to" $functionAppNameSuffix

    $configDeployment_output = az deployment group create --template-file ./Modules/functionConfig.bicep --name "$timeStamp-$appName-$targetLocation-functionConfig" --parameters appName=$appName locationCode=$targetLocation storageAccountNameSuffix=$storageAccountSuffix functionAppNameSuffix=$functionAppNameSuffix
    DecoratedOutput "Executed Config Bicep Script for" $functionAppNameSuffix
}