from rest_framework import permissions


class IsAuthorOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow authors of an object to edit or delete it.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions are only allowed to the author of the question.
        return obj.author == request.user.interlocutor


class IsOwner(permissions.BasePermission):
    """
    Custom permission to only allow owners of a QuestionFeed to see it.
    """

    def has_object_permission(self, request, view, obj):
        return obj.interlocutor.user == request.user
