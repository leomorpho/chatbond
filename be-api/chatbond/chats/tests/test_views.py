import uuid
from unittest.mock import patch

from django.urls import reverse
from django.utils.timezone import now
from parameterized import parameterized
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from chatbond.chats.models import (
    ChatThread,
    DraftQuestionThread,
    Interlocutor,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)
from chatbond.questions.models import FavouritedQuestion, Question
from chatbond.realtime.service import realtimeUpdateService
from chatbond.users.models import User

# TODO: for all objects, add tests to verify that when DELETING,
#   only the wanted hierarchy is deleted...


class CurrentInterlocutorViewTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )

        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.client = APIClient()

    @parameterized.expand(
        [
            ("user1@example.com", status.HTTP_200_OK),
            ("user2@example.com", status.HTTP_200_OK),
            (None, status.HTTP_401_UNAUTHORIZED),
        ]
    )
    def test_get_current_interlocutor(self, test_user, expected_status):
        if test_user == "user1@example.com":
            self.client.force_authenticate(user=self.user1)
        elif test_user == "user2@example.com":
            self.client.force_authenticate(user=self.user2)

        url = reverse("current-interlocutor")
        response = self.client.get(url)

        self.assertEqual(response.status_code, expected_status)
        if expected_status == status.HTTP_200_OK:
            expected_interlocutor = Interlocutor.objects.get(user__email=test_user)
            self.assertEqual(response.data["id"], str(expected_interlocutor.id))


class ChatThreadViewSetTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)
        self.chat_thread_1 = ChatThread.objects.create()
        self.chat_thread_1.interlocutors.add(self.interlocutor1)

        self.chat_thread_2 = ChatThread.objects.create()
        self.chat_thread_2.interlocutors.add(self.interlocutor2)

        self.question1 = Question.objects.create(content="Test question 1")

        self.question_thread_1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread_1, question=self.question1
        )
        self.question_thread_2 = QuestionThread.objects.create(
            chat_thread=self.chat_thread_2, question=self.question1
        )

        # Create question chats
        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_1,
            content="Chat content 1",
        )  # type: ignore
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread_1,
            content="Chat content 2",
        )  # type: ignore

    @parameterized.expand(
        [
            ("authenticated", "user1@gmail.com", status.HTTP_200_OK),
            ("unauthenticated", None, status.HTTP_401_UNAUTHORIZED),
        ]
    )
    def test_list_interlocutor_chat_threads(self, name, email, expected_status_code):
        client = APIClient()

        if email:
            user = User.objects.get(email=email)
            client.force_authenticate(user=user)

        url = "/api/v1/chat-threads/without-question-threads/"
        response = client.get(url)

        self.assertEqual(response.status_code, expected_status_code)

        if expected_status_code == status.HTTP_200_OK:
            self.assertEqual(len(response.data), 1)
            self.assertEqual(response.data[0]["id"], str(self.chat_thread_1.id))
            self.assertEqual(response.data[0]["num_new_unseen_messages"], 1)

    @parameterized.expand(
        [
            ("delete", "delete", None),
            ("create", "post", {"interlocutors": [1, 2]}),
            ("put", "put", None),
            ("update", "patch", None),
        ]
    )
    def test_methods_not_allowed_for_chat_threads(self, name, method, data):
        client = APIClient()
        client.force_authenticate(user=self.user1)
        url = f"/chat-threads/{self.chat_thread_1.id}/"
        response = getattr(client, method)(url, data=data)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class QuestionThreadDetailViewTestCase(APITestCase):
    def setUp(self):
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
        self.interlocutor3 = Interlocutor.objects.get(user=self.user3)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread
        )

        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread,
            status="published",
            content="Content 1",
        )

        self.client = APIClient()

    @parameterized.expand(
        [
            ("user1@example.com", status.HTTP_200_OK),
            ("user3@example.com", status.HTTP_403_FORBIDDEN),
            (None, status.HTTP_401_UNAUTHORIZED),
        ]
    )
    def test_get_question_thread(self, test_user, expected_status):
        if test_user == "user1@example.com":
            self.client.force_authenticate(user=self.user1)
        elif test_user == "user3@example.com":
            self.client.force_authenticate(user=self.user3)

        url = reverse("questionthread-detail", args=[str(self.question_thread.id)])

        response = self.client.get(url)

        self.assertEqual(response.status_code, expected_status)
        if expected_status == status.HTTP_200_OK:
            self.assertEqual(response.data["id"], str(self.question_thread.id))
            self.assertEqual(response.data["num_new_unseen_messages"], 1)


