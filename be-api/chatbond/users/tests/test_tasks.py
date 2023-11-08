from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from chatbond.chats.models import (
    ChatThread,
    DraftQuestionThread,
    Interlocutor,
    QuestionChat,
    QuestionChatInteractionEvent,
    QuestionThread,
)
from chatbond.questions.models import (
    FavouritedQuestion,
    Question,
    QuestionFeed,
    RatedQuestion,
    SeenQuestion,
)
from chatbond.users.models import User
from chatbond.users.tasks import (
    delete_inactive_users_older_than_theshold,
    delete_user_and_associated_objects,
)


class UserDeletionTest(TestCase):
    def setUp(self):
        # Create Users
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123", is_active=True
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123", is_active=True
        )

        # Create QuestionFeeds for user1
        self.qfeed1 = QuestionFeed.objects.create(interlocutor=self.user1.interlocutor)
        self.qfeed2 = QuestionFeed.objects.create(interlocutor=self.user2.interlocutor)

        # Create Questions associated with QuestionFeeds
        # Create a public question created by user 1. It should NOT be
        # deleted upon user deletion.
        self.question1 = Question.objects.create(
            content="question1", author=self.user1.interlocutor
        )
        # TODO: for when we support user-created questions:
        #   Private questions should be deleted if there were never used
        #   in a question thread
        self.question2 = Question.objects.create(
            content="question2",
            author=self.user2.interlocutor,
            is_private=True,
        )
        # Create a regular question created and owned by the app.
        self.question3 = Question.objects.create(
            content="question3",
        )
        self.question4 = Question.objects.create(
            content="question4",
        )

        self.qfeed1.questions.add(self.question1)
        self.qfeed2.questions.add(self.question2)
        self.qfeed2.questions.add(self.question3)

        # Create a ChatThread involving both users
        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(
            self.user1.interlocutor, self.user2.interlocutor
        )

        # Create a QuestionThread related to ChatThread
        self.q_thread = QuestionThread.objects.create(
            chat_thread=self.chat_thread, question=self.question1
        )

        # Create QuestionChats in the QuestionThread
        self.q_chat1 = QuestionChat.objects.create(
            question_thread=self.q_thread,
            author=self.user1.interlocutor,
            content="Hello",
        )
        self.q_chat2 = QuestionChat.objects.create(
            question_thread=self.q_thread,
            author=self.user2.interlocutor,
            content="What's up?",
        )

        # Create QuestionChatInteractionEvent associated to QuestionChat
        self.chat_interaction_event1 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.q_chat2, interlocutor=self.user1.interlocutor
        )
        self.chat_interaction_event2 = QuestionChatInteractionEvent.objects.create(
            question_chat=self.q_chat1, interlocutor=self.user2.interlocutor
        )

        # Create drafts for both users
        self.draft1 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question4,
            drafter=self.user1.interlocutor,
        )
        self.draft2 = DraftQuestionThread.objects.create(
            chat_thread=self.chat_thread,
            question=self.question4,
            drafter=self.user2.interlocutor,
        )

        self.seen_question1 = SeenQuestion.objects.create(
            interlocutor=self.user1.interlocutor, question=self.question1
        )
        self.favourited_question1 = FavouritedQuestion.objects.create(
            interlocutor=self.user1.interlocutor, question=self.question1
        )
        self.rated_question1 = RatedQuestion.objects.create(
            interlocutor=self.user1.interlocutor, question=self.question1, status="L"
        )
        self.seen_question2 = SeenQuestion.objects.create(
            interlocutor=self.user2.interlocutor, question=self.question1
        )
        self.favourited_question2 = FavouritedQuestion.objects.create(
            interlocutor=self.user2.interlocutor, question=self.question1
        )
        self.rated_question2 = RatedQuestion.objects.create(
            interlocutor=self.user2.interlocutor, question=self.question1, status="L"
        )

    def test_delete_user_and_associated_data(self):
        # Action: Delete user1 and associated data
        delete_user_and_associated_objects(self.user1.id)

        # Assertions for User
        self.assertFalse(User.objects.filter(id=self.user1.id).exists())
        self.assertTrue(User.objects.filter(id=self.user2.id).exists())

        self.assertFalse(
            Interlocutor.objects.filter(id=self.user1.interlocutor.id).exists()
        )
        self.assertTrue(
            Interlocutor.objects.filter(id=self.user2.interlocutor.id).exists()
        )

        # Assertions for QuestionFeed
        self.assertFalse(
            QuestionFeed.objects.filter(interlocutor=self.user1.interlocutor).exists()
        )
        self.assertTrue(
            QuestionFeed.objects.filter(interlocutor=self.user2.interlocutor).exists()
        )

        # Assertions for Question (should not be deleted)
        self.assertTrue(Question.objects.filter(id=self.question1.id).exists())
        self.assertTrue(Question.objects.filter(id=self.question2.id).exists())
        self.assertTrue(Question.objects.filter(id=self.question3.id).exists())

        # Assertions for ChatThread (should not be deleted)
        self.assertTrue(ChatThread.objects.filter(id=self.chat_thread.id).exists())
        self.assertEqual(
            ChatThread.objects.get(id=self.chat_thread.id).interlocutors.count(), 1
        )

        # Assertions for QuestionThread (should not be deleted)
        self.assertTrue(QuestionThread.objects.filter(id=self.q_thread.id).exists())

        # Assertions for QuestionChat (only the one by user1 should be deleted)
        # TODO: for deleted users, only the associated PII should be deleted, not
        # the objects. The reason being that the other users in the thread should
        # still see "ghost" messages in place of the original ones.
        self.assertFalse(QuestionChat.objects.filter(id=self.q_chat1.id).exists())
        self.assertTrue(QuestionChat.objects.filter(id=self.q_chat2.id).exists())

        self.assertFalse(
            QuestionChatInteractionEvent.objects.filter(
                id=self.chat_interaction_event1.id
            ).exists()
        )
        # TODO: might want to review below, should it be deleted?
        self.assertFalse(
            QuestionChatInteractionEvent.objects.filter(
                id=self.chat_interaction_event2.id
            ).exists()
        )

        # Assertions for DraftQuestionThread (only the one by user1 should be deleted)
        self.assertFalse(DraftQuestionThread.objects.filter(id=self.draft1.id).exists())
        self.assertTrue(DraftQuestionThread.objects.filter(id=self.draft2.id).exists())

        # Assertions for SeenQuestion (should be deleted for user1)
        self.assertFalse(
            SeenQuestion.objects.filter(interlocutor=self.user1.interlocutor).exists()
        )
        self.assertTrue(
            SeenQuestion.objects.filter(interlocutor=self.user2.interlocutor).exists()
        )

        # Assertions for FavouritedQuestion (should be deleted for user1)
        self.assertFalse(
            FavouritedQuestion.objects.filter(
                interlocutor=self.user1.interlocutor
            ).exists()
        )
        self.assertTrue(
            FavouritedQuestion.objects.filter(
                interlocutor=self.user2.interlocutor
            ).exists()
        )

        # Assertions for RatedQuestion (should be deleted for user1)
        self.assertFalse(
            RatedQuestion.objects.filter(interlocutor=self.user1.interlocutor).exists()
        )
        self.assertTrue(
            RatedQuestion.objects.filter(interlocutor=self.user2.interlocutor).exists()
        )


