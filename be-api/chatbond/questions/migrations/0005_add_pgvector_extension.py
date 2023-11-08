from django.db import migrations
from pgvector.django import VectorExtension


class Migration(migrations.Migration):
    dependencies = [
        # replace 'questions' with the actual name of your app
        ("questions", "0004_auto_20230512_1951"),
    ]

    operations = [VectorExtension()]