class TestQuestionThreadListView(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor1 = self.user1.interlocutor
        self.interlocutor2 = self.user2.interlocutor

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1)
        self.chat_thread.interlocutors.add(self.interlocutor2)

        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")

        self.question_thread_1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question1,
            all_interlocutors_answered=True,
        )

        self.question_thread_2 = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question2,
        )
        self.question_chat_2 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_2,
            content="Draft content",
        )
        self.client.force_authenticate(user=self.user1)
        self.list_url = reverse(
            "chat-thread-question-threads",
            kwargs={"chat_thread_id": str(self.chat_thread.id)},
        )

    def test_list_question_threads(self):
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            len(response.data["results"]), 1
        )  # Because pagination is enabled
        self.assertEqual(
            response.data["results"][0]["question"]["content"], self.question1.content
        )

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_request_nonexistent_chat_thread(self):
        non_existent_chat_thread_url = reverse(
            "chat-thread-question-threads",
            kwargs={"chat_thread_id": "d8c8b837-6873-4474-8d08-8af6771c178e"},
        )
        response = self.client.get(non_existent_chat_thread_url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class DraftQuestionThreadViewSetTestCase(APITestCase):
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
        self.question2 = Question.objects.create(content="Test question 2")

        self.draft_question_thread_1 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question2,
            drafter=self.interlocutor1,
            content="Draft content 1",
        )

    @parameterized.expand(
        [
            ("unauthenticated", None, status.HTTP_401_UNAUTHORIZED),
            ("authenticated", "user1@example.com", status.HTTP_201_CREATED),
        ]
    )
    def test_create_draft(self, _, email, expected_status):
        client = APIClient()

        if email:
            user = User.objects.get(email=email)
            client.force_authenticate(user=user)

        data = {
            "chat_thread": str(self.chat_thread_1.id),
            "question": str(self.question1.id),
            "content": "New draft content",
        }

        response = client.post("/api/v1/draft-question-threads/", data)

        self.assertEqual(response.status_code, expected_status)
        if response.status_code == status.HTTP_201_CREATED:
            response_data = response.json()

            self.assertEqual(response_data["chat_thread"], data["chat_thread"])
            self.assertEqual(response_data["question"], data["question"])
            self.assertEqual(response_data["content"], data["content"])

            created_draft = DraftQuestionThread.objects.get(id=response_data["id"])
            self.assertEqual(created_draft.drafter, self.interlocutor1)
            self.assertEqual(
                str(created_draft.chat_thread.id), response_data["chat_thread"]
            )
            self.assertEqual(str(created_draft.question.id), response_data["question"])
            self.assertEqual(created_draft.content, response_data["content"])

    @parameterized.expand(
        [
            (
                "unauthenticated",
                None,
                None,
                status.HTTP_401_UNAUTHORIZED,
            ),
            (
                "authenticated_not_owner",
                "user2@example.com",
                "user1@example.com",
                status.HTTP_404_NOT_FOUND,
            ),
            (
                "authenticated_owner",
                "user1@example.com",
                "user1@example.com",
                status.HTTP_200_OK,
            ),
        ]
    )
    def test_update_draft(
        self, test_case, request_email, draft_owner_email, expected_status
    ):
        client = APIClient()

        if request_email:
            user = User.objects.get(email=request_email)
            client.force_authenticate(user=user)

        if draft_owner_email:
            draft_owner = User.objects.get(email=draft_owner_email)
            draft_interlocutor = Interlocutor.objects.get(user=draft_owner)
            draft = DraftQuestionThread.objects.create(
                chat_thread=self.chat_thread_1,
                question=self.question1,
                drafter=draft_interlocutor,
                content="Draft content for update test",
            )
        else:
            draft = None

        data = {
            "content": "Updated draft content",
            "chat_thread": self.chat_thread_1.id,
        }

        if draft:
            url = f"/api/v1/draft-question-threads/{draft.id}/"
            response = client.put(url, data)
        else:
            response = client.put(
                f"/api/v1/draft-question-threads/{self.draft_question_thread_1.id}/",
                data,
            )

        self.assertEqual(response.status_code, expected_status)
        if response.status_code == status.HTTP_201_CREATED:
            response_data = response.json()
            self.assertEqual(response_data["chat_thread"], data["chat_thread"])
            self.assertEqual(response_data["question"], data["question"])
            self.assertEqual(response_data["content"], data["content"])

            created_draft = DraftQuestionThread.objects.get(id=response_data["id"])
            self.assertEqual(created_draft.drafter, self.interlocutor1)
            self.assertEqual(created_draft.chat_thread.id, response_data["chat_thread"])
            self.assertEqual(created_draft.question.id, response_data["question"])
            self.assertEqual(created_draft.content, response_data["content"])

    @parameterized.expand(
        [
            ("unauthenticated", None, None, status.HTTP_401_UNAUTHORIZED),
            (
                "authenticated_not_owner",
                "user2@example.com",
                "user1@example.com",
                status.HTTP_404_NOT_FOUND,
            ),
            (
                "authenticated_owner",
                "user1@example.com",
                "user1@example.com",
                status.HTTP_204_NO_CONTENT,
            ),
        ]
    )
    def test_delete_draft(self, _, request_email, draft_owner_email, expected_status):
        client = APIClient()

        if request_email:
            user = User.objects.get(email=request_email)
            client.force_authenticate(user=user)

        if draft_owner_email:
            draft_owner = User.objects.get(email=draft_owner_email)
            draft_interlocutor = Interlocutor.objects.get(user=draft_owner)
            draft = DraftQuestionThread.objects.create(
                chat_thread=self.chat_thread_1,
                question=self.question1,
                drafter=draft_interlocutor,
                content="Draft content for delete test",
            )
        else:
            draft = None

        if draft:
            url = f"/api/v1/draft-question-threads/{draft.id}/"
            response = client.delete(url)
        else:
            response = client.delete("/api/v1/draft-question-threads/0/")

        self.assertEqual(response.status_code, expected_status)
        if response.status_code == status.HTTP_204_NO_CONTENT:
            with self.assertRaises(DraftQuestionThread.DoesNotExist):
                DraftQuestionThread.objects.get(id=draft.id)

            # Verify associated objects were not deleted
            ChatThread.objects.get(id=self.chat_thread_1.id)
            Question.objects.get(id=self.question1.id)
            Interlocutor.objects.get(id=draft_interlocutor.id)


class PublishDraftQuestionThreadViewTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread_1 = ChatThread.objects.create()
        self.chat_thread_1.interlocutors.add(self.interlocutor1)
        self.chat_thread_1.interlocutors.add(self.interlocutor2)

        self.question1 = Question.objects.create(content="Test question")
        self.question2 = Question.objects.create(content="Test question 2")

        self.draft1_content = "Draft content"
        self.draft1 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question1,
            drafter=self.interlocutor1,
            content=self.draft1_content,
        )

        self.draft2 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question2,
            drafter=self.interlocutor1,
            content="",
        )
        self.draft3_content = "Draft content 2"
        self.draft3 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread_1,
            question=self.question1,
            drafter=self.interlocutor2,
            content=self.draft3_content,
        )

    @parameterized.expand(
        [
            ("unauthenticated", None, uuid.uuid4(), status.HTTP_401_UNAUTHORIZED),
            (
                "non_existent_draft",
                "user1@gmail.com",
                uuid.uuid4(),
                status.HTTP_404_NOT_FOUND,
            ),
            ("not_owner", "user2@gmail.com", None, status.HTTP_403_FORBIDDEN),
            (
                "owner_empty_content",
                "user1@gmail.com",
                None,
                status.HTTP_400_BAD_REQUEST,
            ),
            ("owner_valid_content", "user1@gmail.com", None, status.HTTP_201_CREATED),
        ]
    )
    @patch("chatbond.realtime.service.client.publish")
    def test_publish_draft(
        self, case_name, request_email, draft_id, expected_status, mock_publish
    ):
        client = APIClient()

        if request_email:
            user = User.objects.get(email=request_email)
            client.force_authenticate(user=user)

        if draft_id is None:
            if expected_status == status.HTTP_403_FORBIDDEN:
                draft_id = self.draft1.id
            elif expected_status == status.HTTP_400_BAD_REQUEST:
                draft_id = self.draft2.id
            elif expected_status == status.HTTP_201_CREATED:
                draft_id = self.draft1.id

        url = f"/api/v1/draft-question-threads/{draft_id}/publish/"
        response = client.post(url)

        self.assertEqual(response.status_code, expected_status)

        if expected_status == status.HTTP_201_CREATED:
            self.assertIsNotNone(
                DraftQuestionThread.objects.get(id=draft_id).published_at
            )
            self.assertIsNotNone(
                DraftQuestionThread.objects.get(id=draft_id).question_thread
            )

            question_thread = QuestionThread.objects.get(
                chat_thread=self.chat_thread_1,
                question=self.question1,
            )
            self.assertIsNotNone(question_thread)
            self.assertEqual(question_thread.chat_thread, self.chat_thread_1)
            self.assertEqual(question_thread.question, self.question1)
            self.assertIsNotNone(question_thread.chats)
            self.assertEqual(1, len(list(question_thread.chats.all())))
            chat = question_thread.chats.first()
            self.assertEqual(self.draft1_content, chat.content)
            self.assertEqual(self.interlocutor1, chat.author)
            mock_publish.assert_called()

    @patch("chatbond.realtime.service.client.publish")
    def test_all_interlocutors_answer(self, mock_publish):
        client = APIClient()
        self.upsert_draft_url = lambda question_id, interlocutor_id: reverse(
            "upsert-draft-question-thread", args=[question_id, interlocutor_id]
        )

        # First interlocutor publishes draft
        client.force_authenticate(user=self.user1)
        url = f"/api/v1/draft-question-threads/{self.draft1.id}/publish/"
        response = client.post(url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.draft1.refresh_from_db()
        self.assertIsNotNone(self.draft1.published_at)
        self.assertIsNotNone(self.draft1.question_thread)

        # Try to publish the same draft again
        response = client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Try to create a new draft for the same chat thread and question
        # published for above
        response = client.post(
            self.upsert_draft_url(self.question1.id, self.interlocutor2.id),
            {"content": "Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        question_thread = self.draft1.question_thread
        self.assertIsNotNone(question_thread)
        self.assertEqual(question_thread.chat_thread, self.chat_thread_1)
        self.assertEqual(question_thread.question, self.question1)
        self.assertEqual(1, question_thread.chats.count())
        self.assertFalse(question_thread.all_interlocutors_answered)

        # Second interlocutor publishes draft
        client.force_authenticate(user=self.user2)
        url = f"/api/v1/draft-question-threads/{self.draft3.id}/publish/"
        response = client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.draft3.refresh_from_db()
        self.assertIsNotNone(self.draft3.published_at)
        self.assertIsNotNone(self.draft3.question_thread)

        question_thread.refresh_from_db()
        self.assertEqual(question_thread, self.draft3.question_thread)
        self.assertEqual(2, question_thread.chats.count())
        self.assertTrue(question_thread.all_interlocutors_answered)

        mock_publish.assert_called()


class QuestionChatEditSetTestCase(APITestCase):
    def setUp(self):
        # Create users
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.user3 = User.objects.create_user(
            email="user3@gmail.com", password="password123"
        )

        # Create interlocutors
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)
        self.interlocutor3 = Interlocutor.objects.get(user=self.user3)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1)
        self.chat_thread.interlocutors.add(self.interlocutor3)
        # Create question threads
        self.question_thread_1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread
        )

        # Create question chats
        self.question_chat_draft = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_1,
            status="draft",
            content="Draft content",
        )
        self.question_chat_published = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_1,
            status="published",
            content="Published content",
        )

    @parameterized.expand(
        [
            (
                "unauthenticated",
                None,
                "draft",
                status.HTTP_401_UNAUTHORIZED,
            ),
            (
                "authenticated",
                "user1@gmail.com",
                "draft",
                status.HTTP_201_CREATED,
            ),
            (
                "authenticated_wrong_user",
                "user2@gmail.com",
                "draft",
                status.HTTP_403_FORBIDDEN,
            ),
            (
                "unauthenticated_pending",
                None,
                "pending",
                status.HTTP_401_UNAUTHORIZED,
            ),
            (
                "authenticated_pending",
                "user1@gmail.com",
                "pending",
                status.HTTP_201_CREATED,
            ),
            (
                "authenticated_wrong_user_pending",
                "user2@gmail.com",
                "pending",
                status.HTTP_403_FORBIDDEN,
            ),
        ]
    )
    @patch.object(realtimeUpdateService, "publish_to_personal_channels")
    def test_create_question_chat(
        self, _, email, status_value, expected_status, mock_publish_to_personal_channels
    ):
        client = APIClient()

        if email:
            user = User.objects.get(email=email)
            client.force_authenticate(user=user)

        data = {
            "question_thread": str(self.question_thread_1.id),
            "status": status_value,
            "content": "New content",
        }

        response = client.post("/api/v1/question-chats/", data)

        self.assertEqual(response.status_code, expected_status)

        if expected_status == status.HTTP_201_CREATED:
            if status_value == "pending":
                status_value = "published"
            self.assertTrue(
                QuestionChat.objects.filter(
                    author=self.interlocutor1,
                    question_thread=self.question_thread_1,
                    status=status_value,
                    content="New content",
                ).exists()
            )
            mock_publish_to_personal_channels.assert_called_once()

    @parameterized.expand(
        [
            (
                "unauthenticated",
                None,
                None,
                status.HTTP_401_UNAUTHORIZED,
            ),
            (
                "authenticated_draft",
                "user1@gmail.com",
                "draft",
                status.HTTP_200_OK,
            ),
            (
                "authenticated_published",
                "user1@gmail.com",
                "published",
                status.HTTP_403_FORBIDDEN,
            ),
            (
                "authenticated_draft_wrong_user",
                "user2@gmail.com",
                "draft",
                status.HTTP_403_FORBIDDEN,
            ),
            (
                "authenticated_published_wrong_user",
                "user2@gmail.com",
                "published",
                status.HTTP_403_FORBIDDEN,
            ),
        ]
    )
    def test_update_question_chat(self, _, request_email, chat_status, expected_status):
        client = APIClient()

        if request_email:
            user = User.objects.get(email=request_email)
            client.force_authenticate(user=user)

        question_chat = (
            self.question_chat_draft
            if chat_status == "draft"
            else self.question_chat_published
        )

        data = {
            "content": "Updated content",
        }

        response = client.patch(f"/api/v1/question-chats/{question_chat.id}/", data)

        self.assertEqual(response.status_code, expected_status)

    @parameterized.expand(
        [
            (
                "unauthenticated",
                None,
                None,
                status.HTTP_401_UNAUTHORIZED,
            ),
            (
                "authenticated_draft",
                "user1@gmail.com",
                "draft",
                status.HTTP_204_NO_CONTENT,
            ),
            (
                "authenticated_published",
                "user1@gmail.com",
                "published",
                status.HTTP_403_FORBIDDEN,
            ),
            (
                "authenticated_draft_wrong_user",
                "user2@gmail.com",
                "draft",
                status.HTTP_403_FORBIDDEN,
            ),
            (
                "authenticated_published_wrong_user",
                "user2@gmail.com",
                "published",
                status.HTTP_403_FORBIDDEN,
            ),
        ]
    )
    def test_delete_question_chat(self, _, email, chat_status, expected_status):
        client = APIClient()

        if email:
            user = User.objects.get(email=email)
            client.force_authenticate(user=user)

        question_chat = (
            self.question_chat_draft
            if chat_status == "draft"
            else self.question_chat_published
        )

        response = client.delete(f"/api/v1/question-chats/{question_chat.id}/")

        self.assertEqual(response.status_code, expected_status)

        if expected_status == status.HTTP_204_NO_CONTENT:
            question_chat.refresh_from_db()
            self.assertEqual(question_chat.status, "deleted")
            self.assertEqual(question_chat.content, "")


