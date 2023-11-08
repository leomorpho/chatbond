import csv
import logging
import os
from typing import List
from uuid import UUID

import dramatiq
import numpy as np
from django.core.cache import cache
from django.utils import timezone
from dramatiq import pipeline
from sentence_transformers import SentenceTransformer

from chatbond.chats.models import Interlocutor
from chatbond.infra.files import (S3FileNotFoundError, delete_file,
                                  download_s3_file, unzip_file, upload_s3_file)
from chatbond.infra.tasks import download_to_local_and_upload_to_s3
from chatbond.questions.models import (LikedStatus, Question, QuestionFeed,
                                       QuestionStatusChoices, RatedQuestion)
from chatbond.recommender.services.question_recommender import \
    questionRecommender
from chatbond.recommender.services.recommenders.annoy_recommender import \
    AnnoyModelBuilder

from .constants import (ALL_MINI_LML6V2_SRC, ANNOY_INDEX_LOCAL_PATH,
                        ANNOY_INDEX_TO_ID_LOCAL_PATH,
                        ANNOY_QUESTION_INDEX_S3_FILE,
                        ANNOY_QUESTION_INDEX_TO_ID_S3_FILE,
                        MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH,
                        MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH,
                        SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE)

QUESTION_FEED_BATCH_SIZE = 100

logger = logging.getLogger()


def trigger_tasks_for_first_load(rebuild_models=True) -> None:
    """Helper method to start tasks"""
    prepare_first_load.send(rebuild_models=rebuild_models)


def create_onboarding_question_feed(interlocutor_id: UUID) -> QuestionFeed:
    questions = questionRecommender.get_onboarding_questions()

    # If a user has answered a question for all of their connected friends, that question
    # should not be included here.
    questionFeed = QuestionFeed.objects.create(interlocutor_id=interlocutor_id)
    questionFeed.questions.add(*questions)
    return questionFeed


@dramatiq.actor
def prepare_first_load(rebuild_models=True) -> None:
    """
    Prepare all data for proper execution of chatbond-api.

    This task could probably live somewhere else.
    """
    # Chain tasks
    pipe = pipeline(
        [
            download_sentence_transformer_model_if_needed.message_with_options(
                pipe_ignore=True,
            ),
            _create_embeddings_for_public_questions_if_needed.message_with_options(
                pipe_ignore=True,
            ),
            create_new_question_feeds_if_needed.message_with_options(
                args=(rebuild_models,),
                pipe_ignore=True,
            ),
        ]
    )

    # Run the pipeline
    pipe.run()


@dramatiq.actor
def download_sentence_transformer_model_if_needed() -> None:
    # If model not available locally:
    # 1. download from S3
    # 2. if not on S3, download from source and upload to S3
    if os.path.exists(MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH):
        logger.info(
            f"unzipped file {MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH} already exists"
        )
        return
    try:
        download_s3_file(
            file_name=SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE,
            destination=MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH,
            overwrite=False,
        )
    except FileExistsError:
        logger.info(
            "attempted to download "
            f"{SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE} "
            "but it already exists locally at path "
            f"{MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH}"
        )
        upload_s3_file(
            MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH,
            SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE,
            overwrite=False,
        )
    except S3FileNotFoundError:
        logger.error(
            f"{SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE} not available on S3."
        )
        # We need it locally, but make sure we have it in S3 next time around.
        download_to_local_and_upload_to_s3(
            url=ALL_MINI_LML6V2_SRC,
            local_filename=MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH,
            s3_filename=SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE,
        )

    os.makedirs(MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH, exist_ok=True)
    unzip_file(
        zip_filepath=MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH,
        dest_dir=MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH,
    )
    delete_file(MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH)


