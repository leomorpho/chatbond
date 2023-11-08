from datetime import timedelta
from typing import List, Set, Tuple, Union
from uuid import UUID

from django.db import models, transaction
from django.db.models import Q
from django.utils import timezone
from pgvector.django import VectorField
from simple_history.models import HistoricalRecords
from taggit.managers import TaggableManager
from taggit.models import GenericUUIDTaggedItemBase, TaggedItemBase

from chatbond.chats.models import Interlocutor
from chatbond.common.models import AbstractAuditable, AbstractPrimaryKey
from chatbond.recommender.constants import QUESTION_FEED_LIFESPAN_IN_MINUTES


class QuestionStatusChoices(models.TextChoices):
    PENDING = "P", "Pending"
    APPROVED = "A", "Approved"
    REJECTED = "R", "Rejected"
    PRIVATE = "V", "Private"


class LikedStatus(models.TextChoices):
    LIKED = "L"
    NEUTRAL = "N"
    DISLIKED = "D"


class LikedStatusTransition:
    VALID_TRANSITIONS = {
        LikedStatus.LIKED: [LikedStatus.NEUTRAL],
        LikedStatus.NEUTRAL: [LikedStatus.LIKED, LikedStatus.DISLIKED],
        LikedStatus.DISLIKED: [LikedStatus.NEUTRAL],
    }

    @classmethod
    def is_valid_transition(cls, current_status, new_status):
        return new_status in cls.VALID_TRANSITIONS.get(current_status, [])


class QuestionTag(GenericUUIDTaggedItemBase, TaggedItemBase):
    # TODO: add an embedding
    class Meta:
        verbose_name = "Tag"
        verbose_name_plural = "Tags"


class Question(AbstractPrimaryKey, AbstractAuditable):
    """
    Reverse relationships:
    - ratings (RatedQuestion):
      ForeignKey from RatedQuestion.question
    - question_threads (QuestionThread)
    """

    tags = TaggableManager(through=QuestionTag)

    content = models.TextField(unique=True)

    # Used to track questions since they are mostly created in a separate
    # system and only later uploaded to Chatbond.
    external_unique_id = models.UUIDField(null=True, blank=None, unique=True)

    # sentence-transformers/all-mpnet-base-v2
    embedding_all_mpnet_base_v2 = VectorField(dimensions=768, null=True, blank=None)
    embedding_all_mini_lml6v2 = VectorField(dimensions=384, null=True, blank=None)

    is_active = models.BooleanField(default=False)
    is_private = models.BooleanField(default=False)
    status = models.CharField(
        max_length=1,
        choices=QuestionStatusChoices.choices,
        default=QuestionStatusChoices.PENDING,
    )

    author = models.ForeignKey(
        Interlocutor,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_questions",
    )

    history = HistoricalRecords()

    def cumulative_voting_score(self) -> int:
        liked = self.ratings.filter(status=LikedStatus.LIKED).count()
        disliked = self.ratings.filter(status=LikedStatus.DISLIKED).count()
        return liked - disliked

    def times_voted(self) -> int:
        liked = self.ratings.filter(status=LikedStatus.LIKED).count()
        disliked = self.ratings.filter(status=LikedStatus.DISLIKED).count()
        return liked + disliked

    def times_answered(self) -> int:
        return self.question_threads.count()

    @staticmethod
    def get_public_questions(
        *fields: str,
    ) -> Union[List["Question"], List[Tuple[str, ...]]]:
        queryset = Question.objects.filter(
            Q(embedding_all_mpnet_base_v2__isnull=True)
            | Q(embedding_all_mini_lml6v2__isnull=True),
            is_active=True,
            status=QuestionStatusChoices.APPROVED,
        )

        if fields:
            queryset = queryset.values_list(*fields)
        return list(queryset)

    class Meta:
        abstract = False
        constraints = [
            models.UniqueConstraint(
                fields=["external_unique_id"],
                name="unique_external_id",
                condition=models.Q(external_unique_id__isnull=False),
            )
        ]


class SeenQuestion(AbstractPrimaryKey, AbstractAuditable):
    """Represents a question seen by an interlocutor"""

    interlocutor = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="questions_seen_by",
    )
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name="seen_by",
    )

    class Meta:
        abstract = False
        # This ensures that an Interlocutor can mark a specific Question
        # as a favourite only once.
        unique_together = (("interlocutor", "question"),)

    @classmethod
    def get_seen_question_ids(cls, interlocutor_id: UUID) -> Set[UUID]:
        """
        Retrieves a list of question IDs that have been seen by the given interlocutor.

        Args:
            interlocutor_id (UUID): ID of the interlocutor.

        Returns:
            List[UUID]: List of question IDs seen by the interlocutor.
        """
        seen_questions = cls.objects.filter(interlocutor_id=interlocutor_id)
        seen_question_ids = {
            seen_question.question_id for seen_question in seen_questions
        }
        return seen_question_ids


