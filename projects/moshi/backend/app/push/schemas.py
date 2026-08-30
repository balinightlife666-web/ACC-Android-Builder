from typing import Literal

from pydantic import BaseModel, Field


class PushRegistrationRequest(BaseModel):
    provider: Literal["fcm"] = "fcm"
    platform: Literal["android"] = "android"
    token: str = Field(min_length=20, max_length=4096)


class PushRegistrationResponse(BaseModel):
    provider: str
    platform: str
    registered: bool = True
