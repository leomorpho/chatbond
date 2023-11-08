from django.utils import timezone
from rest_framework.test import APITestCase

from chatbond.chats.models import (
    ChatThread,
    Interlocutor,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)
from chatbond.questions.models import Question
from chatbond.users.models import User


class QuestionThreadQuerySetTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread_1 = ChatThread.objects.create()
        self.chat_thread_1.interlocutors.add(self.interlocutor1)
        self.chat_thread_1.interlocutors.add(self.interlocutor2)

        self.question1 = Question.objects.create(content="Test question 1")
        self.question_thread_1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question1,
        )

        self.question_chat_1 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_1,
            content="Test question chat 1",
            status="published",
        )

    def test_with_unseen_messages_count(self):
        # Create an unseen interaction event for question_chat_1
        QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat_1,
            interlocutor=self.interlocutor2,
            received_at=None,
            seen_at=None,
        )

        # Test with_unseen_messages_count method
        queryset = QuestionThread.objects.with_unseen_messages_count(
            interlocutor=self.interlocutor2
        )
        self.assertEqual(queryset.count(), 1)

        # Check that the unseen message count is 1
        question_thread = queryset.first()
        self.assertEqual(question_thread.num_new_unseen_messages, 1)

        # Test with no unseen messages
        interaction_event = QuestionChatInteractionEvent.objects.get(
            question_chat=self.question_chat_1,
            interlocutor=self.interlocutor2,
        )
        interaction_event.seen_at = timezone.now()
        interaction_event.save()

        queryset = QuestionThread.objects.with_unseen_messages_count(
            interlocutor=self.interlocutor2
        )
        self.assertEqual(queryset.count(), 1)

        # Check that the unseen message count is 0
        question_thread = queryset.first()
        self.assertEqual(question_thread.num_new_unseen_messages, 0)


class ChatThreadQuerySetTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread_1 = ChatThread.objects.create()
        self.chat_thread_1.interlocutors.add(self.interlocutor1)
        self.chat_thread_1.interlocutors.add(self.interlocutor2)

        self.question1 = Question.objects.create(content="Test question 1")
        self.question_thread_1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question1,
        )

        self.question_chat_1 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_1,
            content="Test question chat 1",
            status="published",
        )

    def test_with_total_unseen_messages_count(self):
        QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat_1,
            interlocutor=self.interlocutor2,
            received_at=None,
            seen_at=None,
        )

        # Test with_total_unseen_messages_count method
        queryset = ChatThread.objects.with_total_unseen_messages_count(
            interlocutor=self.interlocutor2
        )
        self.assertEqual(queryset.count(), 1)

        # Check that the total unseen message count is 1
        chat_thread = queryset.first()
        self.assertEqual(chat_thread.num_new_unseen_messages, 1)

        # Test with no unseen messages
        interaction_event = QuestionChatInteractionEvent.objects.get(
            question_chat=self.question_chat_1,
            interlocutor=self.interlocutor2,
        )
        interaction_event.seen_at = timezone.now()
        interaction_event.save()

        queryset = ChatThread.objects.with_total_unseen_messages_count(
            interlocutor=self.interlocutor2
        )
        self.assertEqual(queryset.count(), 1)

        # Check that the total unseen message count is 0
        chat_thread = queryset.first()
        self.assertEqual(chat_thread.num_new_unseen_messages, 0)
