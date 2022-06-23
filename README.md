# cdc-poc
POC for CDC Effort

To get started with the solution, rename local.settings.json.example to local.settings.json and update the placeholders with valid values.

The apps are designed to use Azure Managed Identites to connect to the other resources, so make sure the user under which you're running Visual Studio and the debugger has the appropriate send and/or receive role on the Service Bus or Event Hub

To provision/deploy the necessary Azure resources to run this POC, run the deploy-all.ps1 script in a PowerShell command line window and follow the usage instructions.  May need to run it twice if there is a delay on registering the managed identity for the apps and assigning them to the storage accounts.
