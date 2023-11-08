import datetime
import logging

import dramatiq
from django.utils import timezone

from chatbond.infra.files import download_file, upload_s3_file
from chatbond.infra.models import EmailMetadata

logger = logging.getLogger()


@dramatiq.actor
def download_to_local_and_upload_to_s3(url, local_filename, s3_filename):
    try:
        # Download the file from the URL
        download_file(url, local_filename)
    except Exception as e:
        logger.error(f"failed to download file from {url} with error {e}")
        return

    try:
        # Upload the file to S3
        upload_s3_file(local_filename, s3_filename)
    except Exception as e:
        logger.error(f"failed to upload file {local_filename} to S3 with error {e}")


@dramatiq.actor
def delete_old_email_metadata():
    threshold_date = timezone.now() - datetime.timedelta(days=30)
    EmailMetadata.objects.filter(timestamp__lt=threshold_date).delete()
