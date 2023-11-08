import os
import secrets
from datetime import timedelta
from typing import Union

from django.db import models
from django.utils import timezone

from chatbond.chats.models import Interlocutor
from chatbond.common.models import AbstractAuditable, AbstractPrimaryKey
from chatbond.config import INVITATION_URL

# TODO: set in env var? At the least, move to some central config (eventually)
INVITATION_TOKEN_LENGTH = 8
INVITATION_TOKEN_LIFETIME_IN_DAYS = 30


class InvitationManager(models.Manager):
    def create_invitation_with_unique_token(
        self,
        inviter: "Interlocutor",
        invitee_name: Union[str, None] = None,
    ) -> "Invitation":
        # Check if an invitation with the same inviter and invitee_name already exists
        existing_invitation = self.filter(inviter=inviter, invitee_name=invitee_name)
        if existing_invitation.exists():
            # Here you can either return the existing invitation or raise an exception
            # return existing_invitation.first()
            raise ValueError(
                "An invitation with the same inviter and invitee_name already exists"
            )

        unique_token = False
        token_age = timezone.now() - timedelta(days=INVITATION_TOKEN_LIFETIME_IN_DAYS)

        while not unique_token:
            token = secrets.token_urlsafe(INVITATION_TOKEN_LENGTH)
            if not self.filter(token=token, created_at__gte=token_age).exists():
                unique_token = True

        return self.create(inviter=inviter, token=token, invitee_name=invitee_name)


class Invitation(AbstractPrimaryKey, AbstractAuditable):
    objects = InvitationManager()

    inviter = models.ForeignKey(
        Interlocutor, on_delete=models.CASCADE, related_name="created_invitations"
    )
    # Name of the person who is invited. This name appears only for the inviter, and
    # upon acceptance of the invitation, is used as the name of the chat thread.
    invitee_name = models.CharField(max_length=150, blank=None, null=True)

    token = models.CharField(max_length=15)
    accepted_at = models.DateTimeField(null=True, blank=True)

    def get_invite_url(self):
        # TODO: adjust when deployed!!
        return f"{os.getenv('FRONTEND_APP_DOMAIN')}/" + INVITATION_URL.format(
            token=self.token
        )

    class Meta:
        abstract = False
        unique_together = ("inviter", "invitee_name")
