from anymail.signals import tracking
from django.dispatch import receiver

from .models import EmailMetadata


# TODO: need to add a task to delete all entries that are older than x days
@receiver(tracking)
def handle_email_event(sender, event, esp_name, **kwargs):
    EmailMetadata.objects.create(
        subject=sender.subject, event_type=event.event_type, esp_name=esp_name
    )


@receiver(tracking)
def handle_click(sender, event, esp_name, **kwargs):
    if event.event_type == "clicked":
        print("Recipient %s clicked url %s" % (event.recipient, event.click_url))


@receiver(tracking)  # add weak=False if inside some other function/class
def handle_bounce(sender, event, esp_name, **kwargs):
    if event.event_type == "bounced":
        print("Message %s to %s bounced" % (event.recipient, event.recipient))


@receiver(tracking)
def handle_unsubscribe(sender, event, esp_name, **kwargs):
    if event.event_type == "complained":
        print(
            "Message %s to %s was marked as spam" % (event.message_id, event.recipient)
        )
    if event.event_type == "unsubscribed":
        print("%s unsubscribed" % (event.recipient))

    # TODO: remove from all applicable mailing list
