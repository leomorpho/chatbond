from django.contrib import admin

from .models import ChatThread, Interlocutor, QuestionChat, QuestionThread


class InterlocutorAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "created_at",
        "updated_at",
    )


admin.site.register(Interlocutor, InterlocutorAdmin)


class ChatThreadAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "get_interlocutors",
        "get_published_question_threads_num",
        "get_unpublished_question_threads_num",
        "created_at",
        "updated_at",
    )

    def get_interlocutors(self, obj):
        return ", ".join(
            [str(interlocutor.user.email) for interlocutor in obj.interlocutors.all()]
        )

    get_interlocutors.short_description = "Interlocutors"  # Renames column head

    def get_published_question_threads_num(self, obj):
        return obj.question_threads.filter(all_interlocutors_answered=True).count()

    get_published_question_threads_num.short_description = (
        "Published Question Threads Count"
    )

    def get_unpublished_question_threads_num(self, obj):
        return obj.question_threads.filter(all_interlocutors_answered=False).count()

    get_unpublished_question_threads_num.short_description = (
        "Unpublished Question Threads Count"
    )


admin.site.register(ChatThread, ChatThreadAdmin)


class QuestionThreadAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "chat_thread",
        "question",
        "get_question_content",
        "all_interlocutors_answered",
        "created_at",
        "updated_at",
    )

    def get_question_content(self, obj):
        return obj.question.content

    get_question_content.admin_order_field = (
        "question__content"  # Allows column order sorting
    )
    get_question_content.short_description = "Question Content"  # Renames column head


admin.site.register(QuestionThread, QuestionThreadAdmin)


class QuestionChatAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "author",
        "question_thread",
        "status",
        "created_at",
        "updated_at",
    )


admin.site.register(QuestionChat, QuestionChatAdmin)
