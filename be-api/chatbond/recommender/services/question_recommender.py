import logging
import random
from typing import List, Set
from uuid import UUID

import numpy as np
from django.core.cache import cache
from sentence_transformers import SentenceTransformer

from chatbond.chats.models import Interlocutor, QuestionThread
from chatbond.questions.models import (FavouritedQuestion, LikedStatus,
                                       Question, QuestionFeed, RatedQuestion,
                                       SeenQuestion)
from chatbond.recommender.constants import (
    DEFAULT_QUESTION_IDS, MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH,
    NUM_ONBOARDING_QUESTIONS, NUM_QUESTIONS_IN_FEED_RANDOM,
    NUM_QUESTIONS_IN_FEED_SIMILAR_TO_TASTES)

from .recommenders.annoy_recommender import AnnoyRecommender

ANNOY_RECOMMENDER_NAME = "AnnoyRecommender"

logger = logging.getLogger()


class ModelNotLoadedError(Exception):
    """Exception raised when a model is accessed but not loaded.

    Attributes:
        model_name -- name of the model
        message -- explanation of the error
    """

    def __init__(self, model_name: str, message: str = "Model was not loaded") -> None:
        self.filename = model_name
        self.message = message
        super().__init__(self.message)

    def __str__(self):
        return f"{self.filename} -> {self.message}"


class QuestionRecommender:
    def __init__(self):
        self._annoy_recommender = None

    def load_models(self) -> None:
        """
        Before loading the models, the models must be either loaded from file,
        S3, or be trained from scratch.
        """
        if self._annoy_recommender is None:
            self._annoy_recommender = AnnoyRecommender()

    def embed_string(self, content: str):
        # TODO: this will fail if this model doesn't exist locally
        model = SentenceTransformer(MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH)
        return model.encode(content, show_progress_bar=False).astype(np.float64)

    def get_interlocutors_needing_new_question_feeds(self) -> Set[UUID]:
        """
        Retrieves the set of interlocutor IDs that need new question feeds.

        Returns:
            A set of interlocutor IDs.
        """
        all_active_interlocutor_ids: Set[UUID] = {
            x[0] for x in Interlocutor.get_active_interlocutors("id")  # type: ignore
        }

        interlocutor_ids_with_active_question_feeds = set(
            QuestionFeed.get_interlocutor_ids_with_active_question_feeds()
        )
        # TODO: on onboarding, a new question feed should be created for the interlocutor

        return all_active_interlocutor_ids - interlocutor_ids_with_active_question_feeds

    def _get_n_random_question_ids(self, n: int, exclude_ids: Set[UUID]) -> List[UUID]:
        # Try to get the set of all question IDs from the cache
        question_ids = cache.get("all_question_ids")

        # If the cache is empty, fetch the set from the database and store it in the cache
        if question_ids is None:
            question_ids = set(Question.objects.values_list("id", flat=True))
            cache.set("all_question_ids", question_ids)

        # Exclude the IDs we don't want
        question_ids = question_ids - exclude_ids

        # Randomly select n question IDs
        if len(question_ids) <= n:
            random_question_ids = list(question_ids)
        else:
            random_question_ids = random.sample(question_ids, n)

        return random_question_ids

    # TODO: no UTs
    def get_recommended_questions_ids_for_interlocutor(
        self,
        interlocutor_id: UUID,
        num_rand_questions=NUM_QUESTIONS_IN_FEED_RANDOM,
        num_near_questions=NUM_QUESTIONS_IN_FEED_SIMILAR_TO_TASTES,
    ) -> List[UUID]:
        if self._annoy_recommender is None:
            raise ModelNotLoadedError(ANNOY_RECOMMENDER_NAME)

        # TODO: Also select a random subset of questions favorited
        # and drafted by others. The drafts could be targeted for the
        # current interlocutor.

        # Get all questions answered in question threads shared by this interlocutor
        answered_ids: Set[UUID] = set(
            QuestionThread.objects.filter(
                chat_thread__interlocutors__id__contains=interlocutor_id
            ).values_list("question_id", flat=True)
        )

        # Get all questions favorited
        favorited_ids: Set[UUID] = set(
            FavouritedQuestion.objects.filter(
                interlocutor_id=interlocutor_id,
            ).values_list("question_id", flat=True)
        )

        # Get all questions liked
        liked_ids: Set[UUID] = set(
            RatedQuestion.objects.filter(
                interlocutor_id=interlocutor_id, status=LikedStatus.LIKED
            ).values_list("question_id", flat=True)
        )

        seen_ids: Set[UUID] = SeenQuestion.get_seen_question_ids(interlocutor_id)

        # Question IDs to use as seed in search
        seed_ids: Set[UUID] = liked_ids | favorited_ids | answered_ids
        logger.debug(f"seed_ids for interlocutor id {interlocutor_id}: {seed_ids}")

        # Question IDs to forget about for a time
        exclude_ids = seen_ids | seed_ids
        logger.debug(
            f"exclude_ids for interlocutor id {interlocutor_id}: {exclude_ids}"
        )

        near_ids = set()
        if len(seed_ids) != 0:
            seed_embeddings = list(
                Question.objects.filter(id__in=seed_ids).values_list(
                    "embedding_all_mini_lml6v2", flat=True
                )
            )
            near_ids: Set[UUID] = self._annoy_recommender.find_near_similar(
                embeddings=seed_embeddings,
                num_searched=100,
                num_rand_returned=num_near_questions,
                exclude_external_id_list=exclude_ids,
            )
            logger.debug(
                f"Near questions for interlocutor {interlocutor_id}: {near_ids}"
            )
            # Select 10 random unseen question IDs from outside the near_ids list. This is
            # to help the user find new topics and areas of interest.
            random_ids: List[UUID] = self._get_n_random_question_ids(
                n=num_rand_questions, exclude_ids=(near_ids | exclude_ids)
            )
            return list(near_ids) + random_ids
        else:
            logger.info(
                f"returning onboarding questions for interlocutor with id {interlocutor_id}"
            )
            return [x.id for x in self.get_onboarding_questions()]

    def nearest_neighbors(
        self, embedding: List[float], num_results: int = 20
    ) -> List[UUID]:
        if self._annoy_recommender is None:
            self.load_models()

        return self._annoy_recommender.nearest_neighbors(
            embedding, num_results=num_results
        )

    @staticmethod
    def get_default_questions_ids() -> List[UUID]:
        """Create helper method to easily mock default question IDs."""
        return DEFAULT_QUESTION_IDS

    def get_onboarding_questions(cls, num=NUM_ONBOARDING_QUESTIONS) -> List[Question]:
        return Question.objects.filter(
            external_unique_id__in=cls.get_default_questions_ids()
        ).order_by("?")[:num]


# Wait until it is initialized. Because we need the trained model, and it
# either (a) needs to be trained or (b) be loaded from S3, we cannot instantiate
# this.
# NOTE: some methods on QuestionRecommender can only be used after initialization.
# TODO: improve how this works.
questionRecommender = QuestionRecommender()