@dramatiq.actor
def _download_or_build_annoy_index_if_needed(rebuild_models=False) -> None:
    # If model not available locally:
    # 1. download from S3
    # 2. if not on S3, build and upload to S3
    if rebuild_models:
        _build_and_persist_annoy_index.send()
    else:
        try:
            download_s3_file(
                file_name=ANNOY_QUESTION_INDEX_S3_FILE,
                destination=ANNOY_INDEX_LOCAL_PATH,
                overwrite=rebuild_models,
            )
            download_s3_file(
                file_name=ANNOY_QUESTION_INDEX_TO_ID_S3_FILE,
                destination=ANNOY_INDEX_TO_ID_LOCAL_PATH,
                overwrite=rebuild_models,
            )
        except FileExistsError:
            logger.info(
                f"attempted to download {ANNOY_QUESTION_INDEX_S3_FILE} and "
                f"and {ANNOY_QUESTION_INDEX_TO_ID_S3_FILE} "
                f"but it already exists locally at path {ANNOY_INDEX_LOCAL_PATH} "
                f"and {ANNOY_INDEX_TO_ID_LOCAL_PATH}"
            )
        except S3FileNotFoundError:
            _build_and_persist_annoy_index.send()


@dramatiq.actor
def _load_annoy_index_into_cache() -> None:
    """
    This function reads the AnnoyIndex and index-to-ID mapping files from the disk
    and loads them into the cache.

    :param annoy_index_filepath: The path to the AnnoyIndex file.
    :param annoy_id_map_filepath: The path to the index-to-ID mapping file.
    """
    if os.path.exists(ANNOY_INDEX_LOCAL_PATH) and os.path.exists(
        ANNOY_INDEX_TO_ID_LOCAL_PATH
    ):
        # Load the AnnoyIndex from the file
        with open(ANNOY_INDEX_LOCAL_PATH, "rb") as index_file:
            annoy_index_content = index_file.read()

        # Load the index-to-ID mapping from the file
        with open(ANNOY_INDEX_TO_ID_LOCAL_PATH, "rb") as map_file:
            annoy_index_to_id_content = map_file.read()

        # Save the files content to Redis cache
        cache.set("annoy_index", annoy_index_content)
        cache.set("annoy_index_to_id", annoy_index_to_id_content)
    else:
        raise FileNotFoundError("The provided file paths do not exist.")


@dramatiq.actor
def _build_and_persist_annoy_index() -> None:
    # Assume that the function `get_public_questions` returns a list of tuples
    # where each tuple contains the id and the embedding of a question.
    questions = Question.get_public_questions("id", "embedding_all_mini_lml6v2")
    question_ids: List[UUID] = [question[0] for question in questions]  # type: ignore
    question_embeddings: List[List[float]] = [question[1] for question in questions]  # type: ignore

    # Define the length of the item vector
    f = len(question_embeddings[0])

    # Create an AnnoyModelBuilder
    annoyModelBuilder = AnnoyModelBuilder(dimension=f)

    # Add all the vectors to the index
    for i, (question_id, embedding) in enumerate(
        zip(question_ids, question_embeddings)
    ):
        # TODO: Illegal instruction (core dumped)
        annoyModelBuilder.add_item(i, question_id, embedding)

    # Build the index
    annoyModelBuilder.build(n_trees=10)

    # Save the index and the mapping to files
    annoyModelBuilder.save(
        annoy_index_filepath=ANNOY_INDEX_LOCAL_PATH,
        annoy_id_map_filepath=ANNOY_INDEX_TO_ID_LOCAL_PATH,
        save_to_s3=True,
    )


@dramatiq.actor(time_limit=60000)
def create_new_question_feed_for_interlocutor_ids(interlocutor_ids: List[str]):
    questionRecommender.load_models()
    logger.info(f"Creating new question feeds for interlocutor IDs {interlocutor_ids}")
    for interlocutor_id in interlocutor_ids:
        interlocutor_id_uuid = UUID(interlocutor_id)
        question_ids = (
            questionRecommender.get_recommended_questions_ids_for_interlocutor(
                interlocutor_id_uuid
            )
        )
        questions = Question.objects.filter(id__in=question_ids)
        feed = QuestionFeed.objects.create(interlocutor_id=interlocutor_id)
        feed.questions.add(*questions)
    logger.info(
        "Successfully created new question feeds for "
        f"interlocutor IDs {interlocutor_ids}"
    )


@dramatiq.actor
def _create_new_question_feeds_if_needed() -> None:
    # NOTE: recommender models must be locally available or task will fail
    interlocutor_ids = [
        str(x)
        for x in (questionRecommender.get_interlocutors_needing_new_question_feeds())
    ]  # type: List[str]

    for i in range(0, len(interlocutor_ids), QUESTION_FEED_BATCH_SIZE):
        batch_ids = interlocutor_ids[i : i + QUESTION_FEED_BATCH_SIZE]
        create_new_question_feed_for_interlocutor_ids.send(batch_ids)


