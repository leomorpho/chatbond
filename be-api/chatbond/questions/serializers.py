from typing import Union

from django.db.models import Q
from rest_framework import serializers

from chatbond.chats.models import DraftQuestionThread, QuestionThread
from chatbond.questions.models import FavouritedQuestion, Question, RatedQuestion


class QuestionSerializer(serializers.ModelSerializer):
    from chatbond.chats.serializers import InterlocutorSerializer

    cumulative_voting_score = serializers.SerializerMethodField()
    times_voted = serializers.SerializerMethodField()
    times_answered = serializers.SerializerMethodField()
    author = InterlocutorSerializer()
    status = serializers.SerializerMethodField()
    user_rating = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    unpublished_drafts = serializers.SerializerMethodField()
    published_drafts = serializers.SerializerMethodField()
    answered_by_friends = serializers.SerializerMethodField()

    class Meta:
        model = Question
        fields = [
            "id",
            "cumulative_voting_score",
            "times_voted",
            "times_answered",
            "content",
            "author",
            "is_active",
            "created_at",
            "updated_at",
            "is_private",
            "status",
            "user_rating",
            "is_favorite",
            "unpublished_drafts",
            "published_drafts",
            "answered_by_friends",
        ]

    # TODO: these calculated fields may need to be denormalized and stored in models
    # if it becomes too expensive to calculate on the fly.
    def get_cumulative_voting_score(self, obj) -> int:
        return obj.cumulative_voting_score()

    def get_times_voted(self, obj) -> int:
        return obj.times_voted()

    def get_times_answered(self, obj) -> int:
        return obj.times_answered()

    def get_status(self, obj) -> str:
        return obj.get_status_display()

    def get_user_rating(self, obj) -> Union[None, str]:
        # TODO: no tests exist to confirm this is never broken

        request = self.context.get("request")
        if request and request.user.is_authenticated:
            user = request.user
            rating = RatedQuestion.objects.filter(
                interlocutor=user.interlocutor, question=obj
            ).first()
            return rating.status if rating else None
        return None

    def get_is_favorite(self, obj) -> bool:
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            user = request.user
            return FavouritedQuestion.objects.filter(
                Q(interlocutor=user.interlocutor) & Q(question=obj)
            ).exists()
        return False

    def get_unpublished_drafts(self, obj) -> str:
        from .draft_serializer import DraftQuestionThreadSerializer

        request = self.context.get("request")
        if request and request.user.is_authenticated:
            user = request.user
            drafts = DraftQuestionThread.objects.filter(
                Q(drafter=user.interlocutor) & Q(question=obj) & Q(question_thread=None)
            )
            return DraftQuestionThreadSerializer(drafts, many=True).data
        return []

    def get_published_drafts(self, obj) -> str:
        from .draft_serializer import DraftQuestionThreadSerializer

        request = self.context.get("request")
        if request and request.user.is_authenticated:
            user = request.user
            drafts = DraftQuestionThread.objects.filter(
                Q(drafter=user.interlocutor)
                & Q(question=obj)
                & ~Q(question_thread=None)
            )
            return DraftQuestionThreadSerializer(drafts, many=True).data
        return []

    def get_answered_by_friends(self, obj) -> str:
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            user = request.user
            # Check if there are question threads in the chat thread linked to the current user.
            question_threads = QuestionThread.objects.filter(
                chat_thread__interlocutors=user.interlocutor,
                question=obj,
            )

            # Exclude those chats that are authored by the current user.
            return (
                question_threads.exclude(chats__author=user.interlocutor)
                .values_list("chats__author__id", flat=True)
                .distinct()
            )
        return []


class FavouritedQuestionSerializer(serializers.ModelSerializer):
    question = QuestionSerializer()

    class Meta:
        model = FavouritedQuestion
        fields = ["id", "question", "interlocutor"]


class RatedQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RatedQuestion
        fields = ["id", "interlocutor", "question", "status"]


class UuidListSerializer(serializers.Serializer):
    question_ids = serializers.ListField(child=serializers.UUIDField(), required=True)


class FavouriteQuestionActionSerializer(serializers.Serializer):
    question_id = serializers.UUIDField(required=True)
    action = serializers.ChoiceField(choices=["favorite", "unfavorite"], required=True)


class FavouritedQuestionHiddenSerializer(serializers.ModelSerializer):
    class Meta:
        model = FavouritedQuestion
        fields = ["hidden"]
