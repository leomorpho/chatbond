from rest_framework import serializers

from .models import (
    ChatThread,
    Interlocutor,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)


class InterlocutorSerializer(serializers.ModelSerializer):
    # NOTE: if id is not set explicitly, user_id somehow overrides it
    id = serializers.UUIDField()
    name = serializers.CharField(source="user.name")
    user_id = serializers.UUIDField(source="user.id")
    username = serializers.CharField(source="user.username")
    email = serializers.CharField(source="user.email")
    profile_pic = serializers.CharField(source="user.profile_pic")
    created_at = serializers.ReadOnlyField()

    class Meta:
        model = Interlocutor
        fields = [
            "id",
            "user_id",
            "name",
            "username",
            "email",
            "created_at",
            "profile_pic",
        ]


class QuestionThreadSerializer(serializers.ModelSerializer):
    from chatbond.questions.serializers import QuestionSerializer

    # NOTE: never return the chats alongside this object as there is no filtering
    # to prevent users from a common thread, who haven't answered the question,
    # to NOT see those answers from the others.
    num_new_unseen_messages = serializers.IntegerField(required=False, allow_null=True)
    question = QuestionSerializer()
    created_at = serializers.ReadOnlyField()
    updated_at = serializers.ReadOnlyField()
    all_interlocutors_answered = serializers.ReadOnlyField()

    class Meta:
        model = QuestionThread
        fields = [
            "id",
            "chat_thread",
            "question",
            "updated_at",
            "created_at",
            "num_new_unseen_messages",
            "all_interlocutors_answered",
        ]


class ChatThreadSerializer(serializers.ModelSerializer):
    interlocutors = InterlocutorSerializer(many=True, read_only=True)
    num_new_unseen_messages = serializers.IntegerField(required=False, allow_null=True)
    created_at = serializers.ReadOnlyField()
    updated_at = serializers.ReadOnlyField()
    owner = serializers.SerializerMethodField()

    class Meta:
        model = ChatThread
        fields = [
            "id",
            "interlocutors",
            "updated_at",
            "created_at",
            "num_new_unseen_messages",
            "owner",
        ]

    def get_owner(self, obj) -> str:
        user = self.context["request"].user
        interlocutor = Interlocutor.objects.filter(user=user).first()
        # TODO: the ChatThread endpoint will cause UI to crash
        # if interlocutor is ever None when gotten here.
        return InterlocutorSerializer(interlocutor).data if interlocutor else None


class QuestionChatInteractionEventSerializer(serializers.ModelSerializer):
    received_at = serializers.ReadOnlyField()
    seen_at = serializers.ReadOnlyField()

    class Meta:
        model = QuestionChatInteractionEvent
        fields = ["interlocutor", "received_at", "seen_at"]


class QuestionChatSerializer(serializers.ModelSerializer):
    interaction_events = QuestionChatInteractionEventSerializer(
        many=True, read_only=True
    )
    author_id = serializers.SerializerMethodField()
    author_name = serializers.SerializerMethodField()
    created_at = serializers.ReadOnlyField()
    updated_at = serializers.ReadOnlyField()

    class Meta:
        model = QuestionChat
        fields = [
            "id",
            "author_id",
            "author_name",
            "question_thread",
            "content",
            "status",
            "created_at",
            "updated_at",
            "interaction_events",
        ]

    def get_author_id(self, obj) -> str:
        return obj.author.id

    def get_author_name(self, obj) -> str:
        return str(obj.author.user.name)
