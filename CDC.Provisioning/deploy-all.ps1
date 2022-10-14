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
    Write-Host "Usage: .\deploy-all.ps1 {appIdentifier} {tenantId} {subscriptionId} {targetRegion: eus|wus|wus2|wus3|ncus|scus|wcus} {userId}"
    Write-Host "{appIdentifier} refers to a user defined prefix that will be applied to all resource names.  {userId} refers to the Object ID of the AAD user running the script"
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

# Login
$login_output = az login --tenant $tenantId
DecoratedOutput "Logged into Tenant:" "$tenantId"

# Set Subscription.  TODO: determine if both PowerShell and Azure CLI commands need to be run
$setAccount_output = Set-AzContext -Subscription $subscriptionId
$setAzAccount_output = az account set --subscription $subscriptionId
DecoratedOutput "Set Subscription to:" "$subscriptionId"

# Create Resource Group
$groupCreate_output = az group create --name $targetResourceGroup --location "$location"
DecoratedOutput "Created Resource Group" "$targetResourceGroup in $location"

# Set Default RG to newly created RG
az configure --defaults group=$targetResourceGroup
DecoratedOutput "Set Default Resource Group to" "$targetResourceGroup"

# Run intitial provisioning Bicep script, but only if the RG is empty.  Saves time on subsequent runs
$resources = Get-AzResource -ResourceGroupName $targetResourceGroup
if ($resources.Length -lt 2) {
    $deploy_output = az deployment group create --template-file main.bicep --parameters main.parameters.json --name "$timeStamp-$appName-$targetRegion-main" --parameters appName=$appName regionCode=$targetRegion tenantId=$tenantId
    DecoratedOutput "Executed Bicep Script"
}

# This is the list of function apps to create
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
    [PSCustomObject]@{
        AppNameSuffix     = 'ehProducer';
        StorageNameSuffix = 'ehproducer';
    }
)

# Define variables for configuration and managed identity assignment
$serviceBusName = "$appName-$targetRegion-sbns"
$eventHubName = "$appName-$targetRegion-ehns"
$cosmosAccountName = "$appName-$targetRegion-acdb"
$containerRegistryName = $appName.ToString().ToLower().Replace("-", "") + "$targetRegion" + "cr"
$kvName = "$appName-$targetRegion-kv"
$acrPullIdentityName = "$appName-$targetRegion-mi-acrPull"
$kvSecretsUserIdentityName = "$appName-$targetRegion-mi-kvSecrets"

# See if we already have our custom CosmosDB role defition.  This will be used for managed identity access
$cosmosRoleId = ''
(az cosmosdb sql role definition list --resource-group $targetResourceGroup --account-name $cosmosAccountName) | ConvertFrom-Json | ForEach-Object {
    #This role name is defined in the cosmos.role.definition.json file, if you change it here, change it there as well
    if ('ReadWriteRole' -eq $_.roleName) {
        $cosmosRoleId = $_.id
    }
}

# If the custom role definition doesn't exist, create it
if ([string]::IsNullOrWhiteSpace($cosmosRoleId)) {
    $cosmosRoleId = (az cosmosdb sql role definition create --resource-group $targetResourceGroup --account-name $cosmosAccountName --body "@cosmos.role.definition.json" --query id --output tsv)
    DecoratedOutput "Created Custom Cosmos Read/Write Role"
}

