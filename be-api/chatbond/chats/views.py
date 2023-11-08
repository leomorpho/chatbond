from django.db import transaction
from django.db.models import Q, QuerySet
from django.http import Http404
from django.shortcuts import get_object_or_404
from django.utils.timezone import now
from drf_spectacular.utils import OpenApiParameter, OpenApiTypes, extend_schema

# views.py
from rest_framework import generics, mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.mixins import CreateModelMixin, DestroyModelMixin, UpdateModelMixin
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from chatbond.questions.draft_serializer import DraftQuestionThreadSerializer
from chatbond.questions.models import Question
from chatbond.realtime.dataclass import RealtimePayloadTypes, RealtimeUpdateAction
from chatbond.realtime.service import realtimeUpdateService

from .models import (
    ChatThread,
    DraftQuestionThread,
    Interlocutor,
    QuestionChat,
    QuestionThread,
)
from .permissions import IsAuthorOfQuestionChat, IsDrafterOfDraftQuestionThread
from .serializers import (
    ChatThreadSerializer,
    InterlocutorSerializer,
    QuestionChatSerializer,
    QuestionThreadSerializer,
)
from .usecase import get_unseen_question_chats, set_question_chat_seen_at_field


@extend_schema(
    tags=["Interlocutor"],
    description="Get the interlocutor object of the currently logged in user.",
)
class CurrentInterlocutorView(generics.RetrieveAPIView):
    serializer_class = InterlocutorSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        user = self.request.user
        return Interlocutor.objects.get(user=user)


@extend_schema(
    tags=["Chat Thread"],
    description="List and manage chat threads of the currently logged in interlocutor.",
)
class ChatThreadViewSet(viewsets.GenericViewSet):
    """
    ChatThreadViewSet is a view set to list and manage chat threads
    of the currently logged in interlocutor.

    Attributes:
        serializer_class (ChatThreadSerializer): Serializer class for chat threads
        permission_classes (list): List of permission classes required
            to access the view set

    Methods:
        get_queryset: Returns a queryset of chat threads filtered by
            the current interlocutor
        chat_threads_with_question_threads: Returns a queryset of chat threads
            with question threads and the count of unseen messages
    """

    serializer_class = ChatThreadSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[ChatThread]:
        """
        Returns a queryset of chat threads filtered by the current interlocutor.

        Returns:
            QuerySet: A queryset of chat threads for the current interlocutor
        """
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)

        return ChatThread.objects.filter(
            interlocutors=interlocutor
        ).with_total_unseen_messages_count(user.interlocutor)

    @action(detail=False, url_path="without-question-threads")
    def chat_threads_without_question_threads(self, request):
        queryset = self.get_queryset()

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


@extend_schema(
    tags=["Chat Thread"],
    description="List interlocutors that share a chat thread with the currently logged-in interlocutor.",
    parameters=[
        OpenApiParameter(
            name="include_self",
            type=OpenApiTypes.BOOL,
            location=OpenApiParameter.QUERY,
            description="Optional boolean parameter. If set, also returns"
            " the current interlocutor",
            required=False,
        ),
    ],
)
class ConnectedtInterlocutorViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """
    A viewset that returns interlocutors that share a chat thread with
    the currently logged in user.
    """

    permission_classes = [IsAuthenticated]
    serializer_class = InterlocutorSerializer
    pagination_class = None

    def get_queryset(self):
        """
        Returns interlocutors that share a chat thread with
        the currently logged in user.
        """
        # get interlocutor id directly from user without an extra query
        interlocutor_id = self.request.user.interlocutor.id

        # Check if "waiting-on-others" parameter is provided
        include_self = self.request.GET.get("include_self", "false").lower() == "true"

        if include_self:
            shared_interlocutors = Interlocutor.objects.filter(
                Q(chat_threads__interlocutors__id=interlocutor_id)
                | Q(id=interlocutor_id)
            )
        else:
            shared_interlocutors = Interlocutor.objects.filter(
                chat_threads__interlocutors__id=interlocutor_id
            ).exclude(id=interlocutor_id)

        return shared_interlocutors.distinct()


