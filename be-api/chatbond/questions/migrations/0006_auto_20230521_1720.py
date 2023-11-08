# Generated by Django 3.2 on 2023-05-21 17:20

from django.db import migrations, models
import django.db.models.deletion
import pgvector.django
import taggit.managers
import uuid


class Migration(migrations.Migration):
    dependencies = [
        ("contenttypes", "0002_remove_content_type_name"),
        ("chats", "0003_historicalquestionchat"),
        ("taggit", "0005_auto_20220424_2025"),
        ("questions", "0005_add_pgvector_extension"),
    ]

    operations = [
        migrations.CreateModel(
            name="FavouritedQuestion",
            fields=[
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                (
                    "interlocutor",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="questions_favorited_by",
                        to="chats.interlocutor",
                    ),
                ),
            ],
            options={
                "abstract": False,
            },
        ),
        migrations.CreateModel(
            name="QuestionTag",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "object_id",
                    models.UUIDField(db_index=True, verbose_name="object ID"),
                ),
                (
                    "content_type",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="questions_questiontag_tagged_items",
                        to="contenttypes.contenttype",
                        verbose_name="content type",
                    ),
                ),
                (
                    "tag",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="questions_questiontag_items",
                        to="taggit.tag",
                    ),
                ),
            ],
            options={
                "verbose_name": "Tag",
                "verbose_name_plural": "Tags",
            },
        ),
        migrations.CreateModel(
            name="RatedQuestion",
            fields=[
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                (
                    "status",
                    models.CharField(
                        choices=[("L", "Liked"), ("D", "Disliked")],
                        default="L",
                        max_length=1,
                    ),
                ),
                (
                    "interlocutor",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="rated_questions",
                        to="chats.interlocutor",
                    ),
                ),
            ],
            options={
                "abstract": False,
            },
        ),
        migrations.CreateModel(
            name="SeenQuestion",
            fields=[
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                (
                    "interlocutor",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="questions_seen_by",
                        to="chats.interlocutor",
                    ),
                ),
            ],
            options={
                "abstract": False,
            },
        ),
        migrations.AlterUniqueTogether(
            name="questionlikedevent",
            unique_together=None,
        ),
        migrations.RemoveField(
            model_name="questionlikedevent",
            name="interlocutor",
        ),
        migrations.RemoveField(
            model_name="questionlikedevent",
            name="question",
        ),
        migrations.AddField(
            model_name="historicalquestion",
            name="embedding_all_mini_lml6v2",
            field=pgvector.django.VectorField(blank=None, dimensions=384, null=True),
        ),
        migrations.AddField(
            model_name="historicalquestion",
            name="embedding_all_mpnet_base_v2",
            field=pgvector.django.VectorField(blank=None, dimensions=768, null=True),
        ),
        migrations.AddField(
            model_name="question",
            name="embedding_all_mini_lml6v2",
            field=pgvector.django.VectorField(blank=None, dimensions=384, null=True),
        ),
        migrations.AddField(
            model_name="question",
            name="embedding_all_mpnet_base_v2",
            field=pgvector.django.VectorField(blank=None, dimensions=768, null=True),
        ),
        migrations.DeleteModel(
            name="QuestionFavoriteEvent",
        ),
        migrations.DeleteModel(
            name="QuestionLikedEvent",
        ),
        migrations.AddField(
            model_name="seenquestion",
            name="question",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="seen_by",
                to="questions.question",
            ),
        ),
        migrations.AddField(
            model_name="ratedquestion",
            name="question",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="ratings",
                to="questions.question",
            ),
        ),
        migrations.AddField(
            model_name="favouritedquestion",
            name="question",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="favorited_by",
                to="questions.question",
            ),
        ),
        migrations.AddField(
            model_name="favouritedquestion",
            name="target_interlocutors",
            field=models.ManyToManyField(
                related_name="targeted_questions", to="chats.Interlocutor"
            ),
        ),
        migrations.AlterField(
            model_name="question",
            name="tags",
            field=taggit.managers.TaggableManager(
                help_text="A comma-separated list of tags.",
                through="questions.QuestionTag",
                to="taggit.Tag",
                verbose_name="Tags",
            ),
        ),
        migrations.AlterUniqueTogether(
            name="seenquestion",
            unique_together={("interlocutor", "question")},
        ),
        migrations.AlterUniqueTogether(
            name="ratedquestion",
            unique_together={("interlocutor", "question")},
        ),
        migrations.AlterUniqueTogether(
            name="favouritedquestion",
            unique_together={("interlocutor", "question")},
        ),
    ]
