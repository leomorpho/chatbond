import logging
from datetime import timedelta

from django.utils import timezone

from chatbond.users.models import User

logger = logging.getLogger()


def delete_user_and_associated_objects(user_id):
    try:
        # Fetch the user object from User model
        user = User.objects.get(id=user_id)

        # Make sure to delete any associated data

        # Delete the user
        user.delete()

        logger.info(f"User {user_id} and all associated objects have been deleted.")
    except User.DoesNotExist:
        logger.error(f"User {user_id} does not exist.")


def delete_inactive_users_older_than_theshold(hours=24):
    # Get the current time
    current_time = timezone.now()

    # Calculate the time 24 hours ago
    time_24h_ago = current_time - timedelta(hours=hours)

    # Fetch users who were created more than 24 hours ago and are not activated
    users_to_delete = User.objects.filter(
        date_joined__lte=time_24h_ago, is_active=False
    )

    for user in users_to_delete:
        delete_user_and_associated_objects(user.id)
