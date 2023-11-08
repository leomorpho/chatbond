from typing import List
from uuid import UUID


from chatbond.questions.models import Question


def get_questions_ready_to_answer(interlocutor_id: UUID) -> List[Question]:
    questions = (
        Question.objects.filter(
            question_threads__chat_thread__interlocutors__id=interlocutor_id
        )
        .exclude(question_threads__chats__author_id=interlocutor_id)
        .distinct()
    )

    return questions


def get_questions_with_drafts(interlocutor_id: UUID) -> List[Question]:
    return Question.objects.filter(
        question_threads_drafts__drafter_id=interlocutor_id,
    )
