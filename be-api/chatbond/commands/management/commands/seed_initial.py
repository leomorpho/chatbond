# To run the seeder, use the following command:
# python manage.py seed
#

from django.core.management.base import BaseCommand

from chatbond.questions.models import Question
from chatbond.questions.tasks import load_questions_from_csv
from chatbond.recommender.tasks import trigger_tasks_for_first_load


class Command(BaseCommand):
    help = "Seeds the database with questions and associated data for a first load."

    def handle(self, *args, **options):
        self.stdout.write("Creating questions and first load tasks...")

        if Question.objects.count() == 0:
            load_questions_from_csv()
        trigger_tasks_for_first_load()
