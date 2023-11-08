from django.contrib import admin

from .models import Invitation


class InvitationAdmin(admin.ModelAdmin):
    list_display = (
        "inviter",
        "invitee_name",
        "token",
        "accepted_at",
        "created_at",
        "updated_at",
    )


admin.site.register(Invitation, InvitationAdmin)