@extend_schema(
    tags=["Question Thread"],
    description="List and manage question threads of the currently logged in interlocutor.",
)
class QuestionThreadDetailView(RetrieveAPIView):
    queryset = QuestionThread.objects.all()
    serializer_class = QuestionThreadSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        obj = super().get_object()
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)
        if interlocutor not in obj.chat_thread.interlocutors.all():
            raise PermissionDenied("You are not part of this chat thread.")
        obj = QuestionThread.objects.with_unseen_messages_count(interlocutor).get(
            pk=obj.pk
        )
        return obj


@extend_schema(
    tags=["Question Thread"],
    description=(
        "List and manage question threads of a chat thread, answered by all "
        "interlocutors linked to it, for the currently logged in interlocutor."
    ),
)
class QuestionThreadListView(ListAPIView):
    """
    QuestionThreadListView is a view to list and paginate question threads
    of a given chat thread for the currently logged in interlocutor.
    This is for a specific ChatThread.

    Attributes:
        serializer_class (QuestionThreadSerializer): Serializer class for question threads
        permission_classes (list): List of permission classes required
            to access the view
        pagination_class: Class to manage pagination
    """

    serializer_class = QuestionThreadSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = PageNumberPagination  # Define the pagination class

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)

        chat_thread_id = self.kwargs[
            "chat_thread_id"
        ]  # Get the chat_thread_id from the URL parameters

        # Check if the ChatThread exists and belongs to the current interlocutor
        try:
            chat_thread = ChatThread.objects.filter(interlocutors=interlocutor).get(
                pk=chat_thread_id
            )
        except ChatThread.DoesNotExist:
            raise Http404

        # Get the question threads of the chat thread
        question_threads = chat_thread.question_threads.all()

        return (
            question_threads.filter(all_interlocutors_answered=True)
            .with_unseen_messages_count(interlocutor)
            .order_by("-created_at")
        )


@extend_schema(
    tags=["Question Thread"],
    description=(
        "List all question threads where the current user has a QuestionChat, "
        "but not all interlocutors have a QuestionChat yet."
    ),
    parameters=[
        OpenApiParameter(
            name="chat_thread_id",
            type=OpenApiTypes.STR,
            location=OpenApiParameter.QUERY,
            description="To set to get questions related to a"
            " specific chat thread context",
            required=False,
        ),
    ],
)
class QuestionThreadsWaitingOnOthersListView(ListAPIView):
    """
    QuestionThreadsWaitingOnOthersListView is a view to list question threads
    where the current user has a QuestionChat, but all_interlocutors_answered is False.

    Attributes:
        serializer_class (QuestionThreadSerializer): Serializer class for question threads
        permission_classes (list): List of permission classes required
            to access the view
        pagination_class: Class to manage pagination
    """

    serializer_class = QuestionThreadSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = PageNumberPagination  # Define the pagination class

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)

        # Check if "waiting-on-others" parameter is provided
        chat_thread_id = self.request.GET.get("chat_thread_id", None)

        # Get the question threads where the current user has a QuestionChat,
        # but all_interlocutors_answered is False.
        question_threads = QuestionThread.objects.all()

        if chat_thread_id:
            question_threads = QuestionThread.objects.filter(
                chat_thread_id=chat_thread_id,
            )

        return question_threads.filter(
            all_interlocutors_answered=False,
            chats__author=interlocutor,
        ).distinct()


