from django.apps import apps
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

User = get_user_model()


class Command(BaseCommand):
    help = "Clears the entire database."

    def handle(self, *args, **options):
        self.stdout.write("Clearing the entire database...")

        for model in apps.get_models():
            if model.__module__.startswith("django"):
                continue  # skip Django's built-in models

            # Special case for User model - don't delete superusers
            if model == User:
                model.objects.filter(is_superuser=False).delete()
            else:
                model.objects.all().delete()

        self.stdout.write(self.style.SUCCESS("Done clearing the database."))
