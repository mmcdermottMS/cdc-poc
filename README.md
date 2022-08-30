# cdc-poc

POC for CDC Effort

To get started with the solution, rename example.local.settings.json to local.settings.json and update the service placeholders with valid values.

The apps are designed to use Azure Managed Identites to connect to the other resources, so make sure the user under which you're running Visual Studio and the debugger has the appropriate send and/or receive role on the Service Bus or Event Hub for local debugging

## Provisioning Services

To provision/deploy the necessary Azure resources to run this POC, run the deploy-all.ps1 script in a PowerShell command line window and follow the usage instructions.  The script is idempotent, so if there is a delay on registering the managed identity for the apps against other resources, such as storage, the script can be run a second time.

The Provisioning script assumes that a resource group with centralized resources (such as Azure Container Registry or Azure Key Vault) already exists, and the prefix of this resource group must be passed in as a parameter.  If this common RG does not exist, please stub it out ahead of running the script.  The name of this common centralized resource group should end in _-rg_

This POC also assumes you have an existing Mongo Atlas instance.  Creating a Mongo Atlas instances is outside the scope of this documentation, but more information can be found at [https://www.mobgodb.com](https://www.mongodb.com)

## Deploying Code

### Project Descriptions

1. CDC.CLI.EhProducer - Command line project that will generate test messages/events and publish them to the target Event Hub.  Useful for validating the POC independent of MongoDB and the Kafka Connector for MongoDB
1. CDC.CLI.Mongo - Command line project that will insert and update records within a target MongoDB instance (MongoDB Atlas) to simulate customers updating their profiles
1. CDC.Domain - Common class library that contains shared domain objects such as DTO entities.
1. CDC.EhConsumer - Azure Function using an Event Hub Trigger to listen for and consume events off a target Event Hub, process the events, and then publish them to a downstream Service Bus Queue
1. CDC.EhProducer - Azure Function version of CDC.CLI.EhProducer used for producing an extreme volume of events/messages to the target Event Hub for performance and soak testing to validate NFRs
1. CDC.SbConsumer -  Azure Function using a Service Bus Queue trigger to listen for an consume messages, by Session ID, from the queue, transform the messages, and write them to Cosmos (if they don't exist) or update them (if they do)

Assuming you created a common/centralized RG as indicated in the above section, and that RG has a common/centralized Azure Container Registry, you can publish (from Visual Studio) the 3 Azure Function projects to your ACR

## To Stand Up Kafka Connect for MongoDB

1. Provision an Azure VM running Ubuntu 20.04
1. Install Java 17 on the VM.  See [Install OpenJDK on Ubuntu](https://docs.microsoft.com/en-us/java/openjdk/install#install-on-ubuntu) for more details
1. Install Apache Kafka in the home directory:
   1. wget [https://dlcdn.apache.org/kafka/3.2.1/kafka_2.13-3.2.1.tgz](wget https://dlcdn.apache.org/kafka/3.2.1/kafka_2.13-3.2.1.tgz)
   1. tar -xzf kafka_2.13-3.2.1.tgz
   1. cd kafka_2.13-3.2.1
   1. Create the _connect-distributed.properties file.  Use the template in this project, replace the Event Hubs connection string placeholders with the actual values of your provisioned EH
1. Download the _-all_ MongoDB Plugin file to the _/usr/local/share/kafka/plugins_ folder - you may need to create this folder as sudo
   1. sudo wget [https://repo1.maven.org/maven2/org/mongodb/kafka/mongo-kafka-connect/1.7.0/mongo-kafka-connect-1.7.0-all.jar](https://repo1.maven.org/maven2/org/mongodb/kafka/mongo-kafka-connect/1.7.0/mongo-kafka-connect-1.7.0-all.jar)
1. Change directories back to the home directory
1. Create the mongo-connecg-config.json file.  Use the template in this project, replace the Mongo DB connection string placeholder with the actual value of your Mongo Atlas cluster
1. Change directory to *kafka_2.13-3.2.1*
1. Run the following command from the *kafka_2.13-3.2.1* directory:
   1. bin/connect-distributed.sh connect-distributed.properties
1. Open a second command prompt on the VM
1. Run the following command to configure the MongoDB connector:
   1. curl -X POST -H "Content-Type: application/json" --data "@mongo-connect-config.json" http://localhost:8083/connectors -w "\n"


## Executing the POC

1. Ensure your container images have been deployed to each of the provisioned function apps (via the Deployment Center blade on the Function App management screen in the Azure Portal)
1. Ensure a _Customers_ database with an _addresses_ container has been created in the provisioned CosmosDB instance.  Also ensure the partition key on the _addresses_ container is _/profileId_
1. Run the CDC.CLI.Mongo project, either from a command line or from within Visual Studio
   1. To insert records into Mongo: _cdc.cli.mongo.exe {numOfRecordsToInsert} insert_
   1. To update records in Mongo: _cdc.cli.mongo.exe {numOfRecordsToUpdate} {numOfUpdateCyclesToExecute} update_ where _{numOfUpdateCyclesToExecute}_ is the number of update batches that should be run.  There is a 1 second delay between each batch run.