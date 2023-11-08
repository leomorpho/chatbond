import os

from .common import Common

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Local(Common):
    DEBUG = True  # type: ignore

    # Testing
    INSTALLED_APPS = Common.INSTALLED_APPS + (
        "drf_spectacular",
        "django_extensions",
    )  # type: ignore

    # Mail
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST = "mailhog"  # the name of the service in docker-compose file
    EMAIL_PORT = 1025

    ALLOWED_HOSTS = ["*"]
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ALLOW_CREDENTIALS = True

    CORS_ALLOW_HEADERS = (
        "content-disposition",
        "accept-encoding",
        "content-type",
        "accept",
        "origin",
        "authorization",
        "cache-control",
    )

    LOGGING = {
        "version": 1,
        "disable_existing_loggers": False,
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
            },
        },
        "root": {
            "handlers": ["console"],
            "level": "INFO",
        },
    }

    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": "redis://redis:6379/1",
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
            },
        }
    }

    QUESTION_FEED_LIFESPAN_IN_MINUTES = 100  # minutes
    TOTAL_NUM_QUESTIONS_IN_DAILY_FEED = 5
