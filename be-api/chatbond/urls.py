import os

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path, reverse_lazy
from django.views.generic.base import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.routers import DefaultRouter

from chatbond.chats.views import (
    ChatThreadStats,
    ChatThreadViewSet,
    ConnectedtInterlocutorViewSet,
    CurrentInterlocutorView,
    DraftQuestionThreadByQuestionView,
    DraftQuestionThreadViewSet,
    PublishDraftQuestionThreadView,
    QuestionChatEditSet,
    QuestionChatsByQuestionThreadView,
    QuestionThreadDetailView,
    QuestionThreadListView,
    QuestionThreadsWaitingOnCurrentUserListView,
    QuestionThreadsWaitingOnOthersListView,
    SetSeenAtForQuestionChats,
    UpsertDraftQuestionThreadView,
    UserDraftQuestionListView,
)
from chatbond.infra.views import MyTokenObtainPairView
from chatbond.invitations.views import (
    AcceptInvitationAPIView,
    CreateInvitationView,
    InvitationViewSet,
)
from chatbond.questions.views import (
    CreateOrUpdateFavoriteQuestionView,
    # FavouritedQuestionViewSet,
    GetHomeFeed,
    MarkQuestionAsSeenViewSet,
    QuestionsFromFavoriteQuestionsListView,
    QuestionViewSet,
    RateQuestionViewset,
    SearchQuestionViewSet,
    UpdateFavouritedQuestionHiddenView,
)
from chatbond.users.views import CheckEmailAvailabilityView, UploadProfilePicView

router = DefaultRouter()
router.register(r"chat-threads", ChatThreadViewSet, basename="chat-threads")
router.register(
    r"chat-interlocutors", ConnectedtInterlocutorViewSet, basename="chat-interlocutors"
)

router.register(r"invitations", InvitationViewSet, basename="invitations")
router.register(
    r"draft-question-threads",
    DraftQuestionThreadViewSet,
    basename="drafts-question-threads",
)
router.register(r"question-chats", QuestionChatEditSet, basename="question-chats")
router.register(r"questions", QuestionViewSet, basename="questions")
# router.register(r"favorites", FavouritedQuestionViewSet, basename="favorited-question")
router.register(
    r"edit-favorites",
    CreateOrUpdateFavoriteQuestionView,
    basename="edit-favorited-question",
)
router.register(
    r"mark-question-as-seen",
    MarkQuestionAsSeenViewSet,
    basename="mark-question-as-seen",
)
router.register(r"questions", RateQuestionViewset, basename="rate-question")


api_v1_patterns = [
    path("", include(router.urls)),
    path(
        "create-invitation/", CreateInvitationView.as_view(), name="create-invitation"
    ),
    path(
        "invitations/accept/<str:token>/",
        AcceptInvitationAPIView.as_view(),
        name="accept-invitation",
    ),
    path(
        "draft-question-threads/get/<uuid:question_id>/",
        DraftQuestionThreadByQuestionView.as_view(),
        name="draft-question-thread-by-question",
    ),
    path(
        "draft-question-threads-all/",
        UserDraftQuestionListView.as_view(),
        name="draft-question-threads-for-user",
    ),
    path(
        "draft-question-threads/<uuid:question_id>/<uuid:interlocutor_id>/upsert/",
        UpsertDraftQuestionThreadView.as_view(),
        name="upsert-draft-question-thread",
    ),
    path(
        "draft-question-threads/<uuid:draft_id>/publish/",
        PublishDraftQuestionThreadView.as_view(),
        name="publish-draft-question-thread",
    ),
    path(
        "question-threads/<uuid:question_thread_id>/chats/",
        QuestionChatsByQuestionThreadView.as_view(),
        name="question-chats-by-thread",
    ),
    path(
        "question-threads/<uuid:pk>/",
        QuestionThreadDetailView.as_view(),
        name="questionthread-detail",
    ),
    path(
        "set-seen-at/<uuid:question_thread_id>/",
        SetSeenAtForQuestionChats.as_view(),
        name="set-seen-at-for-question-chats",
    ),
    path(
        "interlocutors/me/",
        CurrentInterlocutorView.as_view(),
        name="current-interlocutor",
    ),
    path(
        "search-questions/",
        SearchQuestionViewSet.as_view(),
        name="search-questions",
    ),
    path(
        "home-feed/",
        GetHomeFeed.as_view(),
        name="home-feed",
    ),
    path(
        "chat-threads/<uuid:chat_thread_id>/question-threads/",
        QuestionThreadListView.as_view(),
        name="chat-thread-question-threads",
    ),
    path(
        "waiting-on-others-question-threads/",
        QuestionThreadsWaitingOnOthersListView.as_view(),
        name="waiting-on-others-question-threads",
    ),
    path(
        "waiting-on-you-question-threads/",
        QuestionThreadsWaitingOnCurrentUserListView.as_view(),
        name="waiting-on-you-question-threads",
    ),
    path(
        "favorite-questions/",
        QuestionsFromFavoriteQuestionsListView.as_view(),
        name="favorite-questions-for-user",
    ),
    path(
        "favorite-questions/<int:pk>/update-hidden/",
        UpdateFavouritedQuestionHiddenView.as_view(),
        name="update-hidden",
    ),
    path(
        "chat-thread-stats/<uuid:chat_thread_id>/",
        ChatThreadStats.as_view(),
        name="chat-thread-stats",
    ),
    path(
        "chat-thread-stats/",
        ChatThreadStats.as_view(),
        name="all-chat-threads-stats",
    ),
    path(
        "check-email/<str:email>/",
        CheckEmailAvailabilityView.as_view(),
        name="check-email",
    ),
    path(
        "upload_profile_pic/", UploadProfilePicView.as_view(), name="upload_profile_pic"
    ),
]

urlpatterns = [
    re_path(r"^$", RedirectView.as_view(url=reverse_lazy("api-root"), permanent=False)),
    path("auth/jwt/create/", MyTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path(r"auth/", include("djoser.urls")),
    path(r"auth/", include("djoser.urls.jwt")),
    path("anymail/", include("anymail.urls")),
    path("api/v1/", include(api_v1_patterns)),
    path("api-auth/", include("rest_framework.urls", namespace="rest_framework")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

if os.getenv("DJANGO_ADMIN_OBFUSCATION_URL"):
    # Obfuscate django admin panel for security
    admin_url = os.getenv("DJANGO_ADMIN_OBFUSCATION_URL")
    if admin_url is None:
        raise Exception("DJANGO_ADMIN_OBFUSCATION_URL should be set in production")
    urlpatterns += [
        path(f"{admin_url}/admin/", admin.site.urls),
        path(f"{admin_url}/admin/django-ses/", include("django_ses.urls")),
    ]
else:
    urlpatterns += [
        # Don't obfuscare admin panel in dev mode
        path("admin/", admin.site.urls),
        path("admin/django-ses/", include("django_ses.urls")),
        # Do not include API in prod
        path("api/schema/", SpectacularAPIView.as_view(), name="api-schema"),
        path(
            "api/docs/",
            SpectacularSwaggerView.as_view(url_name="api-schema"),
            name="api-docs",
        ),
    ]
