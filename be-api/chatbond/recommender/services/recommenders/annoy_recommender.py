import pickle
import random
import tempfile
from os import makedirs, path
from typing import Dict, List, Set, Tuple, Union
from uuid import UUID

import numpy as np
from annoy import AnnoyIndex
from django.core.cache import cache
from django.utils.timezone import now

from chatbond.infra.files import upload_s3_file
from chatbond.recommender.constants import (ANNOY_INDEX_LOCAL_PATH,
                                            ANNOY_INDEX_TO_ID_LOCAL_PATH,
                                            ANNOY_QUESTION_INDEX_S3_FILE,
                                            ANNOY_QUESTION_INDEX_TO_ID_S3_FILE)

ANNOY_INDEX_CACHE_KEY = "annoy_index_file_content"
ANNOY_INDEX_MAP_CACHE_KEY = "annoy_index_map"
ANNOY_INDEX_DIMENSION_CACHE_KEY = "annoy_index_dimension"


class AnnoyModelBuilder:
    def __init__(self, dimension: int) -> None:
        self.dimension = dimension
        self.index = AnnoyIndex(self.dimension, "angular")
        self.index_to_id: Dict[int, UUID] = {}

    def add_item(self, index: int, item_id: UUID, vector: List[float]) -> None:
        self.index.add_item(index, vector)
        self.index_to_id[index] = item_id

    def build(self, n_trees: int = 10) -> None:
        self.index.build(n_trees)

    def save(
        self,
        annoy_index_filepath: str = ANNOY_INDEX_LOCAL_PATH,
        annoy_id_map_filepath: str = ANNOY_INDEX_TO_ID_LOCAL_PATH,
        save_to_s3: bool = False,
    ) -> None:
        makedirs(path.dirname(annoy_index_filepath), exist_ok=True)
        makedirs(path.dirname(annoy_id_map_filepath), exist_ok=True)

        # Save the index to a file.
        self.index.save(annoy_index_filepath)

        # Save the dimension and index-to-ID map to another file.
        with open(annoy_id_map_filepath, "wb") as f:
            pickle.dump((self.dimension, self.index_to_id), f)

        # Cache dimension and index-to-ID map.
        cache.set(ANNOY_INDEX_MAP_CACHE_KEY, self.index_to_id)
        cache.set(ANNOY_INDEX_DIMENSION_CACHE_KEY, self.dimension)

        # Cache the Annoy index itself.
        with open(annoy_index_filepath, "rb") as f:
            annoy_index_file_content = f.read()
        cache.set(ANNOY_INDEX_CACHE_KEY, annoy_index_file_content)

        # if save_to_s3:
        #     upload_s3_file(
        #         annoy_index_filepath,
        #         ANNOY_QUESTION_INDEX_S3_FILE,
        #         overwrite=True,
        #     )
        #     upload_s3_file(
        #         annoy_id_map_filepath,
        #         ANNOY_QUESTION_INDEX_TO_ID_S3_FILE,
        #         overwrite=True,
        #     )

    @staticmethod
    def load(
        annoy_index_filepath: str, annoy_id_map_filepath: str
    ) -> Tuple[AnnoyIndex, Dict[int, UUID]]:
        index_to_id = cache.get(ANNOY_INDEX_MAP_CACHE_KEY)
        dimension = cache.get(ANNOY_INDEX_DIMENSION_CACHE_KEY)
        if index_to_id is None or dimension is None:
            with open(annoy_id_map_filepath, "rb") as f:
                dimension, index_to_id = pickle.load(f)
            cache.set(ANNOY_INDEX_MAP_CACHE_KEY, index_to_id)
            cache.set(ANNOY_INDEX_DIMENSION_CACHE_KEY, dimension)

        annoy_index_file_content = cache.get(ANNOY_INDEX_CACHE_KEY)
        if not annoy_index_file_content:
            with open(annoy_index_filepath, "rb") as f:
                annoy_index_file_content = f.read()
            cache.set(ANNOY_INDEX_CACHE_KEY, annoy_index_file_content)

        if dimension is None:
            raise Exception("failed to load Annoy recommender")

        with tempfile.NamedTemporaryFile(delete=True) as tempf:
            tempf.write(annoy_index_file_content)
            temp_index = AnnoyIndex(dimension, "angular")
            temp_index.load(tempf.name)

        return temp_index, index_to_id


