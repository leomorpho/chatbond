from django.contrib import admin

from .models import (
    FavouritedQuestion,
    Question,
    QuestionFeed,
    RatedQuestion,
    SearchedStrings,
    SeenQuestion,
)


class QuestionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "created_at",
        "content",
        "is_active",
        "is_private",
        "cumulative_voting_score",
        "times_voted",
        "times_answered",
    )


class SeenQuestionAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "interlocutor_id", "question_id")


class RatedQuestionAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "interlocutor_id", "question_id", "status")


class QuestionFeedAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "interlocutor_id", "consumedAt")


class FavouritedQuestionAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "interlocutor_id", "question_id")


class SearchedStringsAdmin(admin.ModelAdmin):
    list_display = ("id", "created_at", "searched_string")


admin.site.register(Question, QuestionAdmin)
admin.site.register(SeenQuestion, SeenQuestionAdmin)
admin.site.register(RatedQuestion, RatedQuestionAdmin)
admin.site.register(QuestionFeed, QuestionFeedAdmin)
admin.site.register(SearchedStrings, SearchedStringsAdmin)
