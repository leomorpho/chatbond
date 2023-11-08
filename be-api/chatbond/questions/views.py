import logging

from django.db import transaction
from django.shortcuts import get_object_or_404
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, OpenApiTypes, extend_schema
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ParseError
from rest_framework.generics import ListAPIView, UpdateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.viewsets import ViewSet

from chatbond.chats.models import Interlocutor
from chatbond.questions.custom_queryset import (
    get_questions_ready_to_answer,
    get_questions_with_drafts,
)
from chatbond.questions.permissions import IsAuthorOrReadOnly
from chatbond.recommender.services.question_recommender import questionRecommender
from chatbond.recommender.tasks import (
    create_onboarding_question_feed,
    trigger_task_to_create_new_question_feeds_if_needed,
)

from .models import (
    FavouritedQuestion,
    LikedStatus,
    LikedStatusTransition,
    Question,
    QuestionFeed,
    QuestionStatusChoices,
    RatedQuestion,
    SearchedStrings,
    SeenQuestion,
)
from .serializers import (
    FavouritedQuestionHiddenSerializer,
    FavouritedQuestionSerializer,
    FavouriteQuestionActionSerializer,
    QuestionSerializer,
    RatedQuestionSerializer,
    UuidListSerializer,
)

logger = logging.getLogger()