@extend_schema(
    tags=["Question Thread"],
    description=(
        "List all question threads where there is at least one QuestionChat, "
        "but none from the current interlocutor."
    ),
    parameters=[
        OpenApiParameter(
            name="chat_thread_id",
            type=OpenApiTypes.STR,
            location=OpenApiParameter.QUERY,
            description="To set to get questions related to a specific chat thread context",
            required=False,
        ),
    ],
)
class QuestionThreadsWaitingOnCurrentUserListView(ListAPIView):
    """
    QuestionThreadsWaitingOnCurrentUserListView is a view to list question threads
    where there is at least one QuestionChat, but none from the current interlocutor.

    Attributes:
        serializer_class (QuestionThreadSerializer): Serializer class for question threads
        permission_classes (list): List of permission classes required
            to access the view
        pagination_class: Class to manage pagination
    """

    serializer_class = QuestionThreadSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = PageNumberPagination  # Define the pagination class

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)

        # Check if "chat_thread_id" parameter is provided
        chat_thread_id = self.request.GET.get("chat_thread_id", None)

        # Get the question threads where the current user has a QuestionChat,
        # but all_interlocutors_answered is False.
        # TODO: add test to ensure only chat threads linked to current user are returned
        question_threads = question_threads = QuestionThread.objects.filter(
            chat_thread__interlocutors=interlocutor
        )

        if chat_thread_id:
            question_threads = question_threads.filter(chat_thread_id=chat_thread_id)

        return (
            question_threads.exclude(
                chats__author=interlocutor,
            )
            .filter(chats__isnull=False)
            .distinct()
        )


@extend_schema(
    tags=["Draft Question Thread"],
    description="CRUD a draft question thread",
)
class DraftQuestionThreadViewSet(viewsets.ModelViewSet):
    """
    DraftQuestionThreadViewSet is a view set for performing CRUD operations on
    draft question threads.

    Attributes:
        queryset (QuerySet): QuerySet of all draft question threads
        serializer_class (DraftQuestionThreadSerializer): Serializer class
            for draft question threads
        permission_classes (list): List of permission classes required
            to access the view set

    Methods:
        get_queryset: Returns a queryset of draft question threads filtered
            by the current interlocutor
        perform_create: Creates a new draft question thread with the provided data
    """

    queryset = DraftQuestionThread.objects.all()
    serializer_class = DraftQuestionThreadSerializer
    permission_classes = [IsAuthenticated, IsDrafterOfDraftQuestionThread]

    def get_queryset(self):
        """
        Returns queryset of draft question threads filtered by the current interlocutor.

        Returns:
            QuerySet: A queryset of draft question threads for the current interlocutor
        """
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)
        return DraftQuestionThread.objects.filter(drafter=interlocutor)

    def perform_create(self, serializer):
        """
        Creates a new draft question thread with the provided data.

        Args:
            serializer (DraftQuestionThreadSerializer): Serializer instance for
                the draft question thread

        Returns:
            None
        """
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)
        chat_thread_id = self.request.data.get("chat_thread")
        question_id = self.request.data.get("question")
        content = self.request.data.get("content")

        chat_thread = ChatThread.objects.get(id=chat_thread_id)
        question = Question.objects.get(id=question_id)

        serializer.save(
            chat_thread=chat_thread,
            question=question,
            drafter=interlocutor,
            content=content,
        )

    def get_serializer_context(self):
        """
        Extra context provided to the serializer class.
        """
        return {"request": self.request}


@extend_schema(
    tags=["Draft Question Thread"],
    description="Get all draft question threads associated with a question id for the currently logged in user.",
)
class DraftQuestionThreadByQuestionView(generics.ListAPIView):
    """
    DraftQuestionThreadByQuestionView is a view to retrieve all draft question threads
    associated with a question id for the currently logged in user.

    Attributes:
        serializer_class (DraftQuestionThreadSerializer): Serializer class
            for draft question threads
        permission_classes (list): List of permission classes required to access the view
    """

    serializer_class = DraftQuestionThreadSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        """
        Returns the queryset of draft question threads associated with a question id for
            the currently logged in user.

        Returns:
            Queryset[DraftQuestionThread]: The queryset of draft question threads
        """
        user = self.request.user
        question_id = self.kwargs[
            "question_id"
        ]  # Get the question_id from the URL parameters
        interlocutor = Interlocutor.objects.get(user=user)
        return DraftQuestionThread.objects.filter(
            question__id=question_id, drafter=interlocutor
        )

    def get_serializer_context(self):
        """
        Extra context provided to the serializer class.
        """
        return {"request": self.request}


