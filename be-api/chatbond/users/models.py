from typing import Union

from django.apps import apps
from django.conf import settings
from django.contrib.auth.hashers import make_password
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core import validators
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils.deconstruct import deconstructible
from django.utils.translation import gettext_lazy as _
from rest_framework.authtoken.models import Token
from simple_history.models import HistoricalRecords

from chatbond.common.models import AbstractPrimaryKey
from chatbond.recommender.tasks import create_onboarding_question_feed


class MyUserManager(BaseUserManager):
    def _create_user(
        self,
        email: Union[str, None],
        password: Union[str, None],
        name: Union[str, None],
        date_of_birth: Union[str, None],
        **extra_fields
    ):
        """
        Create and save a user with the given name, email, and password.
        """
        if not email:
            raise ValueError("The given email must be set")
        email = self.normalize_email(email)
        # Lookup the real model class from the global app registry so this
        # manager method can be used in migrations. This is fine because
        # managers are by definition working on the real model.
        apps.get_model(self.model._meta.app_label, self.model._meta.object_name)
        user = self.model(
            email=email,
            username=email,
            name=name,
            password=password,
            date_of_birth=date_of_birth,
            **extra_fields,
        )
        user.password = make_password(password)
        user.save(using=self._db)
        return user

    def create_user(
        self,
        email: str,
        name: Union[str, None] = None,
        date_of_birth: Union[str, None] = None,
        password: Union[str, None] = None,
        **extra_fields
    ):
        """
        Creates and saves a User with the given email, name, date of
        birth and password.
        """
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)

        user = self._create_user(
            email=email,
            name=name,
            password=password,
            date_of_birth=date_of_birth,
            **extra_fields,
        )
        interlocutor, _ = apps.get_model("chats", "Interlocutor").objects.get_or_create(
            user=user
        )
        # TODO: add test to verify feed gets created on user creation. For now,
        # I don't believe that's the case. Write a UT for user registration.
        create_onboarding_question_feed(interlocutor_id=interlocutor.id)

        return user

    def create_superuser(
        self, email, name=None, date_of_birth=None, password=None, **extra_fields
    ):
        """
        Creates and saves a superuser with the given email, name, date of
        birth and password.
        """
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self._create_user(
            email,
            name=name,
            password=password,
            date_of_birth=date_of_birth,
            **extra_fields,
        )


@deconstructible
class UnicodeUsernameValidator(validators.RegexValidator):
    regex = r"^[\w.@+-]+\Z"
    message = _(
        "Enter a valid username. This value may contain only letters, "
        "numbers, and @/./+/-/_ characters."
    )
    flags = 0


class User(AbstractUser, AbstractPrimaryKey):
    """
    Custom User model with email as the primary identifier, an additional
    date_of_birth field, and automatic creation of an associated Interlocutor.

    Attributes:
        id (UUID): Primary key for the user, a UUID.
        email (EmailField): The user's email address (unique).
        date_of_birth (DateField): The user's date of birth.
        objects (MyUserManager): Custom user manager for creating users and superusers.
        USERNAME_FIELD (str): Use email as the primary identifier.
        REQUIRED_FIELDS (list): A list of required fields for creating a user.
    """

    email = models.EmailField(
        verbose_name="email address",
        max_length=320,
        unique=True,
    )
    name = models.CharField(max_length=150, blank=None, null=True)
    date_of_birth = models.DateField(default=None, blank=True, null=True)
    username_validator = UnicodeUsernameValidator()

    username = models.CharField(
        _("username"),
        max_length=150,
        unique=True,
        help_text=_("150 characters or fewer. Letters, digits and @/./+/-/_ only."),
        validators=[username_validator],
        error_messages={
            "unique": _("A user with that username already exists."),
        },
        null=True,
        blank=None,
    )
    profile_pic = models.ImageField(upload_to="profile_pics/", blank=True, default="")

    history = HistoricalRecords()

    objects = MyUserManager()
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["name"]

    def __str__(self):
        return self.username


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_auth_token(sender, instance=None, created=False, **kwargs):
    if created:
        Token.objects.create(user=instance)