@extend_schema(
    tags=["Questions"],
    description="CRUD questions.",
    parameters=[
        OpenApiParameter(
            name="search",
            description="Search terms",
            required=False,
            type=OpenApiTypes.STR,
        ),
        OpenApiParameter(
            name="is_favorite",
            description="Filter favorite questions",
            required=False,
            type=OpenApiTypes.BOOL,
        ),
    ],
)
class QuestionViewSet(viewsets.ModelViewSet):
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated, IsAuthorOrReadOnly]
    filter_backends = [filters.SearchFilter]
    search_fields = ["content"]

    def get_queryset(self):
        queryset = super().get_queryset()
        is_favorite = self.request.query_params.get("is_favorite", None)

        if is_favorite is not None:
            if is_favorite.lower() in ["true", "1"]:
                queryset = queryset.filter(
                    favorited_questions_events__interlocutor=self.request.user.interlocutor
                )
            elif is_favorite.lower() in ["false", "0"]:
                queryset = queryset.exclude(
                    favorited_questions_events__interlocutor=self.request.user.interlocutor
                )

        return queryset

    def perform_create(self, serializer):
        serializer.save(author=self.request.user.interlocutor)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.status != QuestionStatusChoices.PENDING and not instance.is_private:
            return Response(
                {"message": "You cannot edit this question."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)


# # TODO: I believe the below is a dead view, to verify and delete if true
# @extend_schema(
#     tags=["Favorited Questions"],
#     description="Query favorited questions.",
# )
# class FavouritedQuestionViewSet(viewsets.ReadOnlyModelViewSet):
#     serializer_class = FavouritedQuestionSerializer
#     permission_classes = [IsAuthenticated]

#     def get_queryset(self):
#         """
#         This view should return a list of all the favourited questions
#         for the currently authenticated user.
#         """
#         user = self.request.user
#         return FavouritedQuestion.objects.filter(interlocutor=user.interlocutor)


@extend_schema(
    tags=["Questions"],
    description="Query all Question objects related to favorited questions for the current user.",
    parameters=[
        OpenApiParameter(
            name="hidden",
            type=OpenApiTypes.BOOL,
            location=OpenApiParameter.QUERY,
            description="Filter by hidden field. Accepts boolean values true or false.",
            required=False,
        )
    ],
)
class QuestionsFromFavoriteQuestionsListView(ListAPIView):
    """
    UserFavoriteQuestionListView is a view to list question objects related
    to FavouritedQuestion objects of the currently logged in interlocutor.

    NOTE: this view is paginated through the ListAPIView

    Attributes:
        serializer_class (QuestionSerializer): Serializer class for questions
        permission_classes (list): List of permission classes required
            to access the view
    """

    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        interlocutor = Interlocutor.objects.get(user=user)

        hidden_filter = self.request.query_params.get("hidden", None)

        base_query = Question.objects.filter(favorited_by__interlocutor=interlocutor)

        if hidden_filter is not None:
            hidden_filter = hidden_filter.lower() in ["true", "1"]
            base_query = base_query.filter(favorited_by__hidden=hidden_filter)

        return base_query.distinct()


@extend_schema(
    tags=["Questions"],
    description="Favorite or unfavorite a question.",
    request=FavouriteQuestionActionSerializer,
)
class CreateOrUpdateFavoriteQuestionView(ViewSet):
    serializer_class = FavouritedQuestionSerializer
    permission_classes = [IsAuthenticated]
    queryset = FavouritedQuestion.objects.all()

    @action(detail=False, methods=["post"])
    def favorite(self, request, *args, **kwargs):
        serializer = FavouriteQuestionActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        question_id = serializer.validated_data.get("question_id")
        action = serializer.validated_data.get("action")
        user = request.user

        try:
            question = Question.objects.get(id=question_id)

            if action == "favorite":
                FavouritedQuestion.objects.get_or_create(
                    interlocutor=user.interlocutor,
                    question=question,
                )
                return Response(
                    {"message": "Question added to favourites successfully"},
                    status=status.HTTP_201_CREATED,
                )

            elif action == "unfavorite":
                FavouritedQuestion.objects.filter(
                    interlocutor=user.interlocutor,
                    question=question,
                ).delete()
                return Response(
                    {"message": "Question removed from favourites successfully"},
                    status=status.HTTP_200_OK,
                )

        except Question.DoesNotExist:
            return Response(
                {"error": f"Question with id {question_id} does not exist"},
                status=status.HTTP_400_BAD_REQUEST,
            )


@extend_schema(
    tags=["Questions"],
    description="Update the hidden status of a favorited question.",
)
class UpdateFavouritedQuestionHiddenView(UpdateAPIView):
    serializer_class = FavouritedQuestionHiddenSerializer
    permission_classes = [IsAuthenticated]

    def update(self, request, *args, **kwargs):
        user = request.user
        interlocutor = Interlocutor.objects.get(user=user)
        fav_question_id = kwargs.get("pk")  # Assuming the id is passed in thes URL

        fav_question = get_object_or_404(
            FavouritedQuestion, id=fav_question_id, interlocutor=interlocutor
        )

        # Verify that the current user has the permission to update
        if fav_question.interlocutor != interlocutor:
            return Response(
                {"detail": "You do not have permission to update this object."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = self.get_serializer(fav_question, data=request.data, partial=True)
        if serializer.is_valid(raise_exception=True):
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(
    tags=["Recommender"],
    description="Search for questions similar to a search string.",
    parameters=[
        OpenApiParameter(
            name="search",
            description="Search string",
            required=True,
            type=str,
        ),
        OpenApiParameter(
            name="num_results",
            description="Number of results to return",
            required=False,
            type=int,
        ),
    ],
)
class SearchQuestionViewSet(ListAPIView):
    """
    A simple ViewSet for searching for similar questions.
    """

    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]
    # throttle_classes = [ScopedRateThrottle]
    # throttle_scope = "search"  # Set to a proper throttle scope

    def get_queryset(self):
        """
        Restricts the returned questions to a given search string,
        by filtering against a `search` query parameter in the URL.
        """
        search_string = self.request.query_params.get("search", None)
        num_results = self.request.query_params.get("num_results", 20)

        if search_string is None:
            raise ParseError(detail="The search parameter is required.")

        SearchedStrings.objects.create(searched_string=search_string)

        # Embed and find nearest neighbors
        embedding = questionRecommender.embed_string(search_string)
        nearest_question_ids = questionRecommender.nearest_neighbors(
            embedding, num_results=int(num_results)
        )

        queryset = Question.objects.filter(id__in=nearest_question_ids).order_by("id")
        logger.info(f"Queryset count: {queryset.count()}")
        return queryset


@extend_schema(
    tags=["Questions"],
    description="Get home feed questions for the current user",
    # Hide the response schema as DRF fucks it up.
    # Here is what it looks like:
    # {
    #   "feed_created_at": "2023-09-16T04:00:23.187Z",
    #   "questions": [],
    #   "count": 123,
    #   "next": "http://api.example.org/accounts/?page=4",
    #   "previous": "http://api.example.org/accounts/?page=2"
    # }
    responses={},
)
class GetHomeFeed(ListAPIView):
    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.question_feed = None

    def get_queryset(self):
        """
        This view returns a mix of the following:
        - questions answered for current interlocutor not yet answered by current interlocutor
        - drafts
        - questions from the feed
        """
        user = self.request.user

        # Questions answered for current interlocutor but not yet answered by current interlocutor
        questions_to_answer_queryset = get_questions_ready_to_answer(
            user.interlocutor.id
        )

        # Random drafts
        questions_with_drafts_queryset = get_questions_with_drafts(user.interlocutor.id)

        # Questions from the feed
        self.question_feed = QuestionFeed.get_active_question_feeds_for_interlocutor(
            interlocutor_id=user.interlocutor.id, return_oldest_unconsumed=True
        )[0]
        if not self.question_feed or self.question_feed.questions.count() == 0:
            if not self.question_feed:
                logger.error(
                    "interlocutor with id {self.request.user.interlocutor.id} had "
                    "no active question feed, creating default onboarding one"
                )
            if self.question_feed and self.question_feed.questions.count() == 0:
                logger.error(
                    "interlocutor with id {self.request.user.interlocutor.id} had "
                    "a question feed with no questions, creating default onboarding one"
                )
            self.question_feed = create_onboarding_question_feed(
                interlocutor_id=self.request.user.interlocutor.id
            )
            trigger_task_to_create_new_question_feeds_if_needed()

        # To remove later, but should always be true
        assert (
            self.question_feed is not None and self.question_feed.questions.count() > 0
        )

        self.question_feed.mark_as_consumed()

        # TODO: we need the below to be a queryset for pagination
        # to work fine in django-drf
        questions_from_feed = Question.objects.filter(
            id__in=self.question_feed.questions.all().values_list("id", flat=True)
        )

        # Combine querysets and return
        all_queryset = questions_to_answer_queryset.union(
            questions_with_drafts_queryset, questions_from_feed
        )
        return all_queryset

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())

        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response_data = {
                "feed_created_at": self.question_feed.created_at.isoformat()
                if self.question_feed
                else None,
                "questions": serializer.data,
                "count": self.paginator.page.paginator.count,
                "next": self.paginator.get_next_link(),
                "previous": self.paginator.get_previous_link(),
            }
            return Response(response_data, status=status.HTTP_200_OK)


class MarkQuestionAsSeenViewSet(ViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = UuidListSerializer

    @extend_schema(
        tags=["Questions"],
        description="Set a question as seen for the current user.",
        parameters=[
            OpenApiParameter(
                name="question_ids",
                description="Question ids to mark as seen",
                required=True,
                type=OpenApiTypes.STR,
                style="form",
                explode=True,
            ),
        ],
        request=UuidListSerializer,
    )
    @action(detail=False, methods=["post"])
    def mark_as_seen(self, request):
        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        question_ids = serializer.validated_data.get("question_ids", [])
        user = request.user

        if not question_ids:
            return Response(
                {"error": "No question_ids provided"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        seen_questions = []

        for question_id in question_ids:
            try:
                question = Question.objects.get(id=question_id)
                seen_questions.append(
                    SeenQuestion(interlocutor=user.interlocutor, question=question)
                )
            except Question.DoesNotExist:
                return Response(
                    {"error": f"Question with id {question_id} does not exist"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Use a transaction to ensure all or none of the objects are created
        with transaction.atomic():
            SeenQuestion.objects.bulk_create(seen_questions)

        return Response(
            {"message": "Questions marked as seen successfully"},
            status=status.HTTP_200_OK,
        )


class RateQuestionViewset(viewsets.ModelViewSet):
    # TODO: FE is only using a boolean return value, no need
    #   to return a full RatedQuestionSerializer object
    serializer_class = QuestionSerializer
    queryset = Question.objects.all()
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=["Questions"],
        request=RatedQuestionSerializer,
        responses=bool,
        parameters=[
            OpenApiParameter(
                name="status",
                description="Status (L for liked, N for neutral, D for disliked)",
                required=True,
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
            )
        ],
    )
    @action(detail=True, methods=["post"])
    def rate(self, request, pk=None):
        question = self.get_object()
        interlocutor = request.user.interlocutor

        new_rating_status = request.data.get("status")
        if new_rating_status not in dict(LikedStatus.choices):
            return Response(
                {
                    "error": (
                        "Invalid status. Must be either 'L' for liked, "
                        "'N' for neutral or 'D' for disliked."
                    )
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        rated_question, created = RatedQuestion.objects.get_or_create(
            interlocutor=interlocutor,
            question=question,
            defaults={"status": new_rating_status},
        )
        serializer = self.get_serializer(question)
        if not created:
            if LikedStatusTransition.is_valid_transition(
                rated_question.status, new_rating_status
            ):
                rated_question.status = new_rating_status
                rated_question.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            else:
                return Response(
                    {
                        "error": "Invalid status transition. Check the allowed transitions."
                    },
                    status=status.HTTP_409_CONFLICT,
                )
        return Response(serializer.data, status=status.HTTP_201_CREATED)