@extend_schema(
    tags=["Draft Question Thread"],
    description="Create or update a draft question thread",
)
class UpsertDraftQuestionThreadView(APIView):
    """
    UpsertDraftQuestionThreadView is an API view for creating or updating a draft question thread.

    Attributes:
        permission_classes (list): List of permission classes required
            to access the view
    """

    serializer_class = DraftQuestionThreadSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, question_id, interlocutor_id):
        """
        Creates or updates a draft question thread with the provided data.

        Args:
            request (Request): The request object containing the data to create/update the draft
            question_id (int): The ID of the question
            interlocutor_id (int): The ID of the interlocutor

        Returns:
            Response: A response object containing the serialized draft question thread or
                      an error status code
        """
        current_interlocutor = request.user.interlocutor
        target_interlocutor = get_object_or_404(Interlocutor, id=interlocutor_id)
        question = get_object_or_404(Question, id=question_id)
        content = request.data.get("content")

        # TODO: this currently supports only 2 interlocutors per chat thread
        chat_thread = get_object_or_404(
            ChatThread.objects.filter(interlocutors=current_interlocutor),
            interlocutors=target_interlocutor,
        )

        # Check if a draft has already been published for this chat_thread and question
        published_draft_exists = DraftQuestionThread.objects.filter(
            chat_thread=chat_thread,
            question=question,
            drafter=current_interlocutor,
            published_at__isnull=False,
        ).exists()

        if published_draft_exists:
            raise PermissionDenied(
                "You have already published a draft for this chat thread and question."
            )

        draft, created = DraftQuestionThread.objects.select_related(
            "chat_thread", "question", "drafter"
        ).update_or_create(
            chat_thread=chat_thread,
            question=question,
            drafter=current_interlocutor,
            defaults={"content": content},
        )

        if created:
            status_code = status.HTTP_201_CREATED
        else:
            status_code = status.HTTP_200_OK

        serializer = DraftQuestionThreadSerializer(draft, context={"request": request})

        return Response(serializer.data, status=status_code)


@extend_schema(
    tags=["Draft Question Thread"],
    description=(
        "List all Question objects related to DraftQuestionThread objects of the currently logged in interlocutor."
    ),
    parameters=[
        OpenApiParameter(
            name="chat_thread_id",
            type=OpenApiTypes.STR,
            location=OpenApiParameter.QUERY,
            description="To get questions related to a specific chat thread context",
            required=False,
        ),
    ],
)
class UserDraftQuestionListView(ListAPIView):
    """
    UserDraftQuestionListView is a view to list question objects related
    to DraftQuestionThread objects of the currently logged in interlocutor.

    Attributes:
        serializer_class (QuestionSerializer): Serializer class for questions
        permission_classes (list): List of permission classes required
            to access the view
    """

    from chatbond.questions.serializers import QuestionSerializer

    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)
        chat_thread_id = self.request.query_params.get("chat_thread_id", None)

        queryset = Question.objects.filter(
            question_threads_drafts__drafter=interlocutor,
            question_threads_drafts__published_at=None,
        ).distinct()
        if chat_thread_id:
            return queryset.filter(
                question_threads_drafts__chat_thread_id=chat_thread_id,
            )

        return queryset


