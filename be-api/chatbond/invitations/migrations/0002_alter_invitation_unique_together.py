# Generated by Django 3.2 on 2023-09-09 15:04

from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("chats", "0005_questionthread_all_interlocutors_answered"),
        ("invitations", "0001_initial"),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name="invitation",
            unique_together={("inviter", "invitee_name")},
        ),
    ]
