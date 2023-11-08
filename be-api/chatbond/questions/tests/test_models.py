from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from parameterized import parameterized

from chatbond.config import QUESTION_FEED_LIFESPAN_IN_MINUTES
from chatbond.questions.models import Question, QuestionFeed, SeenQuestion

User = get_user_model()


class TestQuestionFeed(TestCase):
    def setUp(self):
        user = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = user.interlocutor
        self.question1 = Question.objects.create(content="Test Question 1")
        active_feeds = QuestionFeed.get_active_question_feeds()

        # Delete the feeds since we're testing for them here and 1 gets created
        # on registration.
        for feed in active_feeds:
            feed.delete()

    def test_question_feed_creation_on_user_creation(self):
        """
        Tests if a Question Feed is correctly triggered for creation when a new User is registered.
        """
        # Create a new user
        User.objects.create_user(email="newuser@example.com", password="newpassword")

        active_feeds = QuestionFeed.get_active_question_feeds()

        self.assertEqual(len(active_feeds), 1)

    @parameterized.expand(
        [
            ("no consumption", None, 1),
            ("recent consumption", timezone.now() - timedelta(hours=23), 1),
            ("old consumption", timezone.now() - timedelta(days=2), 0),
        ]
    )
    def test_get_active_question_feeds(self, test_name, consumed_at, expected_count):
        question_feed1 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1, consumedAt=consumed_at
        )
        question_feed1.questions.add(self.question1)

        active_feeds = QuestionFeed.get_active_question_feeds()

        self.assertEqual(len(active_feeds), expected_count)

        # Clean up after the test
        question_feed1.delete()

    @parameterized.expand(
        [
            ("no consumption", None, 2, False),
            ("recent consumption", timezone.now() - timedelta(hours=23), 2, False),
            # Not sure how to enforce feed id, but the feeds in the below 2 cases are
            # different feeds. In first case, it will return the oldest consumed feed.
            # In the second, it will return the oldest not consumed (remember
            # that a new feed gets created on user creation, so there will always be 2
            # in this test).
            ("old consumption", timezone.now() - timedelta(days=2), 1, False),
            ("old consumption", timezone.now() - timedelta(days=2), 1, True),
            ("return oldest unconsumed", None, 1, True),
        ]
    )
    def test_get_active_question_feeds_for_interlocutor(
        self, test_name, consumed_at, expected_count, return_oldest_unconsumed
    ):
        # Create two feeds for the same interlocutor
        question_feed1 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1, consumedAt=consumed_at
        )
        question_feed1.questions.add(self.question1)

        question_feed2 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1, consumedAt=None
        )
        question_feed2.questions.add(self.question1)

        # Fetch active feeds
        active_feeds_for_interlocutor1 = (
            QuestionFeed.get_active_question_feeds_for_interlocutor(
                self.interlocutor1.id, return_oldest_unconsumed=return_oldest_unconsumed
            )
        )

        # If return_oldest_unconsumed flag is True, ensure only one oldest unconsumed feed is returned
        if return_oldest_unconsumed:
            self.assertEqual(len(active_feeds_for_interlocutor1), 1)
            self.assertIsNone(active_feeds_for_interlocutor1[0].consumedAt)
        else:
            self.assertEqual(len(active_feeds_for_interlocutor1), expected_count)

        # Clean up
        question_feed1.delete()
        question_feed2.delete()

    @parameterized.expand(
        [
            ("no consumption", None, 1),
            (
                "recent consumption",
                # TODO: this test is time sensitive, and if the timedelta is not small enough,
                # because dev mode uses a very small feed lifetime, the feed may be marked
                # as consumed too quickly. Be aware of this.
                timezone.now()
                - timedelta(minutes=int(QUESTION_FEED_LIFESPAN_IN_MINUTES / 10)),
                1,
            ),
            (
                "old consumption",
                timezone.now()
                - timedelta(minutes=QUESTION_FEED_LIFESPAN_IN_MINUTES * 2),
                0,
            ),
        ]
    )
    def test_get_interlocutor_ids_with_active_question_feeds(
        self, test_name, consumed_at, expected_count
    ):
        question_feed1 = QuestionFeed.objects.create(
            interlocutor=self.interlocutor1, consumedAt=consumed_at
        )
        question_feed1.questions.add(self.question1)

        active_feed_ids = QuestionFeed.get_interlocutor_ids_with_active_question_feeds()

        self.assertEqual(len(active_feed_ids), expected_count)

        # Clean up after the test
        question_feed1.delete()

    def test_mark_as_consumed_idempotency(self):
        question_feed = QuestionFeed.objects.create(interlocutor=self.interlocutor1)
        question_feed.questions.add(self.question1)

        # Scenario 1: Call mark_as_consumed and verify consumedAt is set
        question_feed.mark_as_consumed()

        question_feed.refresh_from_db()
        self.assertIsNotNone(question_feed.consumedAt)
        initial_consumedAt = question_feed.consumedAt

        # Scenario 2: Verify that SeenQuestion objects are created
        seen_question_ids = set(
            SeenQuestion.objects.filter(interlocutor=self.interlocutor1).values_list(
                "question_id", flat=True
            )
        )
        self.assertEqual(seen_question_ids, {self.question1.id})

        # Scenario 3: Call mark_as_consumed again and verify no additional SeenQuestion objects are created
        question_feed.mark_as_consumed()

        question_feed.refresh_from_db()
        new_seen_question_ids = set(
            SeenQuestion.objects.filter(interlocutor=self.interlocutor1).values_list(
                "question_id", flat=True
            )
        )
        self.assertEqual(seen_question_ids, new_seen_question_ids)

        # Scenario 4: Verify that consumedAt is not changed by repeated calls to mark_as_consumed
        self.assertEqual(initial_consumedAt, question_feed.consumedAt)

        # Clean up after the test
        question_feed.delete()