@extend_schema(
    tags=["Draft Question Thread"],
    description="Publish a draft answer",
)
class PublishDraftQuestionThreadView(APIView):
    """
    PublishDraftQuestionThreadView is an API view for publishing a draft answer.

    Attributes:
        permission_classes (list): List of permission classes required
            to access the view

    Methods:
        post: Publishes a draft question thread and creates a question chat
    """

    serializer_class = DraftQuestionThreadSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, draft_id):
        """
        Publishes a draft question thread and creates a question chat.

        Args:
            request (Request): The request object containing the data to publish
            draft_id (int): The ID of the draft question thread to publish

        Returns:
            Response: A response object containing the serialized question thread or
                      an error status code
        """
        try:
            draft = DraftQuestionThread.objects.get(id=draft_id)
        except DraftQuestionThread.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        if draft.question_thread:
            return Response(status=status.HTTP_403_FORBIDDEN)
        if draft.drafter != request.user.interlocutor:
            return Response(status=status.HTTP_403_FORBIDDEN)

        if len(draft.content) == 0:
            return Response(status=status.HTTP_400_BAD_REQUEST)

        # This draft could be for either:
        # - a brand new question thread, or
        # - an existing question thread that a friend answered first.
        with transaction.atomic():
            # TODO: this atomic block is huge
            (
                question_thread,
                wasQuestionThreadCreated,
            ) = QuestionThread.objects.get_or_create(
                chat_thread=draft.chat_thread,
                question=draft.question,
            )
            QuestionChat.objects.create(
                question_thread=question_thread,
                author=draft.drafter,
                content=draft.content,
            )
            if not wasQuestionThreadCreated:
                # Check if all interlocutors in the chat_thread have a QuestionChat in the QuestionThread
                interlocutors_in_chat_thread = Interlocutor.objects.filter(
                    chat_threads=question_thread.chat_thread
                )
                interlocutors_with_chat_in_thread = Interlocutor.objects.filter(
                    question_chats__question_thread=question_thread
                )
                if set(interlocutors_in_chat_thread) == set(
                    interlocutors_with_chat_in_thread
                ):
                    question_thread.all_interlocutors_answered = True
                    question_thread.save()

            # Mark draft as published
            draft.content = ""
            draft.published_at = now()
            draft.question_thread = question_thread
            draft.save()

        question_thread_serializer = QuestionThreadSerializer(question_thread)

        # Notify other linked user who are connected
        realtimeUpdateService.publish_to_personal_channels(
            payload_type=RealtimePayloadTypes.QUESTION_THREAD,
            payload_content=question_thread_serializer.data,
            userIds=[
                p.user.id
                for p in question_thread.chat_thread.interlocutors.all()
                if p != request.user.interlocutor
            ],
            action=RealtimeUpdateAction.UPSERT,
        )

        draft_serializer = DraftQuestionThreadSerializer(
            draft, context={"request": request}
        )
        return Response(
            draft_serializer.data,
            status=status.HTTP_201_CREATED
            if wasQuestionThreadCreated
            else status.HTTP_200_OK,
        )


@extend_schema(
    tags=["Chat Thread Stats"],
    description="Retrieve in-depth stats related to the chat thread of the currently logged in interlocutor.",
    parameters=[
        OpenApiParameter(
            name="chat_thread_id",
            type=OpenApiTypes.UUID,
            description="The ID of the chat thread to get the statistics for. If not provided, statistics will be computed across all chat threads of the current user.",
            location=OpenApiParameter.PATH,
            required=False,
        )
    ],
)
class ChatThreadStats(APIView):  # TODO: not a great name...it's not really stats
    permission_classes = [IsAuthenticated]

    def get(self, request, chat_thread_id=None):
        interlocutor = Interlocutor.objects.get(user=request.user)

        # Build a dictionary with the default filter parameters
        exclude_filter_params = {"chats__isnull": False}
        include_filter_params = {}

        # If chat_thread_id is given, add it to the filter parameters
        if chat_thread_id:
            include_filter_params["chat_thread_id"] = chat_thread_id

        # Drafts count
        drafts_count = DraftQuestionThread.objects.filter(
            drafter=interlocutor,
            published_at=None,
            **include_filter_params,
        ).count()

        # QuestionThreads that have at least one associated QuestionChat from someone
        # else but not from the current interlocutor
        waiting_on_you_question_count = (
            QuestionThread.objects.filter(
                chat_thread__interlocutors=interlocutor,
                all_interlocutors_answered=False,
                **include_filter_params,
            )
            .exclude(
                **exclude_filter_params,
                chats__author=interlocutor,
            )
            .distinct()
            .count()
        )

        # QuestionThreads that have at least one associated QuestionChat from the
        # currently logged in interlocutor but has all_interlocutors_answered=False
        waiting_on_others_question_count = (
            QuestionThread.objects.filter(
                chat_thread__interlocutors=interlocutor,
                all_interlocutors_answered=False,
                chats__author=interlocutor,
                **include_filter_params,
            )
            .exclude()
            .distinct()
            .count()
        )

        if chat_thread_id:
            response_data = {
                "drafts_count": drafts_count,
                "waiting_on_others_question_count": waiting_on_others_question_count,
                "waiting_on_you_question_count": waiting_on_you_question_count,
            }
        else:
            # Favorited questions count
            favorited_questions_count = (
                Question.objects.filter(favorited_by__interlocutor=interlocutor)
                .distinct()
                .count()
            )

            response_data = {
                "drafts_count": drafts_count,
                "waiting_on_others_question_count": waiting_on_others_question_count,
                "waiting_on_you_question_count": waiting_on_you_question_count,
                "favorited_questions_count": favorited_questions_count,
            }

        return Response(response_data)


