# import json
from dataclasses import dataclass, field
from enum import Enum


class RealtimePayloadTypes(Enum):
    """
    Represents object types that must be kept in sync between
    BE and clients.
    """

    CHAT_THREAD = "chat_thread"
    QUESTION_THREAD = "question_thread"
    QUESTION_CHAT = "question_chat"
    INVITATION = "invitation"


class RealtimeUpdateAction(Enum):
    """
    Represents allowed actions on objects over the realtime channels.
    """

    UPSERT = "upsert"
    DELETE = "delete"


@dataclass
class RealtimeData:
    """Data payload of a realtime message."""

    type: str
    content: dict

    def to_dict(self):
        return {"type": self.type, "content": self.content}


@dataclass
class RealtimeUpdateEvent:
    """Wrapper for realtime payload."""

    data: RealtimeData
    action: str = field(default=RealtimeUpdateAction.UPSERT)

    def to_dict(self):
        return {"action": self.action.value, "data": self.data.to_dict()}
