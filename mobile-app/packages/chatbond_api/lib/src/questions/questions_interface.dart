import 'package:chatbond_api/chatbond_api.dart';

abstract class QuestionsInterface {
  Future<PaginatedQuestions> getFavoritedQuestions();

  Future<List<Question>> getOnboardingQuestions();

  Future<List<Question>> getQuestionsFeed();

  Future<PaginatedQuestions> searchQuestions({
    required String search,
    int numResults,
    int page,
  });

  Future<QuestionFeedWithMetadata> getHomeFeed({String? pageUrl});

  Future<void> markQuestionsAsSeen(List<String> questionIds);

  Future<bool> rateQuestion(String questionId, VoteStatus status);
}
