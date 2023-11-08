from unittest.mock import patch
from uuid import UUID, uuid4

from django.urls import reverse
from parameterized import parameterized
from rest_framework import status
from rest_framework.exceptions import ErrorDetail
from rest_framework.test import APIClient, APITestCase

from chatbond.chats.models import Interlocutor
from chatbond.questions.models import (
    FavouritedQuestion,
    LikedStatus,
    Question,
    QuestionFeed,
    RatedQuestion,
    SeenQuestion,
)
from chatbond.users.models import User


class FavouritedQuestionViewTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )

        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.question1 = Question.objects.create(
            content="Question1",
            author=self.interlocutor1,
            # fill other required fields
        )
        self.question2 = Question.objects.create(
            content="Question2",
            author=self.interlocutor2,
            # fill other required fields
        )

        self.favourite1 = FavouritedQuestion.objects.create(
            interlocutor=self.interlocutor1,
            question=self.question1,
        )
        self.favourite1.target_interlocutors.add(self.interlocutor2)

        self.favourite2 = FavouritedQuestion.objects.create(
            interlocutor=self.interlocutor2,
            question=self.question2,
        )
        self.favourite2.target_interlocutors.add(self.interlocutor1)

        self.client = APIClient()

    # TODO: goes hand in hand with likely deprecated code. To delete once view is deleted.
    # @parameterized.expand(
    #     [
    #         ("user1@example.com", status.HTTP_200_OK, 1),
    #         ("user2@example.com", status.HTTP_200_OK, 1),
    #         (None, status.HTTP_401_UNAUTHORIZED, 0),
    #     ]
    # )
    # def test_get_favourited_questions(self, test_user, expected_status, expected_count):
    #     if test_user == "user1@example.com":
    #         self.client.force_authenticate(user=self.user1)
    #         expected_question = str(self.question1.id)
    #     elif test_user == "user2@example.com":
    #         self.client.force_authenticate(user=self.user2)
    #         expected_question = str(self.question2.id)

    #     url = "/api/v1/favorites/"
    #     response = self.client.get(url)
    #     import ipdb

    #     ipdb.set_trace()
    #     self.assertEqual(response.status_code, expected_status)
    #     if expected_status == status.HTTP_200_OK:
    #         self.assertEqual(len(response.json()["results"]), expected_count)
    #         # self.assertIn(
    #         #     response.json()["results"][0]["target_interlocutors"][0]["id"],
    #         #     expected_target_interlocutor_id,
    #         # )

    #         self.assertIn(
    #             response.json()["results"][0]["question"]["id"],
    #             expected_question,
    #         )
    #         # TODO: check that it returns the full serialized question
    #         # TODO: check that it returns the full serialized interlocutors for `target_interlocutors`
    #         # for item in response.json()["results"]:
    #         #     self.assertIn(
    #         #         item["interlocutor"],
    #         #         [str(self.interlocutor1.id), str(self.interlocutor2.id)],
    #         #     )
    #         #     self.assertIn(
    #         #         item["question"], [str(self.question1.id), str(self.question2.id)]
    #         #     )