@extend_schema(
    tags=["Question Chat"],
    description="Create a question chat associated with a question thread \
        for the currenlty logged in interlocutor.",
)
class QuestionChatEditSet(
    CreateModelMixin, UpdateModelMixin, DestroyModelMixin, viewsets.GenericViewSet
):
    """
    QuestionChatEditSet is a viewset for creating, updating, and deleting question chats
    associated with a question thread for the currently logged in interlocutor.

    Note: Only the author of a question chat can use this view. To list a question
    thread with its chats, use the QuestionChatsByQuestionThreadView.

    Attributes:
        queryset (QuerySet): The queryset containing all question chat objects
        serializer_class (QuestionChatSerializer): The serializer class
            for question chats
        permission_classes (list): List of permission classes required
            to access the view

    Methods:
        perform_update: Updates a question chat if it is a draft
        perform_destroy: Deletes a question chat if it is a draft
    """

    queryset = QuestionChat.objects.all()
    serializer_class = QuestionChatSerializer

    def get_permissions(self):
        if self.action == "create":
            permission_classes = [IsAuthenticated]
        elif self.action in ["update", "partial_update"]:
            permission_classes = [
                IsAuthenticated,
                IsAuthorOfQuestionChat,
            ]
        elif self.action == "destroy":
            permission_classes = [
                IsAuthenticated,
                IsAuthorOfQuestionChat,
            ]
        else:
            permission_classes = [IsAuthenticated]

        return [permission() for permission in permission_classes]

    # TODO: add a test to check only user in thread can create chat for question_thread
    # TODO: update all IDs to be called question_thread_id. Valid for other objects
    #   too in API.
    def perform_create(self, serializer):
        chat_status = self.request.data.get("status")
        # TODO: don't hardcode constants
        if chat_status not in {"pending", "draft"}:
            return PermissionDenied

        user = self.request.user
        question_thread_id = self.request.data.get("question_thread")
        question_thread = QuestionThread.objects.get(id=question_thread_id)
        if not user.interlocutor.chat_threads.filter(
            id=question_thread.chat_thread.id
        ).exists():
            raise PermissionDenied

        interlocutor = Interlocutor.objects.get(user=self.request.user)

        if chat_status == "pending":
            serializer.save(
                author=interlocutor,
                question_thread=question_thread,
                status="published",
            )
        else:
            serializer.save(
                author=interlocutor,
                question_thread=question_thread,
                status="draft",
            )

        # Notify other linked user who are connected
        realtimeUpdateService.publish_to_personal_channels(
            payload_type=RealtimePayloadTypes.QUESTION_CHAT,
            payload_content=serializer.data,
            userIds=[
                p.user.id
                for p in question_thread.chat_thread.interlocutors.all()
                if p != self.request.user.interlocutor
            ],
            action=RealtimeUpdateAction.UPSERT,
        )

    def perform_update(self, serializer):
        """
        Updates a question chat if it is a draft.

        Args:
            serializer (QuestionChatSerializer): Serializer instance
                with the updated data

        Raises:
            PermissionDenied: If the question chat is already published
        """
        if self.get_object().status == "draft":
            serializer.save()
        else:
            raise PermissionDenied("Published QuestionChats cannot be updated.")

    def perform_destroy(self, instance):
        """
        Deletes a question chat if it is a draft.

        Args:
            instance (QuestionChat): The question chat instance to delete

        Raises:
            PermissionDenied: If the question chat is already published
        """
        # TODO: I think draft state should exist only on FE, don't even bother with it on BE
        if instance.status == "draft":
            instance.content = ""
            instance.status = "deleted"
            instance.save()
        else:
            raise PermissionDenied("Published QuestionChats cannot only be voided.")