def trigger_task_to_create_new_question_feeds_if_needed():
    """Helper method to start tasks"""
    create_new_question_feeds_if_needed.send()


@dramatiq.actor
def create_new_question_feeds_if_needed(rebuild_models=False) -> None:
    pipe = pipeline(
        [
            _download_or_build_annoy_index_if_needed.message_with_options(
                args=(rebuild_models,),
                pipe_ignore=True,
            ),
            _load_annoy_index_into_cache.message_with_options(pipe_ignore=True),
            _create_new_question_feeds_if_needed.message_with_options(pipe_ignore=True),
        ]
    )

    # Run the pipeline
    pipe.run()


@dramatiq.actor
def create_all_mpnet_base_v2_embeddings_for_questions(
    questions: List[Question],
) -> None:
    """
    Creates embeddings using the 'all-mpnet-base-v2' model for a list of questions.

    Args:
        questions (List[Question]): The list of questions to create embeddings for.

    Returns:
        None
    """
    model = SentenceTransformer(MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH)
    # Create embeddings for each question
    for question in questions:
        question.embedding_all_mpnet_base_v2 = model.encode(
            question.content, show_progress_bar=False
        )

    Question.objects.bulk_update(questions, ["embedding_all_mpnet_base_v2"])


def trigger_task_to_create_embeddings_for_public_questions_if_needed() -> None:
    """Helper method to start tasks"""
    _create_embeddings_for_public_questions_if_needed.send()


# TODO: run once a day
@dramatiq.actor
def _create_embeddings_for_public_questions_if_needed() -> None:
    """
    This task makes sure that all public questions have the expected embeddings
    """
    model = SentenceTransformer(MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH)
    update_questions = []
    questions: List[Question] = Question.get_public_questions()  # type: ignore

    for question in questions:
        if question.embedding_all_mini_lml6v2 is None:
            question.embedding_all_mini_lml6v2 = model.encode(
                question.content, show_progress_bar=False
            ).astype(np.float64)
            update_questions.append(question)

    Question.objects.bulk_update(questions, ["embedding_all_mini_lml6v2"])


@dramatiq.actor
def extract_recommender_training_data() -> None:
    """
    Extract questions data to train a machine learning algorithm.

    In Django shell:
    >>> from chatbond.recommender.tasks import extract_recommender_training_data
    >>> extract_recommender_training_data()
    """
    user_ids = Interlocutor.objects.all().values_list("id", flat=True)
    questions = Question.objects.filter(
        is_active=True, status=QuestionStatusChoices.APPROVED, embedding__isnull=False
    )  # .values_list("id", "content", "embedding")

    questions_data = []
    for q in questions:
        questions_data.append([q.id, q.content, q.embedding.tolist()])

    user_actions = []

    for question_liked_event in RatedQuestion.objects.filter(
        question__embedding__isnull=False,
    ):
        user_actions.append(
            {
                "user_id": question_liked_event.interlocutor.id,
                "question_id": question_liked_event.question.id,
                "action": question_liked_event.status,
            }
        )
    action_weights = {
        LikedStatus.LIKED: 1.0,
        LikedStatus.DISLIKED: -1.0,
        "favorites": 2.0,
        "answered": 3.0,
    }
    interactions_data = [
        (action["user_id"], action["question_id"], action_weights[action["action"]])
        for action in user_actions
    ]

    timestamp = timezone.now().strftime("%Y-%m-%d_%H-%M-%S")
    directory_name = f"data/exports/recommender_training_data/{timestamp}"
    os.makedirs(os.path.dirname(directory_name), exist_ok=True)

    # Save user_ids to CSV
    with open(f"{directory_name}/user_ids.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["user_id"])
        writer.writerows([[user_id] for user_id in user_ids])

    # Save questions_data to CSV
    with open(f"{directory_name}/questions_data.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["question_id", "content", "embedding"])
        writer.writerows(questions_data)

    # Save interactions_data to CSV
    with open(f"{directory_name}/interactions_data.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["user_id", "question_id", "action_weight"])
        writer.writerows(interactions_data)