class FavouritedQuestion(AbstractPrimaryKey, AbstractAuditable):
    """
    The FavouritedQuestion model represents the relationship between an Interlocutor
    (user) and a Question that they've marked as a favourite.
    """

    # The Interlocutor who marked the Question as a favourite.
    # This sets up a many-to-one relationship where each Interlocutor can
    # have multiple favourite questions, but each FavouriteQuestion
    # is only associated with one Interlocutor.
    interlocutor = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="questions_favorited_by",
    )

    # The Question that was marked as a favourite by the Interlocutor.
    # This sets up a many-to-one relationship where each Question can
    # be marked as a favourite by multiple Interlocutors,
    # but each FavouriteQuestion is only associated with one Question.
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name="favorited_by",  # TODO: should be renamed to something more relevant
    )

    # The Interlocutors (users) that the 'interlocutor' would like
    # to ask the 'question'. This sets up a many-to-many relationship where
    # each FavouriteQuestion can have multiple target Interlocutors,
    # and each Interlocutor can be targeted by multiple FavouriteQuestions.
    # TODO: currently not supported in view or UI
    target_interlocutors = models.ManyToManyField(
        Interlocutor,
        related_name="targeted_questions",
    )

    hidden = models.BooleanField(default=False)

    history = HistoricalRecords()

    class Meta:
        abstract = False
        # This ensures that an Interlocutor can mark a specific Question
        # as a favourite only once.
        unique_together = (("interlocutor", "question"),)


class RatedQuestion(AbstractPrimaryKey, AbstractAuditable):
    interlocutor = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="rated_questions",
    )
    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name="ratings",
    )
    status = models.CharField(
        max_length=1, choices=LikedStatus.choices, default=LikedStatus.LIKED
    )

    history = HistoricalRecords()

    class Meta:
        abstract = False
        unique_together = (("interlocutor", "question"),)


class SearchedStrings(AbstractPrimaryKey, AbstractAuditable):
    searched_string = models.TextField(null=False)

    class Meta:
        abstract = False


class QuestionFeed(AbstractPrimaryKey, AbstractAuditable):
    """
    A new question feed for a user is automatically regenerated 24h
    after the datetime set in consumedAt.
    We always generate 2 question feed per user so that a user can
    manually request a new page without waiting for BE calculations.
    """

    interlocutor = models.ForeignKey(
        Interlocutor,
        on_delete=models.CASCADE,
        related_name="feed",
    )

    questions = models.ManyToManyField(
        Question,
        related_name="feeds",
    )

    # Consumed
    consumedAt = models.DateTimeField(null=True, default=None)

    @transaction.atomic
    def mark_as_consumed(self):
        """
        Marks the question feed as consumed by setting the `consumedAt` to the current time.
        Also, creates SeenQuestion objects for each Question in the feed.
        """
        if self.consumedAt is not None:
            # Already consumed, so we can skip the rest.
            return

        self.consumedAt = timezone.now()
        self.save()

        # Get the set of question IDs in the feed
        feed_question_ids = set(self.questions.values_list("id", flat=True))

        # Get the set of question IDs already seen by the interlocutor
        existing_seen_question_ids = set(
            SeenQuestion.objects.filter(
                interlocutor=self.interlocutor, question_id__in=feed_question_ids
            ).values_list("question_id", flat=True)
        )

        # Find the new question IDs that haven't been seen yet
        new_question_ids = feed_question_ids - existing_seen_question_ids

        # Create SeenQuestion objects for the new question IDs
        seen_questions_to_create = [
            SeenQuestion(interlocutor=self.interlocutor, question_id=question_id)
            for question_id in new_question_ids
        ]

        if seen_questions_to_create:
            SeenQuestion.objects.bulk_create(seen_questions_to_create)

    @classmethod
    def get_active_question_feeds(cls) -> List["QuestionFeed"]:
        # Calculate the datetime for 24 hours ago
        twenty_four_hours_ago = timezone.now() - timedelta(hours=24)

        # Retrieve active question feeds
        active_feeds = cls.objects.filter(
            models.Q(consumedAt__isnull=True)
            | models.Q(consumedAt__gte=twenty_four_hours_ago)
        )

        return list(active_feeds)

    @classmethod
    def get_active_question_feeds_for_interlocutor(
        cls,
        interlocutor_id: UUID,
        return_oldest_unconsumed: bool = False,
    ) -> List["QuestionFeed"]:
        """
        Get the active question feeds for a specific interlocutor.

        :param interlocutor_id: The UUID of the interlocutor
        :param return_oldest_unconsumed: Flag to return only the oldest unconsumed feed
        :return: A list of active question feeds or the oldest unconsumed feed
        """
        # Calculate the datetime for 24 hours ago
        twenty_four_hours_ago = timezone.now() - timedelta(hours=24)

        # Retrieve active question feeds for the specific interlocutor
        active_feeds_query = cls.objects.filter(
            models.Q(consumedAt__isnull=True)
            | models.Q(consumedAt__gte=twenty_four_hours_ago),
            interlocutor_id=interlocutor_id,
        )

        if return_oldest_unconsumed:
            oldest_unconsumed_feed = (
                active_feeds_query.filter(consumedAt__isnull=True)
                .order_by("created_at")
                .last()
            )  # Assuming 'created_at' exists in AbstractAuditable

            return [oldest_unconsumed_feed]

        return list(active_feeds_query)

    @classmethod
    def get_interlocutor_ids_with_active_question_feeds(cls) -> List[UUID]:
        # Calculate the datetime for 24 hours ago
        buffer = timezone.now() - timedelta(minutes=QUESTION_FEED_LIFESPAN_IN_MINUTES)

        # Retrieve active question feeds
        return list(
            cls.objects.filter(
                models.Q(consumedAt__isnull=True) | models.Q(consumedAt__gte=buffer)
            ).values_list("interlocutor_id", flat=True)
        )

    class Meta:
        abstract = False
