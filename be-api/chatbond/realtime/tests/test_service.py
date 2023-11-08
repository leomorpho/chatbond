import uuid
from unittest.mock import patch

from django.test import TestCase

from chatbond.chats.models import ChatThread, Interlocutor, QuestionThread
from chatbond.chats.serializers import QuestionThreadSerializer
from chatbond.questions.models import Question
from chatbond.realtime.service import RealtimeUpdateService
from chatbond.users.models import User


class RealtimeUpdateServiceTest(TestCase):
    @patch("chatbond.realtime.service.client.publish")
    def test_publish_to_personal_channels(self, mock_publish):
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
        question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question1,
        )
        question_thread_serializer = QuestionThreadSerializer(question_thread)
        payload_type = "QuestionThread"
        payload_content = question_thread_serializer.data
        user_id = uuid.uuid4()
        userIds = [user_id]

        # call the method to test
        service = RealtimeUpdateService()
        service.publish_to_personal_channels(payload_type, payload_content, userIds)

        # make assertions
        channel = f"personal:#{str(user_id)}"
        mock_publish.assert_called_once_with(
            channel,
            {
                "action": "upsert",
                "data": {"type": payload_type, "content": payload_content},
            },
        )
