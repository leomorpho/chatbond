import ast
import logging
from datetime import timedelta

import dramatiq
import pandas as pd
from django.db.utils import IntegrityError
from django.utils.timezone import now

from chatbond.config import FORGET_SEEN_QUESTION_LIFESPAN_IN_DAYS
from chatbond.questions.models import (Question, QuestionStatusChoices,
                                       SeenQuestion)
from chatbond.recommender.services.question_recommender import \
    questionRecommender

logger = logging.getLogger()


def trigger_task_to_delete_expired_seen_question_objects():
    """Helper method to trigger task"""
    delete_expired_seen_question_objects.send()


@dramatiq.actor
def delete_expired_seen_question_objects():
    """
    Beyond a certain age, allow a seen question to be seen again by a user

    The user may have changed and might now be interested again in the questions
    they previously saw but did not interact with.
    """
    # TODO: the more questions we have in the question bank,
    # the smaller we can make the delta
    thirty_days_ago = now() - timedelta(days=FORGET_SEEN_QUESTION_LIFESPAN_IN_DAYS)
    SeenQuestion.objects.filter(created_at__lt=thirty_days_ago).delete()


@dramatiq.actor
def load_questions_from_csv(num_questions=None):
    """
    Used to populate the Question model with data from a CSV.

    In Django shell:
    >>> from chatbond.questions.tasks import load_questions_from_csv
    >>> load_questions_from_csv()
    """
    logger.info("Start loading all questions from csv...")
    csv_file_path = "chatbond/questions/data/questions.csv"

    # TODO: this function has no logic to verify whether a question already exists.
    #   This is not to be used beyond development, especially once users can create their
    #   own questions, since we'll need to make sure to never change important fields like
    #   'author', 'status', 'is_active' and 'is_private'.

    # Load the CSV into a DataFrame
    df = pd.read_csv(csv_file_path)

    # If num_questions is specified, only use a subset of the DataFrame
    if num_questions is not None:
        # Filter out the onboarding questions
        onboarding_ids = questionRecommender.get_default_questions_ids()
        onboarding_df = df[df["unique_id"].isin(onboarding_ids)]
        other_df = df[~df["unique_id"].isin(onboarding_ids)]
        other_df = other_df.head(num_questions - len(onboarding_df))
        df = pd.concat([onboarding_df, other_df])

    questions = []

    # Iterate over the rows of the DataFrame
    for _, row in df.iterrows():
        # Convert the string representation of the list to an actual list of floats
        # embedding_all_mpnet_base_v2 = ast.literal_eval(
        #     row["embedding_all_mpnet_base_v2"]
        # )
        tags = ast.literal_eval(row["tags"])

        # Create a new Question object and add it to the list
        question = Question(
            content=row["question"],
            # embedding_all_mpnet_base_v2=embedding_all_mpnet_base_v2,
            status=QuestionStatusChoices.APPROVED,  # or whatever default status you'd like to use
            is_active=True,  # or False, depending on your requirements
            is_private=False,  # or True, depending on your requirements
            external_unique_id=row["unique_id"],
        )

        questions.append(question)

    # Attempt to bulk create all questions
    Question.objects.bulk_create(questions)

    # Since Django doesn't currently support bulk adding of tags, we need to add tags in a separate loop.
    for question, row in zip(questions, df.itertuples()):
        tags = ast.literal_eval(row.tags)
        question.tags.add(*tags)

    logger.info("Loaded all questions from csv.")