# Create a user defined managed identity and assign the AcrPull role to it.  This identity will then be added to all the function apps so they can access the container registry via managed identity
$acrPullPrincipalId = (az identity create --name $acrPullIdentityName --resource-group $targetResourceGroup --location $location --query principalId --output tsv)
$acrPullRoleId = (az role definition list --name "AcrPull" --query [0].id --output tsv)
DecoratedOutput "Got AcrPull Role Id:" $acrPullRoleId
$acrPullRoleAssignment_output = (az role assignment create --assignee $acrPullPrincipalId --role $acrPullRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName" --output tsv)
DecoratedOutput "Completed role assignment of acrPull to User Identity"

# Create a user defined managed identity and assign the Key Vault Secrets User role to it.  This identity will then be added to all the function apps so they can access Key Vault via managed identity
$kvSecretsPrincipalId = (az identity create --name $kvSecretsUserIdentityName --resource-group $targetResourceGroup --location $location --query principalId --output tsv)
$keyVaultSecretsRoleId = (az role definition list --name "Key Vault Secrets User" --query [0].id --output tsv)
DecoratedOutput "Got Key Vault Secrets User Role Id:" $keyVaultSecretsRoleId
$kvSecretRoleAssignment_output = (az role assignment create --assignee $kvSecretsPrincipalId --role $keyVaultSecretsRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.KeyVault/vaults/$kvName" --output tsv)
DecoratedOutput "Completed role assignment of Key Vault Secrets User to User Identity"

if ([string]::IsNullOrWhiteSpace($principalId) -ne $true) {
    $cosmosRoleAssignment_output = (az cosmosdb sql role assignment create --account-name $cosmosAccountName --resource-group $targetResourceGroup --scope "/" --principal-id $principalId --role-definition-id $cosmosRoleId)
    DecoratedOutput "Completed role assignment of Cosmos Custom Role to Principal ID" $principalId
}

# For each of the function apps we created...
$functionApps | ForEach-Object {
    $functionAppNameSuffix = $_.AppNameSuffix
    $storageAccountSuffix = $_.StorageNameSuffix
    $storageAccountPrefix = $appName.ToString().ToLower().Replace("-", "")
    $storageAccountName = ($storageAccountPrefix + $targetRegion + "sa" + $storageAccountSuffix)
    
    # This is here to make sure we don't exceed the storage account name length restriction
    if ($storageAccountName.Length -gt 24) {
        $storageAccountName = $storageAccountName.Substring(0, 24)
    }

    # Add the AcrPull managed identity to the function app
    $appIdentityAssignOutput = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$targetRegion-fa-$functionAppNameSuffix" --identities "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$acrPullIdentityName"  --query principalId --output tsv)
    DecoratedOutput "Added AcrPull MI to Function App" $functionAppNameSuffix

    # Add the Key Vault managed identity to the function app
    $appIdentityAssignOutput = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$targetRegion-fa-$functionAppNameSuffix" --identities "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$kvSecretsUserIdentityName"  --query principalId --output tsv)
    DecoratedOutput "Added Key Vault Secrets User MI to Function App" $functionAppNameSuffix

    # Create a system managed identity for the function app.  This will be used to access storage accounts, event hubs, and service bus via managed identity
    $functionAppIdentityId = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$targetRegion-fa-$functionAppNameSuffix" --query principalId --output tsv)
    DecoratedOutput "Created $functionAppNameSuffix identity:" $functionAppIdentityId

    # Assign function app's system identity to the storage blob data owner role
    $storageBlobDataOwnerRoleId = (az role definition list --name "Storage Blob Data Owner" --query [0].id --output tsv)
    DecoratedOutput "Got Storage Blog Data Role Id:" $storageBlobDataOwnerRoleId
    $storageBlobRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $storageBlobDataOwnerRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    DecoratedOutput "Completed role assignment of $functionAppNameSuffix to" $storageAccountName

    # Assign function app's system identity to the service bus data sender role
    $serviceBusDataSenderRoleId = (az role definition list --name "Azure Service Bus Data Sender" --query [0].id --output tsv)
    DecoratedOutput "Got Service Bus Data Sender Role Id:" $serviceBusDataSenderRoleId
    $serviceBusRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $serviceBusDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusName"
    DecoratedOutput "Completed sender role assignment of $functionAppNameSuffix to" $serviceBusName

    # Assign function app's system identity to the service bus data receiver role
    $serviceBusDataReceiverRoleId = (az role definition list --name "Azure Service Bus Data Receiver" --query [0].id --output tsv)
    DecoratedOutput "Got Service Bus Data Receiver Role Id:" $serviceBusDataReceiverRoleId
    $serviceBusRecieverRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $serviceBusDataReceiverRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusName"
    DecoratedOutput "Completed receiver role assignment of $functionAppNameSuffix to" $serviceBusName

    # Assign function app's system identity to the event hub data sender role
    $eventHubDataSenderRoleId = (az role definition list --name "Azure Event Hubs Data Sender" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Sender Role Id:" $eventHubDataSenderRoleId
    $eventHubDataSenderRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Sender role assignment of $functionAppNameSuffix to" $eventHubName

    # Assign function app's system identity to the service bus data receiver role
    $eventHubDataReceiverRoleId = (az role definition list --name "Azure Event Hubs Data Receiver" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Receiver Role Id:" $eventHubDataReceiverRoleId
    $eventHubDataReceiverRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataReceiverRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Receiver role assignment of $functionAppNameSuffix to" $eventHubName
    
    # Assign function app's system identity to the custom ComsosDB role that was created above
    $cosmosRoleAssiment_output = az cosmosdb sql role assignment create --account-name $cosmosAccountName --resource-group $targetResourceGroup --scope "/" --principal-id $functionAppIdentityId --role-definition-id $cosmosRoleId
    DecoratedOutput "Assigned Custom Cosmos Role to" $functionAppNameSuffix

    # Apply the app config values to the function app.  This has to happen after the managed identities have been setup or it fails, which is why it's here and not part of the main bicep path
    $configDeployment_output = az deployment group create --template-file ./Modules/functionConfig.bicep --name "$timeStamp-$appName-$targetRegion-functionConfig" --parameters appName=$appName regionCode=$targetRegion storageAccountNameSuffix=$storageAccountSuffix functionAppNameSuffix=$functionAppNameSuffix
    DecoratedOutput "Executed Config Bicep Script for" $functionAppNameSuffix  
}