class InactiveUserDeletionTest(TestCase):
    def setUp(self):
        # Create Users
        current_time = timezone.now()

        # Users joined more than 24h ago
        self.user1 = User.objects.create_user(
            email="user1@example.com",
            password="password123",
            is_active=True,
            date_joined=current_time - timedelta(hours=25),
        )
        self.user2 = User.objects.create_user(
            email="user2@example.com",
            password="password123",
            is_active=False,
            date_joined=current_time - timedelta(hours=25),
        )

        # Users joined less than 24h ago
        self.user3 = User.objects.create_user(
            email="user3@example.com",
            password="password123",
            is_active=True,
            date_joined=current_time - timedelta(hours=23),
        )
        self.user4 = User.objects.create_user(
            email="user4@example.com",
            password="password123",
            is_active=False,
            date_joined=current_time - timedelta(hours=23),
        )

    def test_delete_inactive_users_older_than_theshold(self):
        delete_inactive_users_older_than_theshold(hours=24)

        # Assertions
        # user1 (active, joined > 24h ago) should not be deleted
        self.assertTrue(User.objects.filter(id=self.user1.id).exists())

        # user2 (inactive, joined > 24h ago) should be deleted
        self.assertFalse(User.objects.filter(id=self.user2.id).exists())

        # user3 (active, joined < 24h ago) should not be deleted
        self.assertTrue(User.objects.filter(id=self.user3.id).exists())

        # user4 (inactive, joined < 24h ago) should not be deleted
        self.assertTrue(User.objects.filter(id=self.user4.id).exists())
