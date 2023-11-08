from django.db import models
from django.db.models import Count, Q


class QuestionThreadQuerySet(models.QuerySet):
    def with_unseen_messages_count(self, interlocutor):
        # Annotates the QuerySet with the count of unseen messages for
        # the given interlocutor.
        return self.annotate(
            # The count is based on the number of QuestionChats that match the
            # conditions in the Case.
            num_new_unseen_messages=models.Count(
                models.Case(
                    # The When statement checks for the following two conditions:
                    # 1. A QuestionChat has no corresponding
                    #    QuestionChatInteractionEvent objects
                    #    belonging to the current interlocutor.
                    # 2. A QuestionChat has a corresponding QuestionChatInteractionEvent
                    #    object with the seen_at field set to None (meaning it has not
                    #    been seen yet).
                    # The models.Q function is used to create complex queries
                    # with OR conditions.
                    models.When(
                        # The first condition checks for the existence of a
                        # QuestionChatInteractionEvent with the current interlocutor
                        # and seen_at set to None.
                        (
                            models.Q(
                                chats__interaction_events__interlocutor=interlocutor,
                                chats__interaction_events__seen_at__isnull=True,
                            )
                            # The OR operator (|) is used to combine two conditions.
                            |
                            # The second condition checks if there are no
                            # QuestionChatInteractionEvent objects for the current
                            # interlocutor.
                            models.Q(chats__interaction_events__isnull=True)
                        )
                        & ~models.Q(chats__author=interlocutor),
                        # If all conditions are met, then the unseen message count
                        # is incremented.
                        then=1,
                    ),
                    # If none of the conditions are met, the unseen message count
                    # remains the same.
                    default=None,
                    # The output field is an integer to store the count
                    # of unseen messages.
                    output_field=models.IntegerField(),
                )
            )
        )


class ChatThreadQuerySet(models.QuerySet):
    def with_total_unseen_messages_count(self, interlocutor):
        # Annotate each ChatThread object with a new field `num_new_unseen_messages`.
        return self.annotate(
            num_new_unseen_messages=Count(
                # Use CASE-WHEN construct to conditionally count the messages.
                models.Case(
                    models.When(
                        (
                            (
                                # The first condition: Unseen messages for the given
                                # interlocutor. This matches where the interlocutor has
                                # not seen the message (`seen_at__isnull=True`).
                                Q(
                                    question_threads__chats__interaction_events__interlocutor=interlocutor,
                                    question_threads__chats__interaction_events__seen_at__isnull=True,
                                )
                                # The second condition: Interactions events for the
                                # chats are null. This is for catching chats where
                                # interaction_events are not available.
                                | Q(
                                    question_threads__chats__interaction_events__isnull=True
                                )
                            )
                            # Exclude the messages authored by the interlocutor themselves.
                            & ~Q(question_threads__chats__author=interlocutor)
                        )
                        # Exclude question_threads that have
                        # no chats (i.e., chats__isnull=True).
                        & ~Q(question_threads__chats__isnull=True),
                        # When any of the above conditions are met,
                        # count it as 1 unseen message.
                        then=1,
                    ),
                    # If none of the conditions are met, do not count it.
                    default=None,
                    output_field=models.IntegerField(),
                )
            )
        )
