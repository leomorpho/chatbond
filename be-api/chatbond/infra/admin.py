from django.contrib import admin

from .models import EmailMetadata


class EmailMetadataAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "subject",
        "event_type",
        "esp_name",
        "timestamp",
    )


admin.site.register(EmailMetadata, EmailMetadataAdmin)
