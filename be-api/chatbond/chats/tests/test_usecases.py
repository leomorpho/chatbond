import datetime

from django.test import TestCase
from django.utils.timezone import now
from parameterized import parameterized

from chatbond.chats.models import (
    ChatThread,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)
from chatbond.chats.usecase import (
    get_unseen_question_chats,
    set_question_chat_seen_at_field,
)
from chatbond.questions.models import Question
from chatbond.users.models import User


class GetUnseenQuestionChatsTestCase(TestCase):
    @classmethod
    def setUpTestData(self):
        # Setup Users
        user1 = User.objects.create_user(
            name="user1", email="user1@test.com", password="password"
        )
        user2 = User.objects.create_user(
            name="user2", email="user2@test.com", password="password"
        )

        self.interlocutor1 = user1.interlocutor
        self.interlocutor2 = user2.interlocutor

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)
        self.question = Question.objects.create(content="Test question")

        # Setup QuestionThread
        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread, question=self.question
        )

        # Setup QuestionChats
        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor1, question_thread=self.question_thread
        )
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor2, question_thread=self.question_thread
        )
        self.question_chat3 = QuestionChat.objects.create(
            author=self.interlocutor2, question_thread=self.question_thread
        )

        # Setup QuestionChatInteractionEvent for user1
        self.interaction_event1 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat2, interlocutor=self.interlocutor1
        )

    @parameterized.expand([("interlocutor1",), ("interlocutor2",)])
    def test_get_unseen_question_chats(self, interlocutor_attr):
        interlocutor = getattr(self, interlocutor_attr)

        unseen_chats = get_unseen_question_chats(interlocutor, self.question_thread)
        unseen_chat_ids = {chat.id for chat in unseen_chats}

        # Assert that unseen_chats contains chats that are not seen by the interlocutor
        if interlocutor_attr == "interlocutor1":
            # Since interaction_event1 has been set and no seen_at is specified,
            # question_chat2 should be included in the unseen chats for interlocutor1.
            self.assertEqual(
                {self.question_chat2.id, self.question_chat3.id}, unseen_chat_ids
            )
        elif interlocutor_attr == "interlocutor2":
            # Since no interaction event has been set for interlocutor2,
            # both question_chat1 and question_chat2 should be included in the unseen chats.
            self.assertIn(self.question_chat1.id, unseen_chat_ids)


class SetQuestionChatSeenAtFieldTestCase(TestCase):
    @classmethod
    def setUpTestData(self):
        # Setup Users
        user1 = User.objects.create_user(
            name="user1", email="user1@test.com", password="password"
        )
        user2 = User.objects.create_user(
            name="user2", email="user2@test.com", password="password"
        )

        self.interlocutor1 = user1.interlocutor
        self.interlocutor2 = user2.interlocutor

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)
        self.question = Question.objects.create(content="Test question")

        # Setup QuestionThread
        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread, question=self.question
        )

        # Setup QuestionChats
        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor1, question_thread=self.question_thread
        )
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor2, question_thread=self.question_thread
        )
        self.question_chat3 = QuestionChat.objects.create(
            author=self.interlocutor2, question_thread=self.question_thread
        )

        # Setup QuestionChatInteractionEvent for interlocutor1
        self.interaction_event1 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat2, interlocutor=self.interlocutor1
        )

    def test_set_question_chat_seen_at_field(self):
        question_chats = [self.question_chat1, self.question_chat2, self.question_chat3]

        interaction_events = QuestionChatInteractionEvent.objects.filter(
            question_chat__in=question_chats,
            interlocutor=self.interlocutor1,
            seen_at__isnull=True,
        )

        self.assertEqual(interaction_events.count(), 1)

        set_question_chat_seen_at_field(question_chats, self.interlocutor1)

        interaction_events = QuestionChatInteractionEvent.objects.filter(
            question_chat__in=question_chats, interlocutor=self.interlocutor1
        )
        self.assertEqual(interaction_events.count(), 3)

        for interaction_event in interaction_events:
            self.assertIsNotNone(interaction_event.seen_at)
            self.assertAlmostEqual(
                interaction_event.seen_at, now(), delta=datetime.timedelta(seconds=1)
            )
