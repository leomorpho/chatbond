from rest_framework import serializers

from chatbond.chats.models import DraftQuestionThread
from chatbond.chats.serializers import InterlocutorSerializer


class DraftQuestionThreadSerializer(serializers.ModelSerializer):
    """Dirty hack to avoid circular import...

    TODO: re-organize code to do away with this hack.
    """

    created_at = serializers.ReadOnlyField()
    question_thread = serializers.PrimaryKeyRelatedField(read_only=True)
    published_at = serializers.ReadOnlyField()
    interlocutor = InterlocutorSerializer(read_only=True)

    class Meta:
        model = DraftQuestionThread
        fields = [
            "id",
            "chat_thread",
            "question",
            "content",
            "created_at",
            "interlocutor",
            "published_at",
            "question_thread",
        ]
