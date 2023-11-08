from django.core.exceptions import ValidationError
from rest_framework import permissions

from .models import Interlocutor, QuestionThread


class IsInterlocutorInChatThread(permissions.BasePermission):
    def has_permission(self, request, view):
        question_thread_id = view.kwargs["question_thread_id"]
        question_thread = QuestionThread.objects.get(id=question_thread_id)
        user = request.user

        if not user.is_authenticated:
            return False

        try:
            interlocutor = Interlocutor.objects.get(user=user)
            return interlocutor in question_thread.chat_thread.interlocutors.all()
        except (Interlocutor.DoesNotExist, ValidationError):
            return False


class IsAuthorOfQuestionChat(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return obj.author == request.user.interlocutor
        return False


class IsDrafterOfDraftQuestionThread(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.user.is_authenticated:
            return request.user == obj.drafter.user
        return False
