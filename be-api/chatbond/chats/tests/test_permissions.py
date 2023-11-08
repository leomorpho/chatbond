from unittest.mock import Mock

from django.contrib.auth.models import AnonymousUser
from django.test import RequestFactory, TestCase
from parameterized import parameterized
from rest_framework.test import force_authenticate

from chatbond.chats.models import (
    ChatThread,
    DraftQuestionThread,
    Interlocutor,
    QuestionChat,
    QuestionThread,
)
from chatbond.chats.permissions import (  # IsAllowedToCreateNewChatInChatThread,
    IsAuthorOfQuestionChat,
    IsDrafterOfDraftQuestionThread,
    IsInterlocutorInChatThread,
)
from chatbond.questions.models import Question
from chatbond.users.models import User


class IsInterlocutorInChatThreadTestCase(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.permission = IsInterlocutorInChatThread()

        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.user3 = User.objects.create_user(
            email="user3@example.com", password="password123"
        )

        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.question = Question.objects.create(content="Sample Question")

        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread, question=self.question
        )

    @parameterized.expand(
        [
            ("user1@example.com", True),
            ("user2@example.com", True),
            ("user3@example.com", False),
            (None, False),
        ]
    )
    def test_is_interlocutor_in_chat_thread_permission(
        self, test_user, expected_permission
    ):
        request = self.factory.get(f"/dummy-url/{str(self.question_thread.id)}/")

        if test_user:
            user = User.objects.get(email=test_user)
            force_authenticate(request, user)
            request.user = user
        else:
            request.user = AnonymousUser()

        view = Mock()
        view.kwargs = {"question_thread_id": str(self.question_thread.id)}

        has_permission = self.permission.has_permission(request, view)  # type: ignore
        self.assertEqual(has_permission, expected_permission)


class IsAuthorOfQuestionChatTestCase(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.permission = IsAuthorOfQuestionChat()

        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )

        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.question = Question.objects.create(content="Sample Question")

        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread, question=self.question
        )

        self.chat = QuestionChat.objects.create(
            content="Sample Chat",
            question_thread=self.question_thread,
            author=self.interlocutor1,
        )

    @parameterized.expand(
        [
            ("user1@example.com", True),
            ("user2@example.com", False),
            (None, False),
        ]
    )
    def test_is_author_of_question_chat_permission(
        self, test_user, expected_permission
    ):
        request = self.factory.get("/dummy-url/")

        if test_user:
            user = User.objects.get(email=test_user)
            force_authenticate(request, user)
            request.user = user
        else:
            request.user = AnonymousUser()

        view = Mock()
        has_permission = self.permission.has_object_permission(request, view, self.chat)  # type: ignore
        self.assertEqual(has_permission, expected_permission)


class IsDrafterOfDraftQuestionThreadTestCase(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.permission = IsDrafterOfDraftQuestionThread()

        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.user3 = User.objects.create_user(
            email="user3@example.com", password="password123"
        )

        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.draft_question_thread = DraftQuestionThread.objects.create(
            drafter=self.user1.interlocutor, chat_thread=self.chat_thread
        )

    @parameterized.expand(
        [
            ("user1@example.com", True),
            ("user2@example.com", False),
            ("user3@example.com", False),
            (None, False),
        ]
    )
    def test_is_drafter_of_draft_question_thread_permission(
        self, test_user, expected_permission
    ):
        request = self.factory.get("/dummy-url/")

        if test_user:
            user = User.objects.get(email=test_user)
            force_authenticate(request, user)
            request.user = user
        else:
            request.user = AnonymousUser()

        view = Mock()
        has_permission = self.permission.has_object_permission(request, view, self.draft_question_thread)  # type: ignore
        self.assertEqual(has_permission, expected_permission)
