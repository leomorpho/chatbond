# To run the seeder, use the following command:
# python manage.py seed
#

from random import choice
from typing import List, Tuple

from django.core.management.base import BaseCommand
from django.utils.timezone import now
from faker import Faker

from chatbond.chats.models import (ChatThread, DraftQuestionThread,
                                   Interlocutor, QuestionChat,
                                   QuestionChatInteractionEvent,
                                   QuestionThread)
from chatbond.chats.usecase import create_chat_thread
from chatbond.invitations.models import Invitation
from chatbond.questions.models import LikedStatus, Question, RatedQuestion
from chatbond.questions.tasks import load_questions_from_csv
from chatbond.recommender.tasks import trigger_tasks_for_first_load
from chatbond.users.models import User


class Command(BaseCommand):
    help = "Seeds the database with users, interlocutors, chat threads, \
        question threads, questions, and question chats."

    def handle(self, *args, **options):
        self.stdout.write(
            "Creating users, interlocutors, chat threads, question threads,"
            "questions, and question chats..."
        )

        load_questions_from_csv()
        # load_questions_from_csv(num_questions=500)

        fake = Faker()

        self.alice = User.objects.create_user(
            name="Alice",
            email="alice@test.com",
            date_of_birth=fake.date_of_birth(minimum_age=18, maximum_age=100),
            password="testpassword",
        )
        bob = User.objects.create_user(
            name="Bob",
            email="bob@test.com",
            date_of_birth=fake.date_of_birth(minimum_age=18, maximum_age=100),
            password="testpassword",
        )
        lynn = User.objects.create_user(
            name="Lynn",
            email="lynn@test.com",
            date_of_birth=fake.date_of_birth(minimum_age=18, maximum_age=100),
            password="testpassword",
        )

        alice_bob_chat_thread = create_chat_thread(
            [self.alice.interlocutor, bob.interlocutor]
        )

        alice_lynn_chat_thread = create_chat_thread(
            [self.alice.interlocutor, lynn.interlocutor]
        )

        questions = Question.objects.all()[:130]
        chat_data = [
            (
                questions[0].content,
                [
                    (
                        0,
                        "That's an interesting question! I think I'd trade lives with Elon Musk...",
                    ),
                    (
                        1,
                        "Hmm, I'd actually choose to trade lives with a famous travel blogger...",
                    ),
                    (0, "That's cool! I can see how that would be exciting..."),
                    (1, "I've always wanted to go to New Zealand..."),
                    (
                        0,
                        "I'd probably use the day to try to push some environmentally friendly projects forward...",
                    ),
                ],
            ),
            (
                questions[1].content,
                [
                    (
                        0,
                        "I'd pick Deadpool. At least he'd make the whole experience entertaining...",
                    ),
                    (
                        1,
                        "I'd go with Sherlock Holmes. If anyone could find a way out, it's him...",
                    ),
                    (
                        0,
                        "Haha, good choice! Who knows, you might become a detective after that ordeal...",
                    ),
                    (
                        1,
                        "Exactly! And with Deadpool by your side, you'd probably end up in some wild adventure after escaping the elevator...",
                    ),
                    (0, "No doubt! Elevator escapades, here we come!"),
                ],
            ),
            (
                questions[2].content,
                [
                    (
                        0,
                        "My favorite movie is The Shawshank Redemption. The story of hope and friendship really resonates with me...",
                    ),
                    (
                        1,
                        "I love the book To Kill a Mockingbird. It's a powerful exploration of human nature and morality...",
                    ),
                    (
                        0,
                        "Those are both great choices! What lessons do you think we can learn from those stories?",
                    ),
                    (
                        1,
                        "From The Shawshank Redemption, I think we can learn about the power of hope and resilience. From To Kill a Mockingbird, we can learn about empathy and standing up for what's right...",
                    ),
                    (
                        0,
                        "Absolutely! It's amazing how much we can learn from literature and film.",
                    ),
                ],
            ),
            (
                questions[3].content,
                [
                    (
                        0,
                        "I'd choose the ability to teleport. It would be so convenient to travel instantly anywhere in the world...",
                    ),
                    (
                        1,
                        "I'd want to have the power of mind reading. It would be fascinating to know what people are really thinking...",
                    ),
                    (
                        0,
                        "Those are both cool powers! How would you use them to help others?",
                    ),
                    (
                        1,
                        "With teleportation, I could help transport people or supplies during emergencies. With mind reading, I could better understand and support people's needs and emotions...",
                    ),
                    (
                        0,
                        "It's great to think about how we can use our abilities for the greater good.",
                    ),
                ],
            ),
            (
                questions[4].content,
                [
                    (
                        0,
                        "I love spending weekends outdoors, hiking, and exploring nature. It's a great way to relax and recharge...",
                    ),
                    (
                        1,
                        "For me, I prefer staying in and watching movies or reading a good book. It's a nice way to unwind after a busy week...",
                    ),
                    (
                        0,
                        "I totally understand that. Sometimes, staying home can be just as rejuvenating as being outside.",
                    ),
                    (
                        1,
                        "Exactly! And when I'm in the mood for some outdoor time, I enjoy going for a walk in the park.",
                    ),
                    (
                        0,
                        "That's a great way to get some fresh air and enjoy the beauty of nature.",
                    ),
                    (
                        0,
                        "By the way, have you ever been camping or taken any longer trips outdoors?",
                    ),
                    (
                        1,
                        "Yes, I've been camping a few times. It's a fun experience, especially when shared with friends or family.",
                    ),
                    (
                        1,
                        "How about you? Have you done any longer hikes or outdoor adventures?",
                    ),
                    (
                        0,
                        "Yes, I've done a few multi-day hikes and even tried my hand at rock climbing. They were both challenging and rewarding experiences.",
                    ),
                ],
            ),
            (
                questions[5].content,
                [
                    (
                        0,
                        "I've always wanted to learn how to play the piano. I love listening to classical music, and I think it would be amazing to be able to play it myself...",
                    ),
                    (
                        1,
                        "That's a great choice! I've always wanted to learn a new language, like Spanish or Japanese. I think it would be really useful for traveling and connecting with people from different cultures...",
                    ),
                    (
                        0,
                        "Absolutely, learning a new language can open up so many opportunities.",
                    ),
                    (
                        0,
                        "As for the piano, I think it's a skill that would bring a lot of joy and satisfaction.",
                    ),
                    (
                        1,
                        "Definitely! And who knows, maybe one day we can combine our skills and travel to a foreign country where you can play the piano for a local audience.",
                    ),
                    (0, "That would be a dream come true!"),
                ],
            ),
            (
                questions[6].content,
                [
                    (
                        0,
                        "The best advice I've received is to always be true to yourself and follow your own path, even if it's different from what others expect of you...",
                    ),
                    (
                        1,
                        "That's a powerful message. For me, the best advice I've been given is to never stop learning and growing, both personally and professionally...",
                    ),
                    (
                        0,
                        "I couldn't agree more. Personal growth is essential for a fulfilling life.",
                    ),
                    (
                        1,
                        "Yes, and it's important to remember that it's never too late to learn something new or make a positive change.",
                    ),
                    (
                        0,
                        "Absolutely. In fact, I've found that some of the most valuable lessons in life come from experiences and challenges we face as we grow older.",
                    ),
                    (
                        1,
                        "I agree. Life is a continuous journey of learning and self-improvement.",
                    ),
                ],
            ),
            (
                questions[7].content,
                [
                    (
                        0,
                        "The best advice I've received is to always be true to yourself and follow your own path, even if it's different from what others expect of you...",
                    ),
                    (
                        1,
                        "That's a powerful message. For me, the best advice I've been given is to never stop learning and growing, both personally and professionally...",
                    ),
                ],
            ),
        ]
        for i in range(8, 120):
            chat_data.append(
                (
                    questions[i].content,
                    [
                        (
                            0,
                            "So cool",
                        ),
                        (
                            1,
                            "Yeah mate!",
                        ),
                        (
                            0,
                            "It's like someone's spying on us",
                        ),
                        (
                            1,
                            "It's some mindblowing stuff! I feel like my mind is, like, spread out over a kilometer",
                        ),
                    ],
                )
            )

        self.create_question_thread(
            alice_bob_chat_thread,
            bob.interlocutor,
            self.alice.interlocutor,
            chat_data[0],
        )
        self.create_question_thread(
            alice_bob_chat_thread,
            self.alice.interlocutor,
            bob.interlocutor,
            chat_data[1],
        )

        self.create_question_thread(
            alice_lynn_chat_thread,
            self.alice.interlocutor,
            lynn.interlocutor,
            chat_data[2],
        )
        self.create_question_thread(
            alice_lynn_chat_thread,
            lynn.interlocutor,
            self.alice.interlocutor,
            chat_data[3],
        )

        self.create_question_thread(
            alice_lynn_chat_thread,
            self.alice.interlocutor,
            lynn.interlocutor,
            chat_data[4],
        )

        self.create_question_thread(
            alice_lynn_chat_thread,
            self.alice.interlocutor,
            lynn.interlocutor,
            chat_data[5],
        )

        self.create_question_thread(
            alice_lynn_chat_thread,
            self.alice.interlocutor,
            lynn.interlocutor,
            chat_data[6],
        )

        self.create_question_thread(
            alice_lynn_chat_thread,
            self.alice.interlocutor,
            lynn.interlocutor,
            chat_data[7],
        )
        for i in range(8, 120):
            self.create_question_thread(
                alice_lynn_chat_thread,
                self.alice.interlocutor,
                lynn.interlocutor,
                chat_data[i],
            )

        trigger_tasks_for_first_load()

        DraftQuestionThread.objects.create(
            chat_thread=alice_lynn_chat_thread,
            question=questions[7],
            drafter=self.alice.interlocutor,
            content=(
                "I believe the most important quality in maintaining a strong "
                "relationship is open and honest communication. It's the foundation for "
                "trust and understanding, allowing both parties to express "
                "their feelings, "
                "needs, and desires. By actively listening and empathizing with one "
                "another, we can work through challenges, grow together, and foster a "
                "deeper connection that stands the test of time."
            ),
        )

        self.create_alice_interactions()

        RatedQuestion.objects.create(
            interlocutor=bob.interlocutor,
            question=questions[7],
            status=LikedStatus.LIKED,
        )
        RatedQuestion.objects.create(
            interlocutor=lynn.interlocutor,
            question=questions[7],
            status=LikedStatus.DISLIKED,
        )

        Invitation.objects.create_invitation_with_unique_token(
            inviter=self.alice.interlocutor, invitee_name="Jamel"
        )
        Invitation.objects.create_invitation_with_unique_token(
            inviter=bob.interlocutor, invitee_name="Celine"
        )
        Invitation.objects.create_invitation_with_unique_token(
            inviter=lynn.interlocutor, invitee_name="Magda"
        )

        # Create some questions waiting on Alice
        common_question = self.get_random_unassociated_question(alice_lynn_chat_thread)
        question_thread = QuestionThread.objects.create(
            chat_thread=alice_lynn_chat_thread,
            question=common_question,
            all_interlocutors_answered=False,
        )
        QuestionChat.objects.create(
            author=lynn.interlocutor,
            question_thread=question_thread,
            content="Hola my friend!",
            status="published",
        )
        question_thread = QuestionThread.objects.create(
            chat_thread=alice_bob_chat_thread,
            question=common_question,
            all_interlocutors_answered=False,
        )
        QuestionChat.objects.create(
            author=bob.interlocutor,
            question_thread=question_thread,
            content="Hola my friend!",
            status="published",
        )
        question_thread = QuestionThread.objects.create(
            chat_thread=alice_bob_chat_thread,
            question=self.get_random_unassociated_question(alice_lynn_chat_thread),
            all_interlocutors_answered=False,
        )
        QuestionChat.objects.create(
            author=bob.interlocutor,
            question_thread=question_thread,
            content="Hola my friend!",
            status="published",
        )

        self.stdout.write(self.style.SUCCESS("Done seeding the database."))

    def create_question_thread(
        self,
        chat_thread: ChatThread,
        interlocutor_a: Interlocutor,
        interlocutor_b: Interlocutor,
        question_and_answers: Tuple[str, List[Tuple[int, str]]],
    ) -> None:
        question_content, answers = question_and_answers

        question = Question.objects.filter(
            content=question_content,
        ).first()

        question_thread = QuestionThread.objects.create(
            chat_thread=chat_thread,
            question=question,
            all_interlocutors_answered=True,
        )

        num_answers = len(answers)
        for index, (user_index, answer) in enumerate(answers):
            if user_index == 0:
                sender = interlocutor_a
                receiver = interlocutor_b
            else:
                sender = interlocutor_b
                receiver = interlocutor_a

            self.createQuestionChat(
                sender, receiver, question_thread, answer, index == num_answers - 1
            )

    def get_random_unassociated_question(self, chat_thread_id):
        # Get the IDs of questions which are already associated with the given chat_thread
        associated_question_ids = QuestionThread.objects.filter(
            chat_thread_id=chat_thread_id
        ).values_list("question__id", flat=True)

        # Get a queryset of questions not in the above list
        unassociated_questions = Question.objects.exclude(
            id__in=associated_question_ids
        )

        # If no unassociated questions, return None
        if not unassociated_questions.exists():
            return None

        # Otherwise, select a random question from the queryset
        random_question = choice(unassociated_questions)

        return random_question

    def createQuestionChat(
        self,
        author: Interlocutor,
        recipient: Interlocutor,
        question_thread: QuestionThread,
        content: str,
        is_last_chat: bool,
    ) -> None:
        question_chat = QuestionChat.objects.create(
            author=author,
            question_thread=question_thread,
            content=content,
            status="published",
        )
        if not is_last_chat:
            QuestionChatInteractionEvent.objects.create(
                question_chat=question_chat,
                interlocutor=recipient,
                received_at=now(),
                seen_at=now(),
            )

    def create_alice_interactions(self) -> None:
        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )

        RatedQuestion.objects.create(
            interlocutor=self.alice.interlocutor,
            question=Question.objects.order_by("?").first(),
            status=LikedStatus.LIKED,
        )
