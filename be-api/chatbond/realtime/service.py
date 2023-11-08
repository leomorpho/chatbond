import os
from enum import Enum
from typing import List
from uuid import UUID

from cent import Client
from django.core.serializers.json import DjangoJSONEncoder

from chatbond.realtime.dataclass import (
    RealtimeData,
    RealtimePayloadTypes,
    RealtimeUpdateAction,
    RealtimeUpdateEvent,
)

CENTRIFUGO_PERSONAL_NAMESPACE = "personal"


url = os.getenv("CENTRIFUGO_API_ENDPOINT")
api_key = os.getenv("CENTRIFUGO_API_KEY")


class CustomJSONEncoder(DjangoJSONEncoder):
    def default(self, obj):
        if isinstance(obj, UUID):
            return str(obj)
        elif isinstance(obj, Enum):
            return obj.value
        return super().default(obj)


# initialize client instance.
client = Client(url, api_key=api_key, timeout=1, json_encoder=CustomJSONEncoder)


class RealtimeUpdateService:
    def publish_to_personal_channels(
        self,
        payload_type: RealtimePayloadTypes,
        payload_content: dict,
        userIds: List[UUID],
        action: RealtimeUpdateAction = RealtimeUpdateAction.UPSERT,
    ) -> None:
        payload_data = RealtimeData(
            type=payload_type,
            content=payload_content,
        )
        realtime_event_data = RealtimeUpdateEvent(action=action, data=payload_data)

        for userId in userIds:
            channel = self._get_personal_channel_from_user_id(userId)
            self._publish(channel, realtime_event_data)

    def _publish(self, channel: str, data: RealtimeUpdateEvent):
        client.publish(channel, data.to_dict())

    def _get_personal_channel_from_user_id(self, user_id: UUID) -> str:
        return f"{CENTRIFUGO_PERSONAL_NAMESPACE}:#{user_id}"


realtimeUpdateService = RealtimeUpdateService()
