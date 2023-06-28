import azure.functions as func
import azure.cosmos.cosmos_client as cosmos_client
import logging
import os
import json
from models import EventAddress

# Create a global instance of CosmosClient
client = cosmos_client.CosmosClient(os.environ['CosmosDBEndpoint'], {
                                    'masterKey': os.environ['CosmosDBKey']})
database_name = os.environ['CosmosDBDatabaseName']
container_name = os.environ['CosmosDBContainerName']
database = client.get_database_client(database_name)
container = database.get_container_client(container_name)


app = func.FunctionApp()


@app.event_hub_message_trigger(arg_name="azeventhub", event_hub_name="poc.customers.addresses",
                               consumer_group="jeffs-python",
                               connection="jefftestevn_RootManageSharedAccessKey_EVENTHUB")
def eventhub_trigger(azeventhub: func.EventHubEvent):
    try:

        # Get the database and container
        body_str = azeventhub.get_body().decode('utf-8')
        logging.info('Python EventHub trigger processed an event: %s',
                     azeventhub.get_body().decode('utf-8'))
        event_address = json.loads(
            body_str, object_hook=lambda d: EventAddress(**d))
        event_address.id = event_address.profileId
        container.upsert_item(event_address.dict())
        logging.info('Saved address to cosmos: %s', event_address.profileId)
    except Exception as e:
        logging.error(e)


@app.route('createaddress', methods=['POST'])
def http_post_create_address(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body_str = req.get_body().decode('utf-8')
        logging.info('Python HTTP Post trigger processed an event: %s',
                     body_str)
        event_address = json.loads(
            body_str, object_hook=lambda d: EventAddress(**d))
        event_address.id = event_address.profileId
        container.upsert_item(event_address.dict())

        return func.HttpResponse(f"Address {event_address.id} created successfully")
    except Exception as e:
        return func.HttpResponse(f"Error processing event: {e}", status_code=500)
