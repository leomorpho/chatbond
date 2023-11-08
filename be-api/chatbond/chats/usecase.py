from typing import List

from django.db import transaction
from django.db.models import Q
from django.utils.timezone import now

from chatbond.chats.models import (
    ChatThread,
    Interlocutor,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)

# TODO: these are not usecases...not thinking too hard about architecture for now...


def get_unseen_question_chats(
    interlocutor: Interlocutor, question_thread: QuestionThread
) -> List[QuestionChat]:
    """
    Function to get unseen question chats for the current interlocutor in a specified
    question thread.

    Parameters:
        interlocutor (Interlocutor): The current user as an interlocutor.
        question_thread (QuestionThread): The specific question thread to look
        for unseen question chats.

    Returns:
        List[QuestionChat]: A list of unseen question chats for the current interlocutor
        in the specified question thread.

    The Django ORM query works as follows:

    1. The filter(~Q(author=interlocutor), question_thread=question_thread) selects
       QuestionChat instances that do not belong to the current interlocutor and
       belong to the specified question thread.

    2. The next filter statement has an OR operator (|) and it works as follows:

       a) Q(interaction_events__interlocutor=interlocutor, interaction_events__seen_at__isnull=True)
          This condition checks for QuestionChat instances that have a QuestionChatInteractionEvent associated
          with the current interlocutor, but the 'seen_at' field is set to None (meaning they have not been seen by the interlocutor).

       b) ~Q(interaction_events__interlocutor=interlocutor)
          This condition checks for QuestionChat instances that do not have a QuestionChatInteractionEvent
          associated with the current interlocutor.
    """
    question_chats = QuestionChat.objects.filter(
        ~Q(author=interlocutor),
        question_thread=question_thread,
    ).filter(
        Q(
            interaction_events__interlocutor=interlocutor,
            interaction_events__seen_at__isnull=True,
        )
        | ~Q(interaction_events__interlocutor=interlocutor)
    )

    return question_chats


def set_question_chat_seen_at_field(
    question_chats: List[QuestionChat], interlocutor: Interlocutor
) -> None:
    # Fetch existing QuestionChatInteractionEvent instances
    existing_interaction_events = QuestionChatInteractionEvent.objects.filter(
        question_chat__in=question_chats, interlocutor=interlocutor
    )

    # Update seen_at for existing instances and prepare a list of chat_ids that were updated
    current_time = now()
    updated_chat_ids = []
    for interaction_event in existing_interaction_events:
        interaction_event.seen_at = current_time
        updated_chat_ids.append(interaction_event.question_chat_id)

    # Bulk update existing instances
    QuestionChatInteractionEvent.objects.bulk_update(
        existing_interaction_events, ["seen_at"]
    )

    # Prepare a list of new instances to be created
    new_interaction_events = [
        QuestionChatInteractionEvent(
            question_chat=question_chat,
            interlocutor=interlocutor,
            seen_at=current_time,
        )
        for question_chat in question_chats
        if question_chat.id not in updated_chat_ids
    ]

    # Bulk create new instances
    QuestionChatInteractionEvent.objects.bulk_create(new_interaction_events)


def create_chat_thread(interlocutors: List[Interlocutor]) -> ChatThread:
    with transaction.atomic():
        # Sort interlocutor IDs for a standardized comparison
        interlocutor_ids = sorted([interlocutor.id for interlocutor in interlocutors])

        # Search for existing thread with the same interlocutors
        existing_threads = ChatThread.objects.filter(interlocutors__in=interlocutor_ids)

        for thread in existing_threads:
            if sorted([i.id for i in thread.interlocutors.all()]) == interlocutor_ids:
                return thread

        # Create a new thread if none found
        new_thread = ChatThread.objects.create()
        new_thread.interlocutors.set(interlocutors)
        return new_thread
