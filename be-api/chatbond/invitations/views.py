from datetime import timedelta

from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.exceptions import MethodNotAllowed, PermissionDenied
from rest_framework.generics import CreateAPIView
from rest_framework.mixins import DestroyModelMixin, ListModelMixin
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from rest_framework.views import APIView
from rest_framework.viewsets import GenericViewSet

from chatbond.chats.models import Interlocutor
from chatbond.chats.serializers import ChatThreadSerializer
from chatbond.chats.usecase import create_chat_thread
from chatbond.realtime.dataclass import RealtimePayloadTypes, RealtimeUpdateAction
from chatbond.realtime.service import realtimeUpdateService

from .models import INVITATION_TOKEN_LIFETIME_IN_DAYS, Invitation
from .serializers import CreateInvitationSerializer, InvitationSerializer


@extend_schema(
    tags=["Invitation"],
    description="Create an invitation to a new chat thread for the currently \
        logged in interlocutor.",
    request=CreateInvitationSerializer,
    responses={201: InvitationSerializer},
)
class CreateInvitationView(CreateAPIView):
    queryset = Invitation.objects.all()
    serializer_class = CreateInvitationSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user = request.user
        interlocutor = Interlocutor.objects.get(user=user)
        invitee_name = request.data.get("invitee_name", None)
        if not invitee_name:
            return Response(
                {"error": "invitee_name is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        invitation = Invitation.objects.create_invitation_with_unique_token(
            interlocutor, invitee_name
        )
        serializer = InvitationSerializer(invitation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


@extend_schema(
    tags=["Invitation"],
    description="See an invitation to a new chat thread for the currently \
        logged in interlocutor.",
)
class InvitationViewSet(ListModelMixin, DestroyModelMixin, GenericViewSet):
    """
    A viewset for creating and managing invitations.

    Users can create invitations, but each invitation can only be queried
    by its creator.

    Attributes:
        queryset: QuerySet of all Invitation objects.
        serializer_class: Serializer class used for the Invitation model.
        permission_classes: Permissions required for accessing the viewset.
    """

    queryset = Invitation.objects.all()
    serializer_class = InvitationSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)
        return Invitation.objects.filter(inviter=interlocutor, accepted_at=None)

    def destroy(self, request, pk=None, *args, **kwargs):
        invitation = get_object_or_404(self.queryset, pk=pk)
        user = request.user
        interlocutor = Interlocutor.objects.get(user=user)
        if invitation.inviter != interlocutor:
            raise PermissionDenied()

        invitation_serializer = InvitationSerializer(
            invitation, context={"request": request}
        )
        # Tell the inviter that they can delete the associated invitation
        realtimeUpdateService.publish_to_personal_channels(
            payload_type=RealtimePayloadTypes.INVITATION,
            payload_content=invitation_serializer.data,
            userIds=[invitation.inviter.user.id],
            action=RealtimeUpdateAction.DELETE,
        )
        return super().destroy(request, *args, **kwargs)

    @extend_schema(exclude=True)
    def update(self, request, *args, **kwargs):
        raise MethodNotAllowed(method="put")

    @extend_schema(exclude=True)
    def partial_update(self, request, *args, **kwargs):
        raise MethodNotAllowed(method="patch")


@extend_schema(
    tags=["Invitation"],
    description="Accept an invitation to join a chat thread using the token.",
    responses={201: ChatThreadSerializer},
)
class AcceptInvitationAPIView(APIView):
    """
    NOTE: this API is currently designed only for 2 people in a conversation.

    An API view for accepting an invitation to join a chat thread using a token.

    Users can use this view to accept an invitation to join a chat thread
    by providing a token associated with the invitation.

    Attributes:
        permission_classes: Permissions required for accessing the API view.

    Methods:
        post(request, token): Accept an invitation using the provided token and
            create a new chat thread with the inviter and invitee as interlocutors.
    """

    permission_classes = [IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    throttle_scope = "invitation_accept"  # Add this line

    # TODO: somehow, after creating invitations, I winded up with duplicate chat threads
    # that had the same set of interlocutors. I added a check in create_chat_thread for now.
    def post(self, request, token):
        try:
            invitation = Invitation.objects.get(token=token)

        except Invitation.DoesNotExist:
            return Response(
                {"detail": "Invalid token."}, status=status.HTTP_400_BAD_REQUEST
            )

        if invitation.created_at < timezone.now() - timedelta(
            days=INVITATION_TOKEN_LIFETIME_IN_DAYS
        ):
            return Response(
                {"detail": "Invitation expired."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if request.user == invitation.inviter.user:
            return Response(
                {"detail": "Inviter and invitee cannot be the same person."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if invitation.accepted_at:
            return Response(
                {"detail": "Invitation already accepted."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        interlocutor_accepting_invite = Interlocutor.objects.get(user=request.user)
        # TODO: this currently only supports 2 users per chat thread
        chat_thread = create_chat_thread(
            [invitation.inviter, interlocutor_accepting_invite]
        )

        invitation.accepted_at = timezone.now()
        invitation.save()

        chat_thread_serializer = ChatThreadSerializer(
            chat_thread, context={"request": request}
        )

        # Notify other linked user who are connected
        realtimeUpdateService.publish_to_personal_channels(
            payload_type=RealtimePayloadTypes.CHAT_THREAD,
            payload_content=chat_thread_serializer.data,
            # TODO: I believe we currently get this data duplicated for accepter (on FE)
            userIds=[invitation.inviter.user.id, interlocutor_accepting_invite.user.id],
            action=RealtimeUpdateAction.UPSERT,
        )

        invitation_serializer = InvitationSerializer(
            invitation, context={"request": request}
        )
        # Tell the inviter that they can delete the associated invitation
        realtimeUpdateService.publish_to_personal_channels(
            payload_type=RealtimePayloadTypes.INVITATION,
            payload_content=invitation_serializer.data,
            userIds=[invitation.inviter.user.id],
            action=RealtimeUpdateAction.DELETE,
        )

        return Response(chat_thread_serializer.data, status=status.HTTP_201_CREATED)
