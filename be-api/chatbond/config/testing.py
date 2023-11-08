import os

from .common import Common

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Testing(Common):
    DEBUG = True  # type: ignore

    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR + "/" + "db.sqlite3",
        }
    }

    PASSWORD_HASHERS = [
        "django.contrib.auth.hashers.MD5PasswordHasher",
    ]
    EMAIL_BACKEND = "django.core.mail.backends.dummy.EmailBackend"
