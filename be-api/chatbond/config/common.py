import os
from datetime import timedelta
from distutils.util import strtobool
from os.path import join
from typing import List

import dj_database_url
from configurations import Configuration

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Common(Configuration):
    SITE_NAME = "Chatbond"
    DOMAIN = "localhost:6060"  # Used by djoser for emails

    INSTALLED_APPS = (
        "django.contrib.admin",
        "django.contrib.auth",
        "django.contrib.contenttypes",
        "django.contrib.sessions",
        "django.contrib.messages",
        "django.contrib.staticfiles",
        # Third party apps
        "rest_framework",  # utilities for rest apis
        "rest_framework.authtoken",  # token authentication
        # "django_filters",  # for filtering rest endpoints
        "djoser",  # for auth
        "corsheaders",
        "taggit",
        "simple_history",
        "django_dramatiq",
        "django_apscheduler",
        "django_ses",
        # Your apps
        "chatbond.users",
        "chatbond.chats",
        "chatbond.common",
        "chatbond.questions",
        "chatbond.invitations",
        "chatbond.commands",
        "chatbond.recommender",
        "chatbond.apscheduler",
        "chatbond.realtime",
        "chatbond.infra",
    )

    # https://docs.djangoproject.com/en/2.0/topics/http/middleware/
    MIDDLEWARE = (
        "corsheaders.middleware.CorsMiddleware",
        "django.middleware.common.CommonMiddleware",
        "django.middleware.security.SecurityMiddleware",
        "django.contrib.sessions.middleware.SessionMiddleware",
        "django.middleware.csrf.CsrfViewMiddleware",
        "django.contrib.auth.middleware.AuthenticationMiddleware",
        "django.contrib.messages.middleware.MessageMiddleware",
        "django.middleware.clickjacking.XFrameOptionsMiddleware",
        "simple_history.middleware.HistoryRequestMiddleware",
    )
    SESSION_COOKIE_HTTPONLY = True
    ALLOWED_HOSTS = ["*"]  # TODO: to change for prod?
    ROOT_URLCONF = "chatbond.urls"
    SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
    WSGI_APPLICATION = "chatbond.wsgi.application"

    # Email
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"

    ADMINS = (("Author", "leonard.audibert@gmail.com"),)

    POSTGRES_HOST = os.getenv("POSTGRES_HOST", "chatbond")
    POSTGRES_PORT = os.getenv("POSTGRES_PORT", 5432)
    POSTGRES_DATABASE = os.getenv("POSTGRES_DATABASE", "chatbond")
    POSTGRES_USER = os.getenv("POSTGRES_USER", "chatbond")
    POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "password")

    DATABASE_URL = f"postgres://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DATABASE}"

    DATABASES = {
        "default": dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=int(os.getenv("POSTGRES_CONN_MAX_AGE", 600)),
        )
    }

    # General
    APPEND_SLASH = False
    TIME_ZONE = "UTC"
    LANGUAGE_CODE = "en-us"
    # If you set this to False, Django will make some optimizations so as not
    # to load the internationalization machinery.
    USE_I18N = False
    USE_L10N = True
    USE_TZ = True
    LOGIN_REDIRECT_URL = "/"

    # Static files (CSS, JavaScript, Images)
    # https://docs.djangoproject.com/en/2.0/howto/static-files/
    STATIC_ROOT = os.path.normpath(join(os.path.dirname(BASE_DIR), "static"))
    STATICFILES_DIRS: List[str] = []
    STATIC_URL = "/static/"
    STATICFILES_FINDERS = (
        "django.contrib.staticfiles.finders.FileSystemFinder",
        "django.contrib.staticfiles.finders.AppDirectoriesFinder",
    )

    # Media files
    MEDIA_ROOT = join(os.path.dirname(BASE_DIR), "media")
    MEDIA_URL = "/media/"

    TEMPLATES = [
        {
            "BACKEND": "django.template.backends.django.DjangoTemplates",
            "DIRS": STATICFILES_DIRS,
            "APP_DIRS": True,
            "OPTIONS": {
                "context_processors": [
                    "django.template.context_processors.debug",
                    "django.template.context_processors.request",
                    "django.contrib.auth.context_processors.auth",
                    "django.contrib.messages.context_processors.messages",
                ],
            },
        },
    ]

    DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

    # Set DEBUG to False as a default for safety
    # https://docs.djangoproject.com/en/dev/ref/settings/#debug
    DEBUG = strtobool(os.getenv("DJANGO_DEBUG", "no"))

    # Password Validation
    # https://docs.djangoproject.com/en/2.0/topics/auth/passwords/#module-django.contrib.auth.password_validation
    AUTH_PASSWORD_VALIDATORS = [
        {
            "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
        },
        {
            "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        },
        {
            "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
        },
        {
            "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
        },
    ]

    # Custom user app
    AUTH_USER_MODEL = "users.User"

    # Django Rest Framework
    REST_FRAMEWORK = {
        "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
        "PAGE_SIZE": int(os.getenv("DJANGO_PAGINATION_LIMIT", 10)),
        "DATETIME_FORMAT": "%Y-%m-%dT%H:%M:%S%z",
        "DEFAULT_RENDERER_CLASSES": (
            "rest_framework.renderers.JSONRenderer",
            "rest_framework.renderers.BrowsableAPIRenderer",
        ),
        "DEFAULT_PERMISSION_CLASSES": [
            "rest_framework.permissions.IsAuthenticated",
        ],
        "DEFAULT_AUTHENTICATION_CLASSES": (
            # "rest_framework.authentication.SessionAuthentication",
            # "rest_framework.authentication.TokenAuthentication",
            "rest_framework_simplejwt.authentication.JWTAuthentication",
        ),
        "DEFAULT_VERSIONING_CLASS": "rest_framework.versioning.NamespaceVersioning",
        "DEFAULT_VERSION": "v1",
        "ALLOWED_VERSIONS": ["v1"],
        "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
        "DEFAULT_THROTTLE_CLASSES": [
            "rest_framework.throttling.AnonRateThrottle",
            "rest_framework.throttling.UserRateThrottle",
        ],
        "DEFAULT_THROTTLE_RATES": {
            "anon": "10000/hour",
            "user": "100000/hour",
            "invitation_accept": "15000/hour",
            "search": "120000/hour",
            # TODO: reinstate below for production
            # "anon": "100/hour",
            # "user": "1000/hour",
            # "invitation_accept": "15/hour",
            # "search": "120/hour",
        },
    }

    SPECTACULAR_SETTINGS = {
        "TITLE": "Your Project API",
        "DESCRIPTION": "Your project description",
        "VERSION": "1.0.0",
        "SERVE_INCLUDE_SCHEMA": False,
        # OTHER SETTINGS
    }

    SESSION_EXPIRE_AT_BROWSER_CLOSE = False

    # Auth: https://djoser.readthedocs.io/en/latest/settings.html
    DJOSER = {
        "HIDE_USERS": True,
        "LOGIN_FIELD": "email",
        "SEND_ACTIVATION_EMAIL": True,
        "SEND_CONFIRMATION_EMAIL": False,
        "ACTIVATION_URL": "#/activate/{uid}/{token}",  # TODO
        "PASSWORD_RESET_SHOW_EMAIL_NOT_FOUND": False,
        "PASSWORD_RESET_CONFIRM_URL": "#/password-reset/{uid}/{token}",  # TODO
        # "USERNAME_RESET_CONFIRM_URL": "#/username-reset/{uid}/{token}",  # TODO
        "EMAIL": {
            "activation": "chatbond.infra.email.ActivationEmail",
            "confirmation": "chatbond.infra.email.ConfirmationEmail",
            "password_reset": "chatbond.infra.email.PasswordResetEmail",
            "password_changed_confirmation": "chatbond.infra.email.PasswordChangedConfirmationEmail",
            # "username_changed_confirmation": "djoser.email.UsernameChangedConfirmationEmail", # TODO
            # "username_reset": "djoser.email.UsernameResetEmail",
        },
        "SERIALIZERS": {
            "user": "chatbond.users.serializers.UserSerializer",
        },
    }

    INVITATION_URL = "#/auth/people/invite/{token}"

    DRAMATIQ_BROKER = {
        "BROKER": "dramatiq.brokers.rabbitmq.RabbitmqBroker",
        "OPTIONS": {
            "url": "amqp://rabbitmq:5672",
        },
        "MIDDLEWARE": [
            "dramatiq.middleware.Pipelines",
            "dramatiq.middleware.Prometheus",
            "dramatiq.middleware.AgeLimit",
            "dramatiq.middleware.TimeLimit",
            "dramatiq.middleware.Callbacks",
            "dramatiq.middleware.Retries",
            "django_dramatiq.middleware.DbConnectionsMiddleware",
            "django_dramatiq.middleware.AdminMiddleware",
        ],
    }

    # Defines which database should be used to persist Task objects when the
    # AdminMiddleware is enabled.  The default value is "default".
    DRAMATIQ_TASKS_DATABASE = "default"

    S3_ACCESS_KEY_ID = os.getenv("S3_ACCESS_KEY_ID")
    S3_SECRET_ACCESS_KEY = os.getenv("S3_SECRET_ACCESS_KEY")
    AWS_STORAGE_BUCKET_NAME = "chatbondml"  # TODO: need to separate dev and prod for S3
    AWS_S3_REGION_NAME = "us-east-2"
    AWS_S3_FILE_OVERWRITE = True
    AWS_DEFAULT_ACL = None

    DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
    STATICFILES_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"

    SIMPLE_JWT = {
        "AUTH_HEADER_TYPES": ("Bearer"),
        "ALGORITHM": "HS256",
        # TODO: this is for testing, to make sure that the FE correctly
        #  refreshes tokens. Set to 15min long-term.
        "ACCESS_TOKEN_LIFETIME": timedelta(
            minutes=int(os.getenv("ACCESS_TOKEN_LIFETIME", 15))
        ),
        "REFRESH_TOKEN_LIFETIME": timedelta(
            days=int(os.getenv("REFRESH_TOKEN_LIFETIME", 21))
        ),
        "ROTATE_REFRESH_TOKENS": True,
        "BLACKLIST_AFTER_ROTATION": True,
        "SIGNING_KEY": os.getenv("CENTRIFUGO_TOKEN_SECRET"),
        "TOKEN_OBTAIN_SERIALIZER": "infra.serializers.MyTokenObtainPairSerializer",
    }

    TOTAL_NUM_QUESTIONS_IN_DAILY_FEED = 15
    QUESTION_FEED_LIFESPAN_IN_MINUTES = 60 * 24  # minutes , i.e. 1 day
    FORGET_SEEN_QUESTION_LIFESPAN_IN_DAYS = 30