class QuestionChatsByQuestionThreadViewTestCase(APITestCase):
    def setUp(self):
        # Create users
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password"
        )
        self.user3 = User.objects.create_user(
            email="user3@gmail.com", password="password"
        )
        self.user4 = User.objects.create_user(
            email="user4@gmail.com", password="password"
        )

        # Create interlocutors
        self.interlocutor1 = self.user1.interlocutor
        self.interlocutor2 = self.user2.interlocutor
        self.interlocutor3 = self.user3.interlocutor
        self.interlocutor4 = self.user4.interlocutor

        # Create chat threads
        self.chat_thread1 = ChatThread.objects.create()
        self.chat_thread1.interlocutors.add(
            self.interlocutor1, self.interlocutor2, self.interlocutor4
        )

        self.chat_thread2 = ChatThread.objects.create()
        self.chat_thread2.interlocutors.add(self.interlocutor2, self.interlocutor3)

        # Create question threads
        self.question_thread1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread1
        )
        self.question_thread2 = QuestionThread.objects.create(
            chat_thread=self.chat_thread2
        )

        # Create question chats
        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread1,
            content="Chat content 1",
        )  # type: ignore
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread1,
            content="Chat content 2",
        )  # type: ignore

        # Create question chat interaction events
        self.interaction_event1 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat1,
            interlocutor=self.interlocutor1,
            received_at=now(),
            seen_at=now(),
        )
        self.interaction_event2 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.question_chat2,
            interlocutor=self.interlocutor2,
            received_at=now(),
            seen_at=now(),
        )

    @parameterized.expand(
        [
            ("unauthenticated", None, 0, status.HTTP_401_UNAUTHORIZED),
            (
                "User belongs to question thread 1",
                "user1@gmail.com",
                1,
                status.HTTP_200_OK,
            ),
            (
                "User belongs to question thread 2",
                "user2@gmail.com",
                1,
                status.HTTP_200_OK,
            ),
            (
                "User does not belong to question thread",
                "user3@gmail.com",
                0,
                status.HTTP_403_FORBIDDEN,
            ),
        ]
    )
    def test_access_question_chats(
        self, case_name, email, num_accessible_chats, expected_status
    ):
        # If not all users have answered a question, they can only see their chat,
        # which is why we have num_accessible_chats
        client = APIClient()

        if email:
            user = User.objects.get(email=email)
            client.force_authenticate(user=user)

        response = client.get(
            f"/api/v1/question-threads/{self.question_thread1.id}/chats/"
        )

        self.assertEqual(response.status_code, expected_status)
        if response.status_code == status.HTTP_200_OK:
            data = response.json()
            self.assertEqual(len(data), num_accessible_chats)
            if email == "user1@gmail.com":
                self.assertEqual(
                    {chat["id"] for chat in data},
                    {str(self.question_chat1.id)},
                )
            elif email == "user2@gmail.com":
                self.assertEqual(
                    {chat["id"] for chat in data},
                    {str(self.question_chat2.id)},
                )
            # Check interaction_events field
            for chat in data:
                if chat["id"] == self.question_chat1.id:
                    interaction_event = chat["interaction_events"][0]
                    self.assertEqual(
                        interaction_event["interlocutor"], str(self.interlocutor1.id)
                    )
                    self.assertIsNotNone(interaction_event["received_at"])
                    self.assertIsNotNone(interaction_event["seen_at"])
                elif chat["id"] == self.question_chat2.id:
                    interaction_event = chat["interaction_events"][0]
                    self.assertEqual(
                        interaction_event["interlocutor"], str(self.interlocutor2.id)
                    )
                    self.assertIsNotNone(interaction_event["received_at"])
                    self.assertIsNotNone(interaction_event["seen_at"])

    @patch("chatbond.realtime.service.client.publish")
    def test_question_chats_visibility(self, mock_publish):
        client = APIClient()

        # Interlocutor 1 posts a question chat
        self.assertEqual(
            1,
            QuestionChat.objects.filter(
                author=self.interlocutor1,
                question_thread=self.question_thread1,
            ).count(),
        )

        self.assertEqual(
            1,
            QuestionChat.objects.filter(
                author=self.interlocutor2,
                question_thread=self.question_thread1,
            ).count(),
        )
        self.assertEqual(
            0,
            QuestionChat.objects.filter(
                author=self.interlocutor3,
                question_thread=self.question_thread1,
            ).count(),
        )

        # Authenticate as user1 and fetch question chats
        client.force_authenticate(user=self.user1)
        response = client.get(
            f"/api/v1/question-threads/{self.question_thread1.id}/chats/"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)

        # Authenticate as user2 and fetch question chats
        client.force_authenticate(user=self.user2)
        response = client.get(
            f"/api/v1/question-threads/{self.question_thread1.id}/chats/"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)

        # Interlocutor 3 posts a question chat
        self.draft3_content = "Draft content 2"
        draft_id = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread1,
            question=self.question_thread1.question,
            drafter=self.interlocutor4,
            content="Using publish to correctly toggle a value",
        ).id

        url = f"/api/v1/draft-question-threads/{draft_id}/publish/"
        client.force_authenticate(user=self.user4)
        response = client.post(url)

        # Authenticate as user2 again and fetch question chats
        response = client.get(
            f"/api/v1/question-threads/{self.question_thread1.id}/chats/"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            len(response.json()), 3
        )  # Should be 3 as all interlocutors have now posted a chat

        mock_publish.assert_called()


