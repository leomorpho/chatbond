from django.db import models


class EmailMetadata(models.Model):
    subject = models.CharField(max_length=255)
    event_type = models.CharField(max_length=50)
    esp_name = models.CharField(max_length=50)
    timestamp = models.DateTimeField(auto_now_add=True)
