import unittest
import json
from models import EventAddress
from bson import ObjectId


class TestEventAddress(unittest.TestCase):
    def test_json_serialization(self):
        # Create an instance of the EventAddress object
        event_address = EventAddress(
            id='123',
            profileId='456',
            Street1='123 Main St',
            Street2='',
            City='Anytown',
            State='CA',
            Zip_code='12345',
            CreatedDateUtc='2022-01-01T00:00:00Z',
            UpdatedDateUtc='2022-01-01T00:00:00Z'
        )

        # Serialize the object to a JSON string
        json_str = json.dumps(event_address.dict())

        # Define the expected JSON string
        expected_json_str = '{"id": "123", "profileId": "456", "Street1": "123 Main St", "Street2": "", "City": "Anytown", "State": "CA", "Zip_code": "12345", "CreatedDateUtc": "2022-01-01T00:00:00Z", "UpdatedDateUtc": "2022-01-01T00:00:00Z"}'

        # Compare the JSON strings
        self.assertEqual(json_str, expected_json_str)


class TestDeserializeEventAddress(unittest.TestCase):
    def test_json_deserialization(self):
        # Define a JSON string
        json_str = '{"id": "123", "profileId": "456", "Street1": "123 Main St", "Street2": "", "City": "Anytown", "State": "CA", "Zip_code": "12345", "CreateDateUtc": "2022-01-01T00:00:00Z", "UpdateDateUtc": "2022-01-01T00:00:00Z"}'

        # Deserialize the JSON string into a dictionary
        json_dict = json.loads(json_str)
        # json_dict["ID"] = json_dict["_id"]
        # Create an instance of the EventAddress object using the dictionary

        event_address = EventAddress(**json_dict)

        # Check that the object was created correctly
        self.assertEqual(event_address.id, '123')
        self.assertEqual(event_address.profileId, '456')
        self.assertEqual(event_address.Street1, '123 Main St')
        self.assertEqual(event_address.Street2, '')
        self.assertEqual(event_address.City, 'Anytown')
        self.assertEqual(event_address.State, 'CA')
        self.assertEqual(event_address.Zip, '12345')
        self.assertEqual(event_address.CreatedDateUtc, '2022-01-01T00:00:00Z')
        self.assertEqual(event_address.UpdatedDateUtc, '2022-01-01T00:00:00Z')


if __name__ == '__main__':
    unittest.main()