class TestQuestionViewSet(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.client.force_authenticate(user=self.user)

        self.question_1 = Question.objects.create(
            content="Question 1", author=self.user.interlocutor
        )
        self.question_2 = Question.objects.create(
            content="Question 2", author=self.user.interlocutor
        )

    @parameterized.expand(
        [
            ("mathematics", 0, []),
            ("history", 1, ["question_1"]),
            ("physics", 2, ["question_1", "question_2"]),
        ]
    )
    @patch("chatbond.questions.views.questionRecommender")
    def test_search_questions(
        self, search_string, num_results, question_names, mock_question_recommender
    ):
        # Convert question names to actual question objects
        questions = [getattr(self, question_name) for question_name in question_names]
        # Derive the expected question IDs from the question objects
        question_ids = [question.id for question in questions]

        mock_question_recommender.embed_string.return_value = "fake_embedding"
        mock_question_recommender.nearest_neighbors.return_value = question_ids

        response = self.client.get(
            reverse("search-questions"),
            {"search": search_string, "num_results": num_results},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()["results"]), len(question_ids))

        for question_data in response.json()["results"]:
            self.assertIn(UUID(question_data["id"]), question_ids)

    def test_search_questions_unauthenticated(self):
        self.client.logout()

        response = self.client.get(
            reverse("search-questions"), {"search": "mathematics", "num_results": 10}
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestGetHomeFeed(APITestCase):
    def setUp(self):
        self.client = APIClient()

        # Setup users and interlocutors
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        # Create questions and feeds
        self.question1 = Question.objects.create(content="Question 1")
        self.question2 = Question.objects.create(content="Question 2")
        self.question3 = Question.objects.create(content="Question 3")
        self.feed1 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1,
        )
        self.feed1.questions.add(self.question1, self.question2)

        self.feed2 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor2,
        )
        self.feed2.questions.add(self.question3)

    def test_all_home_feeds_got_created(self):
        """When an interlocutor is newly registered, a new question
        gets created with the onboarding questions, which is why in this
        test we wind up with 4 question feeds total.
        """
        self.assertEqual(4, QuestionFeed.objects.count())

    def test_get_home_feed_no_consumed(self):
        self.client.force_authenticate(user=self.user1)

        with patch(
            "chatbond.questions.views.get_questions_ready_to_answer"
        ) as mock_to_answer, patch(
            "chatbond.questions.views.get_questions_with_drafts"
        ) as mock_with_drafts:
            mock_to_answer.return_value = Question.objects.filter(id=self.question1.id)
            mock_with_drafts.return_value = Question.objects.filter(
                id=self.question2.id
            )

            response = self.client.get("/api/v1/home-feed/")
            self.assertEqual(response.status_code, status.HTTP_200_OK)

            # Validate the custom wrapper
            self.assertIn("questions", response.data)
            self.assertIn("feed_created_at", response.data)
            self.assertIn("count", response.data)
            self.assertIn("next", response.data)
            self.assertIn("previous", response.data)

            # Check for questions in the response
            result_ids = [UUID(item["id"]) for item in response.data["questions"]]
            expected_ids = [self.question1.id, self.question2.id]
            self.assertCountEqual(result_ids, expected_ids)

            self.assertIsNotNone(response.data["feed_created_at"])

            # Validate that the feed was marked as consumed
            self.feed1.refresh_from_db()
            self.assertIsNotNone(self.feed1.consumedAt)

    def test_get_home_feed_unauthenticated(self):
        self.client.logout()
        response = self.client.get("/api/v1/home-feed/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestMarkQuestionAsSeen(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.client.force_authenticate(user=self.user)
        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")
        self.seen_url = reverse("mark-question-as-seen-mark-as-seen")

    def test_mark_questions_as_seen(self):
        response = self.client.post(
            self.seen_url,
            {"question_ids": [self.question1.id, self.question2.id]},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            SeenQuestion.objects.filter(
                interlocutor=self.user.interlocutor,
                question__in=[self.question1, self.question2],
            ).count(),
            2,
        )

    def test_mark_non_existent_question_as_seen(self):
        non_existent_uuid = uuid4()
        response = self.client.post(
            self.seen_url,
            {"question_ids": [str(non_existent_uuid)]},
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data,
            {"error": f"Question with id {non_existent_uuid} does not exist"},
        )

    def test_no_question_ids_provided(self):
        response = self.client.post(self.seen_url, {})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            repr(response.data["question_ids"][0]),
            repr(ErrorDetail(string="This field is required.", code="required")),
        )

    def test_unauthenticated_request(self):
        self.client.logout()

        response = self.client.post(
            self.seen_url,
            {"question_ids": [self.question1.id, self.question2.id]},
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestRateQuestionViewSet(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.client.force_authenticate(user=self.user)
        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")
        self.rate_url = reverse("rate-question-rate", kwargs={"pk": self.question1.id})

    def test_rate_question(self):
        response = self.client.post(
            self.rate_url,
            {"status": LikedStatus.LIKED},
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            RatedQuestion.objects.filter(
                interlocutor=self.user.interlocutor,
                question=self.question1,
                status=LikedStatus.LIKED,
            ).exists()
        )

    def test_rate_non_existent_question(self):
        non_existent_question_rate_url = reverse(
            "rate-question-rate", kwargs={"pk": 999}
        )
        response = self.client.post(
            non_existent_question_rate_url,
            {"status": LikedStatus.LIKED},
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_invalid_status(self):
        response = self.client.post(
            self.rate_url,
            {"status": "invalid_status"},
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data,
            {
                "error": (
                    "Invalid status. Must be either 'L' for liked,"
                    " 'N' for neutral or 'D' for disliked."
                )
            },
        )

    def test_unauthenticated_request(self):
        self.client.logout()

        response = self.client.post(
            self.rate_url,
            {"status": LikedStatus.LIKED},
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_already_rated_with_same_status(self):
        RatedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question1,
            status=LikedStatus.LIKED,
        )

        response = self.client.post(
            self.rate_url,
            {"status": LikedStatus.LIKED},
        )
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(
            response.data,
            {"error": "Invalid status transition. Check the allowed transitions."},
        )

    def test_illegal_transition(self):
        RatedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question1,
            status=LikedStatus.LIKED,
        )

        response = self.client.post(
            self.rate_url,
            {"status": LikedStatus.DISLIKED},
        )
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(
            response.data,
            {"error": "Invalid status transition. Check the allowed transitions."},
        )

    def test_legal_transition(self):
        RatedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question1,
            status=LikedStatus.LIKED,
        )

        response = self.client.post(
            self.rate_url,
            {"status": LikedStatus.NEUTRAL},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(
            RatedQuestion.objects.filter(
                interlocutor=self.user.interlocutor,
                question=self.question1,
                status=LikedStatus.NEUTRAL,
            ).exists()
        )


class TestCreateOrUpdateFavoriteQuestionView(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.client.force_authenticate(user=self.user)
        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")
        self.favorite_url = reverse("edit-favorited-question-favorite")

    def test_favorite_a_question(self):
        response = self.client.post(
            self.favorite_url,
            {"question_id": str(self.question1.id), "action": "favorite"},
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(
            FavouritedQuestion.objects.filter(
                interlocutor=self.user.interlocutor,
                question=self.question1,
            ).count(),
            1,
        )

    def test_unfavorite_a_question(self):
        FavouritedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question1,
        )
        response = self.client.post(
            self.favorite_url,
            {"question_id": str(self.question1.id), "action": "unfavorite"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(
            FavouritedQuestion.objects.filter(
                interlocutor=self.user.interlocutor,
                question=self.question1,
            ).exists()
        )

    def test_favorite_non_existent_question(self):
        non_existent_uuid = uuid4()
        response = self.client.post(
            self.favorite_url,
            {"question_id": str(non_existent_uuid), "action": "favorite"},
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data,
            {"error": f"Question with id {non_existent_uuid} does not exist"},
        )

    def test_no_question_id_or_action_provided(self):
        response = self.client.post(self.favorite_url, {})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue("question_id" in response.data)
        self.assertTrue("action" in response.data)

    def test_invalid_action_provided(self):
        response = self.client.post(
            self.favorite_url,
            {"question_id": str(self.question1.id), "action": "invalid_action"},
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        self.assertEqual(
            response.json()["action"],
            ['"invalid_action" is not a valid choice.'],
        )

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.post(
            self.favorite_url,
            {"question_id": str(self.question1.id), "action": "favorite"},
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestQuestionsFromFavoriteQuestionsListView(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.question1 = Question.objects.create(content="Test Question 1")
        self.question2 = Question.objects.create(content="Test Question 2")
        self.favourite_url = reverse("favorite-questions-for-user")
        self.favorite_question1 = FavouritedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question1,
        )
        self.favorite_question2 = FavouritedQuestion.objects.create(
            interlocutor=self.user.interlocutor,
            question=self.question2,
        )
        self.favorite_question3 = FavouritedQuestion.objects.create(
            interlocutor=self.user2.interlocutor,
            question=self.question2,
        )
        self.client.force_authenticate(user=self.user)

    def test_get_favorited_questions(self):
        response = self.client.get(self.favourite_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()["results"]), 2)
        self.assertEqual(
            {x["id"] for x in response.json()["results"]},
            {
                str(self.favorite_question1.question.id),
                str(self.favorite_question2.question.id),
            },
        )

    def test_get_favorited_questions_for_other_user(self):
        self.client.force_authenticate(user=self.user2)
        response = self.client.get(self.favourite_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()["results"]), 1)

    def test_unauthenticated_request(self):
        self.client.logout()
        response = self.client.get(self.favourite_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