class AnnoyRecommender:
    def __init__(self) -> None:
        self._model = None
        self._load_trained_model()

    def _load_trained_model(self) -> None:
        """
        Loads the Annoy index and metadata from the filesystem.

        Note that this implementation assumes that there is a task
        that retrains a new model whenever there is the need for it.
        It is a dumb method and will simply reload the last
        model saved to file.
        """
        # Load the index
        self._model, self._index_to_external_id_mapping = AnnoyModelBuilder.load(
            ANNOY_INDEX_LOCAL_PATH, ANNOY_INDEX_TO_ID_LOCAL_PATH
        )  # super fast, will just mmap the file
        # if self._model is None or self._index_to_external_id_mapping is None:
        #     raise Exception("Failed to load Annoy index and metadata from file")

        # TODO: that is kinda disgusting so clean up one day
        self._external_id_to_index_mapping = {
            value: key for key, value in self._index_to_external_id_mapping.items()
        }

        self._model_load_time = now()

    def _convertAnnoyIndicesToExternalIds(self, annoyIndices: List[int]) -> List[UUID]:
        """
        Converts Annoy indices to external IDs.

        Args:
            annoyIndices (List[int]): Annoy indices to convert.

        Returns:
            List[UUID]: Converted external IDs.
        """
        # TODO: may eventually want to do a key check, maybe?
        return [self._index_to_external_id_mapping[i] for i in annoyIndices]

    def _convertExternalIdsToAnnoyIndices(
        self, annoyIndices: Union[List[UUID], Set[UUID]]
    ) -> List[int]:
        """
        Converts external IDs to Annoy indices.

        Args:
            externalIds (List[UUID]): External IDs to convert.

        Returns:
            List[int]: Converted Annoy indices.
        """
        # TODO: may eventually want to do a key check, maybe?
        return [self._external_id_to_index_mapping[i] for i in annoyIndices]

    def _find_nearest_to_centroid(
        self,
        embeddings: List[float],
        num_results: int = 100,
        exclude_question_annoy_indices: List[int] = [],
    ) -> List[int]:
        """
        Finds the nearest questions to the centroid of a given set of embeddings,
        excluding certain question indices.

        Args:
            embeddings (List[float]): List of embeddings.
            num_results (int): Number of results to retrieve (default: 100).
            exclude_question_annoy_indices (List[int]): List of question indices to exclude.

        Returns:
            List[int]: List of nearest question indices.
        """
        # Calculate the centroid of the embeddings
        centroid = np.mean(embeddings, axis=0)

        # Query the Annoy index
        nearest_ids = self._model.get_nns_by_vector(  # type: ignore
            centroid, num_results + len(exclude_question_annoy_indices)
        )  # extend the range by the size of excluded questions

        # Filter out the excluded indices
        nearest_ids = [
            i for i in nearest_ids if i not in exclude_question_annoy_indices
        ]

        # Trim the list to num_results
        nearest_ids = nearest_ids[:num_results]

        return nearest_ids

    @staticmethod
    def _select_random_subset(ids: List[int], num_random_questions: int) -> List[int]:
        """
        Selects a random subset from a list of IDs.

        Args:
            ids (List[int]): List of IDs.
            num_random_questions (int): Number of random questions to select.

        Returns:
            List[int]: Random subset of IDs.
        """
        random_subset_ids: List[int] = random.sample(
            ids, min(num_random_questions, len(ids))
        )
        return random_subset_ids

    def find_near_similar(
        self,
        embeddings: List[float],
        num_searched: int,
        num_rand_returned: int,
        exclude_external_id_list: Set[UUID],
    ) -> Set[UUID]:
        """
        Finds near similar questions to a given set of embeddings.

        We start off with a set of the most similar questions, and then
        downsize it randomly if required.

        Args:
            embeddings (List[float]): List of embeddings.
            num_searched (int): Number of questions to search for.
            num_rand_returned (int): Number of randomly returned questions.
            exclude_external_id_list (List[UUID]): List of external IDs to exclude.

        Returns:
            List[UUID]: List of nearest similar question external IDs.
        """
        exclude_annoy_indices_list = self._convertExternalIdsToAnnoyIndices(
            exclude_external_id_list
        )
        ids = self._find_nearest_to_centroid(
            embeddings,
            num_results=num_searched,
            exclude_question_annoy_indices=exclude_annoy_indices_list,
        )
        random_ids = self._select_random_subset(ids, num_rand_returned)
        return set(self._convertAnnoyIndicesToExternalIds(random_ids))

    def nearest_neighbors(
        self, embedding: List[float], num_results: int = 20
    ) -> List[UUID]:
        near_ids: Set[UUID] = self._model.get_nns_by_vector(  # type: ignore
            embedding, num_results
        )
        return set(self._convertAnnoyIndicesToExternalIds(near_ids))