class SetSeenAtForQuestionChatsTestCase(APITestCase):
    def setUp(self):
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

        self.question_chat1 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread,
            status="published",
            content="Content 1",
        )
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread,
            status="published",
            content="Content 2",
        )

        self.client = APIClient()

    @parameterized.expand(
        [
            ("user1@example.com", status.HTTP_200_OK),
            ("user3@example.com", status.HTTP_403_FORBIDDEN),
            (None, status.HTTP_401_UNAUTHORIZED),
        ]
    )
    def test_set_seen_at_for_question_chats(self, test_user, expected_status):
        if test_user == "user1@example.com":
            self.client.force_authenticate(user=self.user1)
        elif test_user == "user3@example.com":
            self.client.force_authenticate(user=self.user3)

        url = reverse("set-seen-at-for-question-chats", args=[self.question_thread.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, expected_status)
        if expected_status == status.HTTP_200_OK:
            self.assertEqual(2, QuestionChatInteractionEvent.objects.count())

            question_chat_interaction_event1 = QuestionChatInteractionEvent.objects.get(
                question_chat=self.question_chat1,
                interlocutor=self.user1.interlocutor,
            )
            self.assertIsNotNone(question_chat_interaction_event1.seen_at)

            question_chat_interaction_event2 = QuestionChatInteractionEvent.objects.get(
                question_chat=self.question_chat2,
                interlocutor=self.user1.interlocutor,
            )
            self.assertIsNotNone(question_chat_interaction_event2.seen_at)


class TestConnectedtInterlocutorViewSet(APITestCase):
    def setUp(self):
        self.client = APIClient()

        # create 3 users and interlocutors
        self.users = [
            User.objects.create_user(
                email=f"user{i}@example.com", password="password123"
            )
            for i in range(1, 4)
        ]
        self.interlocutors = [user.interlocutor for user in self.users]

        # create a chat thread shared by user1 and user2
        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(*self.interlocutors[:2])

        self.url = reverse("chat-interlocutors-list")

    def test_get_interlocutors(self):
        self.client.force_authenticate(user=self.users[0])
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # assert that the response includes interlocutor2 but not interlocutor3
        self.assertContains(response, self.interlocutors[1].user.email)
        self.assertNotContains(response, self.interlocutors[2].user.email)

    def test_unauthenticated_request(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_interlocutor_onboarding(self):
        onboarding_user = User.objects.create_user(
            email="H@example.com", password="password123"
        )
        self.client.force_authenticate(user=onboarding_user)
        response = self.client.get(self.url, {"include_self": "true"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertContains(response, onboarding_user.email)


class TestDraftQuestionThreadByQuestionView(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.other_user = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.user_3 = User.objects.create_user(
            email="user3@example.com", password="password123"
        )

        self.client.force_authenticate(user=self.user)
        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.user.interlocutor)
        self.chat_thread.interlocutors.add(self.user_3.interlocutor)

        self.draft1 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question1,
            drafter=self.user.interlocutor,
            content="Draft Content 1",
        )

        self.draft2 = DraftQuestionThread.objects.create(
            chat_thread=ChatThread.objects.create(),
            question=self.question1,
            drafter=self.other_user.interlocutor,
            content="Draft Content 2",
        )

        self.drafts_url = lambda question_id: reverse(
            "draft-question-thread-by-question", args=[question_id]
        )

    def test_get_drafts_for_question(self):
        response = self.client.get(self.drafts_url(str(self.question1.id)))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["id"], str(self.draft1.id))
        self.assertEqual(
            response.json()[0]["interlocutor"]["id"],
            str(self.user_3.interlocutor.id),
        )

    def test_get_drafts_for_non_existent_question(self):
        non_existent_uuid = uuid.uuid4()
        response = self.client.get(self.drafts_url(non_existent_uuid))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.get(self.drafts_url(str(self.question1.id)))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestUpsertDraftQuestionThreadView(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.target_user = User.objects.create_user(
            email="target@example.com", password="password123"
        )
        self.client.force_authenticate(user=self.user)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(
            self.user.interlocutor, self.target_user.interlocutor
        )

        self.question = Question.objects.create(content="Test Question 1")

        self.upsert_draft_url = lambda question_id, interlocutor_id: reverse(
            "upsert-draft-question-thread", args=[question_id, interlocutor_id]
        )

    def test_create_draft(self):
        response = self.client.post(
            self.upsert_draft_url(self.question.id, self.target_user.interlocutor.id),
            {"content": "Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        draft = DraftQuestionThread.objects.get(id=response.data["id"])
        self.assertEqual(draft.content, "Draft Content")

    def test_update_draft(self):
        draft = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question,
            drafter=self.user.interlocutor,
            content="Initial Draft Content",
        )

        response = self.client.post(
            self.upsert_draft_url(self.question.id, self.target_user.interlocutor.id),
            {"content": "Updated Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        draft.refresh_from_db()
        self.assertEqual(draft.content, "Updated Draft Content")

    def test_upsert_draft_for_non_existent_question_or_interlocutor(self):
        non_existent_uuid = uuid.uuid4()
        response = self.client.post(
            self.upsert_draft_url(non_existent_uuid, self.target_user.interlocutor.id),
            {"content": "Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        response = self.client.post(
            self.upsert_draft_url(self.question.id, non_existent_uuid),
            {"content": "Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.post(
            self.upsert_draft_url(self.question.id, self.target_user.interlocutor.id),
            {"content": "Draft Content"},
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestQuestionThreadsWaitingOnOthersListView(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor1 = self.user1.interlocutor
        self.interlocutor2 = self.user2.interlocutor

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1)
        self.chat_thread.interlocutors.add(self.interlocutor2)

        self.chat_thread2 = ChatThread.objects.create()
        self.chat_thread2.interlocutors.add(self.interlocutor1)

        self.question = Question.objects.create(content="Test Question")

        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question,
            all_interlocutors_answered=False,
        )
        self.question_chat = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread,
            content="Chat content",
        )

        self.question_thread2 = QuestionThread.objects.create(
            chat_thread=self.chat_thread2,
            question=self.question,
            all_interlocutors_answered=False,
        )
        self.question_chat2 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread2,
            content="Chat content",
        )
        self.url = reverse("waiting-on-others-question-threads")
        self.client = APIClient()

    def test_unauthenticated_request(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_no_question_threads(self):
        self.client.force_authenticate(user=self.user2)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 0)

    def test_all_question_threads(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_chat_thread_id_filter(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.get(
            f"{self.url}?chat_thread_id=" + str(self.chat_thread.id)
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)


class TestQuestionThreadsWaitingOnCurrentUserListView(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.user3 = User.objects.create_user(
            email="user3@example.com", password="password123"
        )

        self.interlocutor1 = self.user1.interlocutor
        self.interlocutor2 = self.user2.interlocutor
        self.interlocutor3 = self.user3.interlocutor

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(
            self.interlocutor1, self.interlocutor2, self.interlocutor3
        )

        self.question_thread_answered_by_interlocutor1 = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=Question.objects.create(content="Test Question 1"),
        )
        self.question_thread_answered_by_interlocutor2 = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=Question.objects.create(content="Test Question 2"),
        )

        QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread_answered_by_interlocutor1,
            content="Test Content 1",
        )

        QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread_answered_by_interlocutor2,
            content="Test Content 2",
        )

        self.url = reverse("waiting-on-you-question-threads")
        self.client.force_authenticate(user=self.user3)

    def test_unanswered_question_threads(self):
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Check that only question_thread_answered_by_interlocutor1 and
        # question_thread_answered_by_interlocutor2 are returned, and not the other way around
        returned_question_thread_ids = [
            thread["id"] for thread in response.json()["results"]
        ]
        self.assertIn(
            str(self.question_thread_answered_by_interlocutor1.id),
            returned_question_thread_ids,
        )
        self.assertIn(
            str(self.question_thread_answered_by_interlocutor2.id),
            returned_question_thread_ids,
        )

    def test_unanswered_question_threads_with_chat_thread_id(self):
        response = self.client.get(
            self.url, {"chat_thread_id": str(self.chat_thread.id)}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Check that only question_thread_answered_by_interlocutor1 and
        # question_thread_answered_by_interlocutor2 are returned, and not the other way around
        returned_question_thread_ids = [
            thread["id"] for thread in response.json()["results"]
        ]
        self.assertIn(
            str(self.question_thread_answered_by_interlocutor1.id),
            returned_question_thread_ids,
        )
        self.assertIn(
            str(self.question_thread_answered_by_interlocutor2.id),
            returned_question_thread_ids,
        )

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestUserDraftQuestionListView(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )

        self.interlocutor1 = self.user1.interlocutor
        self.interlocutor2 = self.user2.interlocutor

        self.chat_thread1 = ChatThread.objects.create()
        self.chat_thread1.interlocutors.add(self.interlocutor1)

        self.chat_thread2 = ChatThread.objects.create()
        self.chat_thread2.interlocutors.add(self.interlocutor1, self.interlocutor2)

        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")

        self.draft1 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread1,
            question=self.question1,
            drafter=self.interlocutor1,
            content="Draft content 1",
        )

        self.draft2 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread2,
            question=self.question2,
            drafter=self.interlocutor1,
            content="Draft content 2",
        )

        DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread2,
            question=self.question2,
            drafter=self.interlocutor2,
            content="Draft content 3",
        )

        self.url = reverse("draft-question-threads-for-user")
        self.client.force_authenticate(user=self.user1)

    def test_get_all_drafts(self):
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        returned_question_ids = [draft["id"] for draft in response.json()["results"]]
        self.assertIn(str(self.draft1.question.id), returned_question_ids)
        self.assertIn(str(self.draft2.question.id), returned_question_ids)

    def test_get_drafts_for_specific_chat_thread(self):
        response = self.client.get(
            self.url, {"chat_thread_id": str(self.chat_thread1.id)}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        returned_question_ids = [draft["id"] for draft in response.json()["results"]]
        self.assertIn(str(self.draft1.question.id), returned_question_ids)
        self.assertNotIn(str(self.draft2.question.id), returned_question_ids)

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestChatThreadStatsView(APITestCase):
    def setUp(self):
        self.client = APIClient()

        # Create users and interlocutors
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor = self.user.interlocutor
        self.other_user = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.other_interlocutor = self.other_user.interlocutor

        # Authenticate the client with the user
        self.client.force_authenticate(user=self.user)

        # Create ChatThread, DraftQuestionThread, and QuestionThread instances
        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor)
        self.question = Question.objects.create(content="Test Question")
        self.question_2 = Question.objects.create(content="Test Question 2")
        self.draft_question_thread = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question,
            drafter=self.interlocutor,
            content="Draft Content",
        )
        # Add a question thread for "waiting for current user"
        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question,
            all_interlocutors_answered=False,
        )

        # Add a chat authored by the other interlocutor
        self.question_thread.chats.create(
            author=self.other_interlocutor, content="Test Chat"
        )

        # Add a question threads for "waiting for other user"
        self.question_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question_2,
            all_interlocutors_answered=False,
        )

        # Add a chat authored by the other interlocutor
        self.question_thread.chats.create(author=self.interlocutor, content="Test Chat")

        self.favorited_question = FavouritedQuestion.objects.create(
            interlocutor=self.interlocutor, question=self.question
        )

        # Set up the URL for the view
        self.url_with_id = reverse("chat-thread-stats", args=[str(self.chat_thread.id)])
        self.url_without_id = reverse("all-chat-threads-stats")

    def test_get_chat_thread_stats(self):
        response = self.client.get(self.url_with_id)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify the returned stats
        expected_data = {
            "drafts_count": 1,
            "waiting_on_others_question_count": 1,
            "waiting_on_you_question_count": 1,
        }
        self.assertEqual(response.data, expected_data)

    def test_get_chat_thread_stats_without_chat_thread_id(self):
        # Remove the chat_thread_id from the URL
        response = self.client.get(self.url_without_id)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify the returned stats
        expected_data = {
            "drafts_count": 1,
            "waiting_on_others_question_count": 1,
            "waiting_on_you_question_count": 1,
            "favorited_questions_count": 1,
        }
        self.assertEqual(response.data, expected_data)

    def test_unauthenticated_request(self):
        # Log out the client
        self.client.logout()
        response = self.client.get(self.url_without_id)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
