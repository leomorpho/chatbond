from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.views import APIView

from .models import User
from .serializers import ProfilePicSerializer


class EmailThrottle(AnonRateThrottle):
    rate = "50/hour"  # limit to 5 requests per hour


@extend_schema(
    tags=["auth"],
    description="Verify if an email is available or not.",
)
class CheckEmailAvailabilityView(APIView):
    throttle_classes = [EmailThrottle]
    permission_classes = (AllowAny,)

    def get(self, request, email=None, format=None):
        if User.objects.filter(email=email).exists():
            return Response(
                {"email": "This email is already in use."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            {"email": "This email is available."}, status=status.HTTP_200_OK
        )


class UploadProfilePicView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        file_serializer = ProfilePicSerializer(request.user, data=request.data)

        if file_serializer.is_valid():
            file_serializer.save()
            return Response(file_serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(file_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
