import logging
import os
import urllib.request
import zipfile
from os.path import isfile

from django.core.files.storage import default_storage

logger = logging.getLogger()


class S3FileNotFoundError(Exception):
    """Exception raised for errors in the input.

    Attributes:
        filename -- input filename which caused the error
        message -- explanation of the error
    """

    def __init__(
        self, filename: str, message: str = "File does not exist in S3"
    ) -> None:
        self.filename = filename
        self.message = message
        super().__init__(self.message)

    def __str__(self):
        return f"{self.filename} -> {self.message}"


def download_s3_file(file_name: str, destination: str, overwrite: bool = False) -> None:
    """Downloads a file from S3 to a specific local destination.

    Args:
        file_name (str): Name of the file in S3 to download.
        destination (str): Path on local filesystem to store the downloaded file.
        overwrite (bool): If True, overwrite the local file if it already exists.

    Raises:
        S3FileNotFoundError: If the file does not exist in S3.
        FileExistsError: If the local file already exists and overwrite is False.

    Returns:
        None
    """
    # Check if the local file already exists
    if os.path.isfile(destination) and not overwrite:
        raise FileExistsError(f"The local file {destination} already exists.")

    os.makedirs(os.path.dirname(destination), exist_ok=True)

    # Check if the file exists in S3
    if default_storage.exists(file_name):
        logger.info(f"Downloading {file_name} from S3...")
        # Open the file and read its content
        with default_storage.open(file_name, "rb") as s3_file:
            data = s3_file.read()

        logger.info(
            f"Finished downloading {file_name} from S3. \
                Saving to disk at {destination}."
        )

        # Write the data to a local file
        with open(destination, "wb") as local_file:
            local_file.write(data)

    else:
        raise S3FileNotFoundError(file_name)


def upload_s3_file(file_path: str, destination: str, overwrite: bool = False) -> None:
    """Uploads a local file to a specific destination in S3.

    Args:
        file_path (str): Path of the local file to be uploaded.
        destination (str): Path in S3 where the file should be uploaded.

    Raises:
        FileNotFoundError: If the local file does not exist.

    Returns:
        None
    """
    if default_storage.exists(destination) and not overwrite:
        logger.info(
            f"not uploading file {file_path} to {destination} because that file "
            "already exists on S3 and overwrite is turned off."
        )
        return
    # Check if the local file exists
    if isfile(file_path):
        logger.info(
            f"Uploading file from {file_path} to s3 destination {destination}.."
        )

        # Open the local file and read its content
        with open(file_path, "rb") as local_file:
            data = local_file.read()

        # Write the data to a file in S3
        with default_storage.open(destination, "wb") as s3_file:
            s3_file.write(data)

    else:
        raise FileNotFoundError(f"The local file {file_path} does not exist.")
    logger.info(
        f"successfully uploaded file from {file_path} to s3 destination {destination}"
    )


def download_file(url: str, filename: str) -> None:
    """Downloads a file from a URL to a specific local destination.

    Args:
        url (str): URL of the file to download.
        filename (str): Local path where the file should be saved.

    Raises:
        ValueError: If the file can't be downloaded from the URL.

    Returns:
        None
    """
    logger.info(f"downloading file from {url} to local path {filename}...")
    try:
        urllib.request.urlretrieve(url, filename)
    except Exception as e:
        raise ValueError(f"Can't download file from {url}. Reason: {str(e)}")
    logger.info(f"successfully downloaded file from {url} to local path {filename}")


def unzip_file(zip_filepath, dest_dir):
    """Unzip a file to a specific directory.

    Args:
        zip_filepath (str): The path to the zip file to unzip.
        dest_dir (str): The directory to unzip the file to.
    """
    with zipfile.ZipFile(zip_filepath, "r") as zip_ref:
        zip_ref.extractall(dest_dir)


def delete_file(filepath):
    """Delete a file.

    Args:
        filepath (str): The path to the file to delete.
    """
    if os.path.isfile(filepath):
        os.remove(filepath)
    else:
        logger.error(f"The file {filepath} does not exist")
