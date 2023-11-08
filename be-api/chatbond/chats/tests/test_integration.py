from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from chatbond.chats.models import (
    ChatThread,
    Interlocutor,
)
from chatbond.questions.models import Question, QuestionFeed
from chatbond.users.models import User


class TestChatsIntegration(APITestCase):
    def setUp(self):
        self.client = APIClient()

        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.user3 = User.objects.create_user(
            email="user3@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)
        self.interlocutor3 = Interlocutor.objects.get(user=self.user3)

        self.chat_thread_1 = ChatThread.objects.create()
        self.chat_thread_1.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.chat_thread_2 = ChatThread.objects.create()
        self.chat_thread_2.interlocutors.add(self.interlocutor1, self.interlocutor3)

        self.question1 = Question.objects.create(content="Test question 1")
        self.question2 = Question.objects.create(content="Test question 2")
        self.question3 = Question.objects.create(content="Test question 3")

        self.interlocutor1_home_feed = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1,
        )
        self.interlocutor1_home_feed.questions.add(self.question1, self.question2)

    def do_test(self):
        # USER 1: get home feed
        response = self.client.get("/api/v1/home-feed/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # USER 1: creates 2 drafts for the same question, but for
        # different people
        self.client.force_authenticate(user=self.user1)
        data = {
            "chat_thread": str(self.chat_thread_1.id),
            "question": str(self.question1.id),
            "content": "New draft content",
        }
        response = self.client.post("/api/v1/draft-question-threads/", data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        data = {
            "chat_thread": str(self.chat_thread_2.id),
            "question": str(self.question1.id),
            "content": "New draft content",
        }
        response = self.client.post("/api/v1/draft-question-threads/", data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # USER 1: verify the stats for specific chat thread
        response = self.client.get(
            reverse("chat-thread-stats", args=[str(self.chat_thread_1.id)])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.assertEqual(
            response.data,
            {
                "drafts_count": 2,
                "waiting_on_others_question_count": 0,
                "waiting_on_you_question_count": 0,
            },
        )

        # USER 1: verify the stats for all chat threads
        response = self.client.get(reverse("all-chat-threads-stats"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data,
            {
                "drafts_count": 2,
                "waiting_on_others_question_count": 0,
                "waiting_on_you_question_count": 0,
                "favorited_questions_count": 0,
            },
        )

        # USER 1: publishes 2 drafts


# New test
# User A publishes their answer for question Q
# User A publishes their answer for question Q, should error out. A user can only publish once.
