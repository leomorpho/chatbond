# Generated by Django 3.2 on 2023-10-01 23:14

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0002_historicaluser"),
    ]

    operations = [
        migrations.AddField(
            model_name="historicaluser",
            name="profile_pic",
            field=models.TextField(blank=True, default="", max_length=100),
        ),
        migrations.AddField(
            model_name="user",
            name="profile_pic",
            field=models.ImageField(blank=True, default="", upload_to="profile_pics/"),
        ),
    ]
