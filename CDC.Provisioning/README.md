# Provisioning Services

To provision/deploy the necessary Azure resources to run this POC, run the deploy-all.ps1 script in a PowerShell command line window and follow the usage instructions.  The script is idempotent, so if there is a delay on registering the managed identity for the apps against other resources, such as storage, the script can be run a second time.

Usage: .\deploy-all.ps1 {appIdentifier} {tenantId} {subscriptionId} {targetRegion: eus|wus|wus2|wus3|ncus|scus|wcus} {userId}

Where _{appIdentifier}_ is a custom free-form field to uniquely identify your deployment.  Will be used as a prefix for all the resource names.  Recommend keeping this to 15 characters (not including dashes) or less to avoid name length errors with storage accounts.  _{tenantId}_ and _{subscriptionId}_ are the GUID representing the tenant and subscription respectively.  _{userId}_ is the AAD GUID representing the user running the script to enable local development.

# Post Provisioning Steps

These steps are for locking down all the Azure resrouces via VNET injection and private endpoints to make it a complete and isolated "island" from a networking perspective

1. From within Visual Studio, publish sample function apps from cdc-poc repo to the Azure Container Registry that was created in step 1
1. In Azure Portal, update storage accounts to only allow traffic from the subnets mapped to their function apps (NOTE: this should be able to be done via Bicep script, but applying the storage configuration settings to the function app fails if VNET access restrictions are already in place)
    1. *ehconsum -> -subnet-epf-01
    1. *sbconsum -> -subnet-epf-02
    1. *ehproduc -> -subnet-epf-03
1. In the Azure Portal, create a private endpoint for the container registry.  Name should be in format of {appIdentifier}-{locationCode}-pe-acr where {appIdentifier} is same value passed into provisioning script.
    1. The naming convention for the NICs associated with the Private Endpoints should be {appIdentifier}-{locationCode}-nic-pe-acr
	1. The subnet to be used should be the -subnet-privateEndpoints subnet created by the provisioning script
	1. All remaining settings can be defaulted
	1. DOUBLE CHECK THE TARGET REGION MATCHES THE REGION YOU RAN THE PROVISIONING SCRIPT AGAINST
1. Do the same for the key vault
	1. Disable public access via the networking tab.  Allow trusted Microsoft services
1. Do the same for the service bus
	1. Disable public access via the networking tab.  Allow trusted Microsoft services
1. Do the same for the event hub
	1. Disable public access via the networking tab.  Allow trusted Microsoft services
1. Do the same for the 3 functions
1. Create Bastion
1. Create VM
