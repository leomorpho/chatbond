from typing import (
    List,
    Tuple,  # noqa: F401
    Union,
)

from django.db import models
from django.utils import timezone
from simple_history.models import HistoricalRecords

from chatbond.chats.custom_queryset import ChatThreadQuerySet, QuestionThreadQuerySet
from chatbond.common.models import AbstractAuditable, AbstractPrimaryKey


class Interlocutor(AbstractPrimaryKey, AbstractAuditable):
    """
    Represents an interlocutor within the chats app, which is a user in the
    context of chat-related activities.

    Attributes:
        user (OneToOneField): A one-to-one relationship with the User model,
            representing the user associated with this interlocutor.

    Reverse relationships:
        - chat_threads (ChatThread): ForeignKey from ChatThread.interlocutors,
            representing the chat threads this interlocutor is part of.
        - question_chats (QuestionChat): ForeignKey from QuestionChat.author,
            representing the question chats authored by this interlocutor.
        - created_invitations (Invitation): ForeignKey from Invitation.inviter,
            representing the chat invitations created by this interlocutor.
        - rated_questions (RatedQuestion):
            ForeignKey from RatedQuestion.interlocutor,
            representing the question like events involving this interlocutor.
        - created_questions (question.Question)
    """

    # TODO: should we CASCADE or SET_NULL?
    user = models.OneToOneField("users.User", on_delete=models.CASCADE)

    @staticmethod
    def get_active_interlocutors(
        *fields: str,
    ) -> Union[List["Interlocutor"], List[Tuple[str, ...]]]:
        queryset = Interlocutor.objects.filter(
            user__is_active=True,
        )

        if fields:
            queryset = queryset.values_list(*fields)
        return list(queryset)

    class Meta:
        abstract = False


class AbstractChat(AbstractAuditable):
    """
    Abstract base model for a chat, representing messages exchanged between users.

    This model should be subclassed by other chat types to store specific
    chat-related information.
    """

    content = models.TextField()

    class Meta:
        abstract = True


class ChatThread(AbstractPrimaryKey, AbstractAuditable):
    """
    Represents a chat room that connects a group of users for conversation.

    A ChatThread allows multiple Interlocutors to exchange messages in a
    shared environment.
    """

    objects = ChatThreadQuerySet.as_manager()

    interlocutors = models.ManyToManyField(
        Interlocutor,
        related_name="chat_threads",
    )

    # Reverse relationships:
    # - question_threads (QuestionThread): ForeignKey from QuestionThread.chat_thread

    class Meta:
        abstract = False


class QuestionThread(AbstractPrimaryKey, AbstractAuditable):
    """
    Associates a sequence of question chats with a specific question.

    A QuestionThread represents a conversation related to a particular question,
    allowing users to discuss and answer the question through a series of QuestionChats.
    """

    # To Prevent circular import
    from chatbond.questions.models import Question

    objects = QuestionThreadQuerySet.as_manager()

    # TODO: should we CASCADE or SET_NULL
    chat_thread = models.ForeignKey(
        ChatThread,
        on_delete=models.CASCADE,
        related_name="question_threads",
    )
    question = models.ForeignKey(
        Question,
        on_delete=models.SET_NULL,
        related_name="question_threads",
        null=True,
    )

    all_interlocutors_answered = models.BooleanField(default=False)

    # Reverse relationships:
    # - chats (QuestionChat): ForeignKey from QuestionChat.question_thread
    # - last_seen_question_events (QuestionThreadInteractionEvent): ForeignKey from
    #   QuestionThreadInteractionEvent.question_thread

    class Meta:
        abstract = False
        unique_together = ("chat_thread", "question")


class QuestionChat(AbstractPrimaryKey, AbstractChat):
    """
    Represents a chat specific to answering questions within the chats app.

    A QuestionChat is a message within a QuestionThread, allowing users to contribute
    to the discussion and help answer the associated question.
    """

    STATUS_CHOICES = [
        ("published", "Published"),
        ("draft", "Draft"),
        ("pending", "Pending"),  # TODO: Why this one? Is it ever used?
        ("deleted", "Deleted"),
    ]

    # TODO: should we CASCADE or SET_NULL?
    author = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="question_chats",
    )
    # TODO: should we CASCADE or SET_NULL?
    question_thread = models.ForeignKey(
        QuestionThread,
        on_delete=models.CASCADE,
        related_name="chats",
    )

    # TODO: pretty sure below field is dead
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default="draft",
    )

    history = HistoricalRecords()

    # - last_seen_chat_events (QuestionChatInteractionEvent): ForeignKey from
    #   QuestionChatInteractionEvent.question_chat

    class Meta:
        abstract = False

    def save(self, *args, **kwargs):
        # Update the related instances' `updated_at` fields
        self.question_thread.updated_at = timezone.now()
        self.question_thread.save()

        self.question_thread.chat_thread.updated_at = timezone.now()
        self.question_thread.chat_thread.save()

        super().save(*args, **kwargs)  # Call the "real" save() method.


class DraftQuestionThread(AbstractPrimaryKey, AbstractAuditable):
    """A draft question thread created when an interlocutor starts drafting an answer.

    The draft is visible only to the creator. Upon publishing, the draft is converted
    into a real question thread, visible to all members in the chat thread.
    """

    # To Prevent circular import
    from chatbond.questions.models import Question

    chat_thread = models.ForeignKey(
        ChatThread,
        on_delete=models.CASCADE,
        related_name="question_threads_drafts",
    )
    question = models.ForeignKey(
        Question,
        on_delete=models.SET_NULL,
        related_name="question_threads_drafts",
        null=True,
    )
    drafter = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="drafts",
    )
    question_thread = models.ForeignKey(
        QuestionThread,
        on_delete=models.CASCADE,
        related_name="draft",
        null=True,
    )
    content = models.TextField()
    published_at = models.DateTimeField(default=None, null=True)

    class Meta:
        abstract = False
        unique_together = ("chat_thread", "question", "drafter")

    @property
    def interlocutor(self):
        # TODO: does not support multiple interlocutors (more than 2) in a chat thread.
        other_interlocutors = self.chat_thread.interlocutors.exclude(id=self.drafter.id)
        return other_interlocutors[0] if other_interlocutors.exists() else None


class QuestionChatInteractionEvent(AbstractPrimaryKey, AbstractAuditable):
    """Records interactions a user has with a question chat."""

    question_chat = models.ForeignKey(
        QuestionChat,
        on_delete=models.CASCADE,
        related_name="interaction_events",
    )
    interlocutor = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
    )
    # TODO: I don't think it makes any sense to allow null for received_at.
    # This object should only get created on first receive, no?
    received_at = models.DateTimeField(default=None, null=True)
    seen_at = models.DateTimeField(default=None, null=True)

    # TODO: this is where we would associate emojis with chats
    class Meta:
        abstract = False
        unique_together = ("question_chat", "interlocutor")
