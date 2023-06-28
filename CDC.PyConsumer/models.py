from typing import Optional
from pydantic import BaseModel


class EventAddress(BaseModel):
    id: Optional[str]
    profileId: str
    Street1: str
    Street2: str
    City: str
    State: str
    Zip: str
    ZipExtension: str
    CreatedDateUtc: str
    UpdatedDateUtc: str
