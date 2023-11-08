from rest_framework import serializers
from rest_framework.serializers import SerializerMethodField

from .models import INVITATION_TOKEN_LIFETIME_IN_DAYS, Invitation


class InvitationSerializer(serializers.ModelSerializer):
    invite_url = serializers.CharField(read_only=True, source="get_invite_url")
    validity_duration_in_days = SerializerMethodField()

    class Meta:
        model = Invitation
        fields = [
            "id",
            "inviter",
            "invitee_name",
            "token",
            "accepted_at",
            "created_at",
            "updated_at",
            "invite_url",
            "validity_duration_in_days",
        ]

    def get_validity_duration_in_days(self, obj):
        return INVITATION_TOKEN_LIFETIME_IN_DAYS


class CreateInvitationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invitation
        fields = [
            "invitee_name",
        ]
