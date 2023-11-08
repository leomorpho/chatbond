import 'dart:async';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo_interface.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:loggy/loggy.dart';

class QuestionsRepo with RepoLogger implements QuestionsRepoInterface {
  QuestionsRepo({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final StreamController<QuestionVotingEvent> _questionVotingStreamController =
      StreamController<QuestionVotingEvent>.broadcast();

  Stream<QuestionVotingEvent> get questionVotingStream =>
      _questionVotingStreamController.stream;

  final StreamController<QuestionFavoritingEvent>
      _questionfavoritingStreamController =
      StreamController<QuestionFavoritingEvent>.broadcast();

  Stream<QuestionFavoritingEvent> get questionFavoritingStream =>
      _questionfavoritingStreamController.stream;

  @override
  Future<PaginatedQuestions> getFavoritedQuestions({String? pageUrl}) {
    return _apiClient.questions.getFavoritedQuestions(pageUrl: pageUrl);
  }

  @override
  Future<List<Question>> getOnboardingQuestions() async {
    return _apiClient.questions.getOnboardingQuestions();
  }

  @override
  Future<List<Question>> getQuestionsFeed() async {
    return _apiClient.questions.getQuestionsFeed();
  }

  @override
  Future<QuestionFeedWithMetadata> getHomeFeed({String? pageUrl}) async {
    return _apiClient.questions.getHomeFeed(pageUrl: pageUrl);
  }

  @override
  Future<PaginatedQuestions> searchQuestions({
    required String search,
    int numResults = 10,
    int page = 1,
  }) async {
    return _apiClient.questions
        .searchQuestions(search: search, numResults: numResults, page: page);
  }

  @override
  Future<void> markQuestionsAsSeen(List<String> questionIds) {
    return _apiClient.questions.markQuestionsAsSeen(questionIds);
  }

  @override
  Future<bool> rateQuestion(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) async {
    try {
      await _apiClient.questions.rateQuestion(questionId, newVotingStatus);

      _questionVotingStreamController.add(
        QuestionVotingEvent(
          questionId: questionId,
          oldVotingStatus: oldVotingStatus,
          newVotingStatus: newVotingStatus,
        ),
      );
      return true;
    } catch (e) {
      logError('failed to rate question with error $e');
      return false;
    }
  }

  @override
  Future<bool> favoriteQuestion(
    String questionId,
    FavoriteState favoriteState,
  ) async {
    final success =
        await _apiClient.questions.favoriteQuestion(questionId, favoriteState);

    if (success) {
      _questionfavoritingStreamController.add(
        QuestionFavoritingEvent(
          questionId: questionId,
          favoritedStatus: favoriteState,
        ),
      );
    }

    return success;
  }
}
