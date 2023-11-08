import 'package:chatbond_api/chatbond_api.dart';

abstract class QuestionsRepoInterface {
  Future<PaginatedQuestions> getFavoritedQuestions({String? pageUrl});

  Future<List<Question>> getOnboardingQuestions();

  Future<List<Question>> getQuestionsFeed();

  Future<QuestionFeedWithMetadata> getHomeFeed({String? pageUrl});

  Future<PaginatedQuestions> searchQuestions({
    required String search,
    int numResults,
    int page,
  });

  Future<void> markQuestionsAsSeen(List<String> questionIds);

  Future<bool> rateQuestion(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  );

  Future<bool> favoriteQuestion(
    String questionId,
    FavoriteState FavoriteState,
  );
}
