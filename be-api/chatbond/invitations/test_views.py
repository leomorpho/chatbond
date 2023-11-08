import secrets
from datetime import timedelta
from unittest.mock import patch

from django.utils.timezone import now
from parameterized import parameterized
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from chatbond.chats.models import ChatThread, Interlocutor
from chatbond.invitations.models import INVITATION_TOKEN_LENGTH, Invitation
from chatbond.realtime.service import realtimeUpdateService
from chatbond.users.models import User


class CreateInvitationViewTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

    @parameterized.expand(
        [
            (
                "user1_authenticated",
                "user1@gmail.com",
                "Invitee1",
                status.HTTP_201_CREATED,
                1,
            ),
            (
                "user2_authenticated",
                "user2@gmail.com",
                "Invitee2",
                status.HTTP_201_CREATED,
                1,
            ),
            ("unauthenticated", None, "Invitee3", status.HTTP_401_UNAUTHORIZED, None),
            (
                "missing_invitee_name",
                "user1@gmail.com",
                None,
                status.HTTP_400_BAD_REQUEST,
                None,
            ),
        ]
    )
    def test_create_invitation(
        self,
        name,
        user_email,
        invitee_name,
        expected_status_code,
        expected_invitation_count,
    ):
        client = APIClient()

        if user_email:
            user = User.objects.get(email=user_email)
            client.force_authenticate(user=user)

        url = "/api/v1/create-invitation/"
        data = {}
        if invitee_name:
            data["invitee_name"] = invitee_name
        response = client.post(url, data=data, format="json")

        self.assertEqual(response.status_code, expected_status_code)

        if expected_invitation_count is not None:
            invitations = Invitation.objects.filter(invitee_name=invitee_name)
            self.assertEqual(invitations.count(), expected_invitation_count)
            if user_email == "user1@gmail.com":
                self.assertEqual(invitations.first().inviter, self.interlocutor1)
            if user_email == "user2@gmail.com":
                self.assertEqual(invitations.first().inviter, self.interlocutor2)

            # Verify successful response has a full invitation object
            self.assertIn("id", response.json())
            self.assertIn("inviter", response.json())
            self.assertIn("invitee_name", response.json())
            self.assertIn("token", response.json())
            self.assertIn("accepted_at", response.json())
            self.assertIn("created_at", response.json())
            self.assertIn("updated_at", response.json())
            self.assertIn("invite_url", response.json())


class InvitationViewSetTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

    @parameterized.expand(
        [
            ("user1_authenticated", "user1@gmail.com", status.HTTP_200_OK, 1),
            ("user2_authenticated", "user2@gmail.com", status.HTTP_200_OK, 1),
            ("unauthenticated", None, status.HTTP_401_UNAUTHORIZED, None),
        ]
    )
    def test_list_invitations(
        self, name, user_email, expected_status_code, expected_invitation_count
    ):
        Invitation.objects.create(inviter=self.interlocutor1)
        Invitation.objects.create(inviter=self.interlocutor2)

        client = APIClient()

        if user_email:
            user = User.objects.get(email=user_email)
            client.force_authenticate(user=user)

        url = "/api/v1/invitations/"
        response = client.get(url, format="json")

        self.assertEqual(response.status_code, expected_status_code)

        if expected_invitation_count is not None:
            self.assertEqual(len(response.data), expected_invitation_count)
            if user_email == "user1@gmail.com":
                self.assertEqual(
                    str(self.interlocutor1.id), response.json()[0]["inviter"]
                )
            if user_email == "user2@gmail.com":
                self.assertEqual(
                    str(self.interlocutor2.id), response.json()[0]["inviter"]
                )

    @parameterized.expand(
        [
            ("own_invitation", "user1@gmail.com", 1, status.HTTP_204_NO_CONTENT),
            ("other_invitation", "user1@gmail.com", 2, status.HTTP_403_FORBIDDEN),
            ("unauthenticated", None, 1, status.HTTP_401_UNAUTHORIZED),
        ]
    )
    @patch.object(realtimeUpdateService, "publish_to_personal_channels")
    def test_delete_invitation(
        self,
        name,
        user_email,
        invitation_id,
        expected_status_code,
        mock_publish_to_personal_channels,
    ):
        invitation_1 = Invitation.objects.create(inviter=self.interlocutor1)
        invitation_2 = Invitation.objects.create(inviter=self.interlocutor2)

        client = APIClient()

        if user_email:
            user = User.objects.get(email=user_email)
            client.force_authenticate(user=user)

        deleted_invitation_id = None
        if invitation_id == 1:
            deleted_invitation_id = invitation_1.id
        else:
            deleted_invitation_id = invitation_2.id

        url = f"/api/v1/invitations/{deleted_invitation_id}/"
        response = client.delete(url)

        self.assertEqual(response.status_code, expected_status_code)

        if expected_status_code == status.HTTP_204_NO_CONTENT:
            self.assertFalse(
                Invitation.objects.filter(id=deleted_invitation_id).exists()
            )
            mock_publish_to_personal_channels.assert_called_once()
        else:
            self.assertTrue(
                Invitation.objects.filter(id=deleted_invitation_id).exists()
            )

    @parameterized.expand(
        [
            ("put", "put", None),
            ("patch", "patch", None),
            ("post", "post", None),
        ]
    )
    def test_methods_not_allowed_for_invitations(self, name, method, data):
        client = APIClient()
        client.force_authenticate(user=self.user1)
        url = "/api/v1/invitations/1/"
        response = getattr(client, method)(url, data=data)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)


