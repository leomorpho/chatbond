# runapscheduler.py
import logging
import signal
import sys

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from django.conf import settings
from django.core.management.base import BaseCommand
from django_apscheduler import util
from django_apscheduler.jobstores import DjangoJobStore
from django_apscheduler.models import DjangoJobExecution

from chatbond.infra.tasks import delete_old_email_metadata
from chatbond.questions.tasks import (
    trigger_task_to_delete_expired_seen_question_objects,
)
from chatbond.recommender.tasks import (
    trigger_task_to_create_embeddings_for_public_questions_if_needed,
    trigger_task_to_create_new_question_feeds_if_needed,
)
from chatbond.users.tasks import delete_inactive_users_older_than_theshold

logger = logging.getLogger(__name__)


# The `close_old_connections` decorator ensures that database connections, that have become
# unusable or are obsolete, are closed before and after your job has run. You should use it
# to wrap any jobs that you schedule that access the Django database in any way.
@util.close_old_connections
def delete_old_job_executions(max_age=604_800):
    """
    This job deletes APScheduler job execution entries older than `max_age` from the database.
    It helps to prevent the database from filling up with old historical records that are no
    longer useful.

    :param max_age: The maximum length of time to retain historical job execution records.
                    Defaults to 7 days.
    """
    DjangoJobExecution.objects.delete_old_job_executions(max_age)


class Command(BaseCommand):
    help = "Runs APScheduler."

    def handle(self, *args, **options):
        scheduler = BlockingScheduler(timezone=settings.TIME_ZONE)
        scheduler.add_jobstore(DjangoJobStore(), "default")

        scheduler.add_job(
            trigger_task_to_delete_expired_seen_question_objects,
            trigger=CronTrigger(hour="04", minute="00"),  # Every day
            id="delete_expired_seen_question_objects",
            max_instances=1,
            replace_existing=True,
        )

        scheduler.add_job(
            trigger_task_to_create_embeddings_for_public_questions_if_needed,
            trigger=IntervalTrigger(hours=6),
            id="create_embeddings_for_public_questions_if_needed",
            max_instances=1,
            replace_existing=True,
        )

        scheduler.add_job(
            trigger_task_to_create_new_question_feeds_if_needed,
            trigger=IntervalTrigger(minutes=60),
            id="create_new_question_feeds_if_needed",
            max_instances=1,
            replace_existing=True,
        )

        scheduler.add_job(
            delete_inactive_users_older_than_theshold,
            trigger=IntervalTrigger(hours=1),
            id="delete_inactive_users_older_than_theshold",
            max_instances=1,
            replace_existing=True,
        )

        scheduler.add_job(
            delete_old_job_executions,
            trigger=CronTrigger(
                day_of_week="mon", hour="00", minute="00"
            ),  # Midnight on Monday, before start of the next work week.
            id="delete_old_job_executions",
            max_instances=1,
            replace_existing=True,
        )

        scheduler.add_job(
            delete_old_email_metadata,
            trigger=CronTrigger(hour="00", minute="00"),  # Once a day
            id="delete_old_email_metadata",
            max_instances=1,
            replace_existing=True,
        )

        def shutdown(*args):
            self.stdout.write("Exiting...")
            sys.exit(0)

        signal.signal(signal.SIGINT, shutdown)
        signal.signal(signal.SIGTERM, shutdown)

        self.stdout.write("Discovered tasks:")

        for s in scheduler.get_jobs():
            self.stdout.write(f"* {s.name} - {s.trigger}")

        self.stdout.write("\nStarting scheduler...")

        scheduler.start()

        return 0
