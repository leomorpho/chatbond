import os

from rest_framework import status
from rest_framework_simplejwt.views import TokenObtainPairView

SECONDS_IN_HOUR = 3600
COOKIE_LIFETIME = SECONDS_IN_HOUR * 24 * 28


class MyTokenObtainPairView(TokenObtainPairView):
    """
    Takes a set of user credentials and returns an access and refresh JSON web
    token pair to prove the authentication of those credentials.
    This custom implementation includes the 'sub' claim in the token.
    """

    _serializer_class = "chatbond.infra.serializers.MyTokenObtainPairSerializer"

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)

        if (
            response.status_code == status.HTTP_200_OK
        ):  # Assuming token is created successfully
            access_token = response.data.get("access")
            refresh_token = response.data.get("refresh")

            if os.getenv("DJANGO_CONFIGURATION") == "Production":
                domain = ".chatbond.app"
                secure = True
                httponly = True
            else:
                domain = None
                secure = False
                httponly = False

            response.set_cookie(
                key="access_token",
                value=access_token,
                httponly=httponly,
                samesite="None",
                domain=domain,
                secure=secure,
                max_age=COOKIE_LIFETIME,
            )
            response.set_cookie(
                key="refresh_token",
                value=refresh_token,
                httponly=httponly,
                samesite="None",
                domain=domain,
                secure=secure,
                max_age=COOKIE_LIFETIME,
            )

        return response