@extend_schema(
    tags=["Question Chat"],
    description="List question chats associated with a question thread \
        for the currenlty logged in interlocutor.",
)
class QuestionChatsByQuestionThreadView(generics.ListAPIView):
    """
    QuestionChatsByQuestionThreadView is a view for listing question chats
    associated with a question thread for the currently logged in interlocutor.

    Attributes:
        serializer_class (QuestionChatSerializer): The serializer class
            for question chats
        permission_classes (list): List of permission classes required
            to access the view

    Methods:
        get_queryset: Retrieves the queryset containing question chats associated
            with a question thread for the currently logged in interlocutor
    """

    serializer_class = QuestionChatSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None  # TODO: too complicated for now

    def get_queryset(self):
        """
        QuestionChatsByQuestionThreadView is a view for listing question chats
        associated with a question thread for the currently logged in interlocutor.

        Attributes:
            serializer_class (QuestionChatSerializer): The serializer class
                for question chats
            permission_classes (list): List of permission classes required
                to access the view

        Methods:
            get_queryset: Retrieves the queryset containing question chats associated
                with a question thread (identified by its UUID) for the currently logged
                    in interlocutor
        """
        user = self.request.user
        question_thread_id = self.kwargs["question_thread_id"]
        question_thread = QuestionThread.objects.get(id=question_thread_id)

        # Check if the user is part of the chat thread
        if not user.interlocutor.chat_threads.filter(
            id=question_thread.chat_thread.id
        ).exists():
            raise PermissionDenied

        # Check if all interlocutors in associated ChatThread have a QuestionChat
        # for the relevant QuestionThread
        all_interlocutors_have_chats = question_thread.all_interlocutors_answered
        if all_interlocutors_have_chats:
            # All interlocutors have a QuestionChat, so return all chats
            queryset = QuestionChat.objects.filter(question_thread=question_thread)
        else:
            # Not all interlocutors have a QuestionChat, so return only the chats
            # authored by the current interlocutor
            queryset = QuestionChat.objects.filter(
                question_thread=question_thread,
                author=user.interlocutor,
            )

        return queryset.select_related("author", "question_thread").prefetch_related(
            "interaction_events"
        )


@extend_schema(
    tags=["Question Chat"],
    description="A client can tell the backend the interlocutor saw a set of chats",
)
class SetSeenAtForQuestionChats(APIView):
    """
    SetSeenAtForQuestionChats is a view that allows a client to notify the backend
    that the interlocutor has seen a set of chats.

    Methods:
        post: Handles the POST request to set the seen_at field for a list of
            question chat IDs
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, question_thread_id):
        """
        Handles the POST request to set the seen_at field for a list of question
        chat IDs.

        Args:
            request (Request): The request object containing the data sent by the client
            question_thread_id (int): The id of the question thread to update

        Returns:
            Response: A response object containing the status of the operation

        Raises:
            HTTP_403_FORBIDDEN: If the user is not part of the chat thread for any
                specified question chat
        """
        # Fetch Interlocutor for the authenticated user
        interlocutor = Interlocutor.objects.get(user=request.user)

        # Fetch QuestionThread with related data
        try:
            question_thread = QuestionThread.objects.get(id=question_thread_id)
        except QuestionThread.DoesNotExist:
            return Response(
                {"detail": "QuestionThread not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Check if the user is part of the ChatThread for the QuestionThread
        if interlocutor not in question_thread.chat_thread.interlocutors.all():
            raise PermissionDenied

        # Query QuestionChats with no QuestionChatInteractionEvent or seen_at is None
        question_chats = get_unseen_question_chats(interlocutor, question_thread)

        set_question_chat_seen_at_field(question_chats, interlocutor)

        return Response(
            {"detail": "seen_at has been set for the specified QuestionChats."},
            status=status.HTTP_200_OK,
        )