class AcceptInvitationAPIViewTestCase(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            email="user1@gmail.com", password="password123"
        )
        self.user2 = User.objects.create_user(
            email="user2@gmail.com", password="password123"
        )
        self.interlocutor1 = Interlocutor.objects.get(user=self.user1)
        self.interlocutor2 = Interlocutor.objects.get(user=self.user2)

    @parameterized.expand(
        [
            ("unauthenticated", None, "correct_token", status.HTTP_401_UNAUTHORIZED),
            (
                "authenticated_correct_token",
                "user1@gmail.com",
                "correct_token",
                status.HTTP_201_CREATED,
            ),
            (
                "authenticated_incorrect_token",
                "user1@gmail.com",
                "incorrect_token",
                status.HTTP_400_BAD_REQUEST,
            ),
        ]
    )
    @patch.object(realtimeUpdateService, "publish_to_personal_channels")
    def test_accept_invitation(
        self,
        name,
        user_email,
        token_scenario,
        expected_status_code,
        mock_publish_to_personal_channels,
    ):
        incorrect_token = secrets.token_hex(INVITATION_TOKEN_LENGTH)

        invitation = Invitation.objects.create_invitation_with_unique_token(
            inviter=self.interlocutor2
        )
        correct_token = invitation.token

        client = APIClient()

        if user_email:
            user = User.objects.get(email=user_email)
            client.force_authenticate(user=user)

        token = correct_token if token_scenario == "correct_token" else incorrect_token
        url = f"/api/v1/invitations/accept/{token}/"
        response = client.post(url, format="json")

        self.assertEqual(response.status_code, expected_status_code)

        if expected_status_code == status.HTTP_201_CREATED:
            invitation.refresh_from_db()
            self.assertIsNotNone(invitation.accepted_at)
            self.assertEqual(ChatThread.objects.count(), 1)
            chat_thread = ChatThread.objects.first()
            self.assertIn(self.interlocutor1, chat_thread.interlocutors.all())
            self.assertIn(self.interlocutor2, chat_thread.interlocutors.all())
            self.assertEqual(mock_publish_to_personal_channels.call_count, 2)

    def test_accept_own_invitation(self):
        token = secrets.token_hex(INVITATION_TOKEN_LENGTH)

        invitation = Invitation.objects.create_invitation_with_unique_token(
            inviter=self.interlocutor1
        )

        client = APIClient()

        client.force_authenticate(user=self.user1)

        url = f"/api/v1/invitations/accept/{token}/"
        response = client.post(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        invitation.refresh_from_db()
        self.assertIsNone(invitation.accepted_at)

    def test_expired_invitation(self):
        # Create an invitation with a created_at timestamp set to more than 30 days ago
        expired_invitation = Invitation.objects.create(
            inviter=self.interlocutor2, token="expired_token"
        )
        expired_invitation.created_at = now() - timedelta(days=31)
        expired_invitation.save()

        client = APIClient()
        client.force_authenticate(user=self.user1)

        url = f"/api/v1/invitations/accept/{expired_invitation.token}/"
        response = client.post(url, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["detail"], "Invitation expired.")

    @parameterized.expand(
        [
            ("put", "put", None),
            ("patch", "patch", None),
        ]
    )
    def test_methods_not_allowed_for_accept_invitations(self, name, method, data):
        client = APIClient()
        client.force_authenticate(user=self.user1)
        url = "/api/v1/invitations/accept/1/"
        response = getattr(client, method)(url, data=data)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
