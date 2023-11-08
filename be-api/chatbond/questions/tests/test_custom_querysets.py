from rest_framework.test import APITestCase

from chatbond.chats.models import (
    ChatThread,
    DraftQuestionThread,
    Interlocutor,
    QuestionChat,
    QuestionThread,
)
from chatbond.questions.custom_queryset import (
    get_questions_ready_to_answer,
    get_questions_with_drafts,
)
from chatbond.questions.models import Question
from chatbond.users.models import User


class GetQuestionsReadyToAnswerTestCase(APITestCase):
    def setUp(self):
        """Create:
        - 1 question thread that was answered by interlocutor 1, and is now
            answerable by interlocutor 2
        - and vice versa
        """
        super().setUp()
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        # create questions, question threads and chats
        self.question1 = Question.objects.create(content="Question 1")
        self.question2 = Question.objects.create(content="Question 2")
        self.question3 = Question.objects.create(content="Question 3")

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1)
        self.chat_thread.interlocutors.add(self.interlocutor2)

        self.question_thread1 = QuestionThread.objects.create(
            question=self.question1, chat_thread=self.chat_thread
        )
        self.question_thread2 = QuestionThread.objects.create(
            question=self.question2, chat_thread=self.chat_thread
        )
        self.question_thread3 = QuestionThread.objects.create(
            question=self.question3, chat_thread=self.chat_thread
        )

        self.chat1 = QuestionChat.objects.create(
            author=self.interlocutor1,
            question_thread=self.question_thread1,
            content="Chat from interlocutor 1 for question 1",
        )
        self.chat2 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread2,
            content="Chat from interlocutor 2 for question 2",
        )
        self.chat3 = QuestionChat.objects.create(
            author=self.interlocutor2,
            question_thread=self.question_thread3,
            content="Chat from interlocutor 2 for question 3",
        )

    def test_get_questions_ready_to_answer(self):
        """Test getting questions that are ready for an interlocutor to answer."""
        questions = get_questions_ready_to_answer(self.interlocutor2.id)
        self.assertEqual(len(questions), 1)
        self.assertEqual(questions[0].id, self.question1.id)

        questions = get_questions_ready_to_answer(self.interlocutor1.id)
        self.assertEqual(len(questions), 2)
        self.assertEqual(
            {x.id for x in questions}, {self.question2.id, self.question3.id}
        )


class GetQuestionsWithDraftsTestCase(APITestCase):
    def setUp(self):
        super().setUp()
        self.user1 = User.objects.create_user(
            email="user1@example.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)

        self.user2 = User.objects.create_user(
            email="user2@example.com", password="password123"
        )
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

        self.chat_thread = ChatThread.objects.create()
        self.chat_thread.interlocutors.add(self.interlocutor1)
        self.chat_thread.interlocutors.add(self.interlocutor2)

        # create questions, question threads and drafts
        self.question1 = Question.objects.create(content="Question 1")
        self.question2 = Question.objects.create(content="Question 2")
        self.question3 = Question.objects.create(content="Question 3")

        self.draft1 = DraftQuestionThread.objects.create(
            question=self.question1,
            drafter=self.interlocutor1,
            chat_thread=self.chat_thread,
            content="Draft 1",
        )
        self.draft2 = DraftQuestionThread.objects.create(
            question=self.question2,
            drafter=self.interlocutor2,
            chat_thread=self.chat_thread,
            content="Draft 2",
        )
        self.draft2 = DraftQuestionThread.objects.create(
            question=self.question3,
            drafter=self.interlocutor2,
            chat_thread=self.chat_thread,
            content="Draft 3",
        )

    def test_get_questions_with_drafts(self):
        questions = get_questions_with_drafts(self.interlocutor1.id)
        self.assertEqual(len(questions), 1)
        self.assertEqual(questions[0].id, self.question1.id)

        questions = get_questions_with_drafts(self.interlocutor2.id)
        self.assertEqual(len(questions), 2)
        self.assertEqual(
            {x.id for x in questions}, {self.question2.id, self.question3.id}
        )
