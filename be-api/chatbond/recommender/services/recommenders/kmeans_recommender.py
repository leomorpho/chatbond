import pickle
from datetime import timedelta

from django.utils import timezone
from django.utils.timezone import now
from sklearn.cluster import KMeans

from ..tasks import KMEANS_MODEL_PATH


class SKMeansModel:
    def __init__(self) -> None:
        self._load_kmeans_model()

    def _load_kmeans_model(self) -> None:
        """
        Loads the KMeans model from the file.

        Note that this implementation assumes that there is a task
        that retrains a new model whenever there is the need for it.
        It is a dumb method and will simply reload the last
        model saved to file.
        """
        with open(KMEANS_MODEL_PATH, "rb") as infile:
            self._kmeans_model: KMeans = pickle.load(infile)
        self._kmeans_model_load_time = now()

    def _is_model_expired(self) -> bool:
        """
        Checks if the model has expired based on its load time.

        Returns:
            True if the model has expired, False otherwise.
        """
        if self._kmeans_model_load_time is None:
            return True
        expiry_time = self._kmeans_model_load_time + timedelta(hours=24)
        return timezone.now() > expiry_time

    @property
    def kmeans_model(self) -> KMeans:
        """
        Returns the KMeans model. If the model expired, it reloads it from file.

        Returns:
            The KMeans model.
        """
        if (
            self._kmeans_model is None
            or self._kmeans_model_load_time is None
            or self._is_model_expired()
        ):
            self._load_kmeans_model()
        return self._kmeans_model

    def get_closest_questions(
        self,
    ):
        pass
