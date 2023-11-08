part of 'question_threads_page_cubit.dart';

abstract class QuestionThreadsPageState extends Equatable {
  const QuestionThreadsPageState();

  @override
  List<Object> get props => [];
}

class QuestionThreadsPageLoading extends QuestionThreadsPageState {}

class QuestionThreadsPageLoaded extends QuestionThreadsPageState {
  const QuestionThreadsPageLoaded({
    required this.chatThreadId,
    required this.questionThreads,
    required this.hasReachedMax,
    required this.draftsCount,
    required this.waitingOnOthersQuestionCount,
    required this.waitingOnYouQuestionCount,
    this.updateCounter = 0,
  });
  final String chatThreadId;
  final List<QuestionThread> questionThreads;
  final bool hasReachedMax;
  final int draftsCount;
  final int waitingOnOthersQuestionCount;
  final int waitingOnYouQuestionCount;
  final int updateCounter;

  QuestionThreadsPageLoaded copyWith({
    String? chatThreadId,
    List<Interlocutor>? interlocutorsInChatThread,
    List<QuestionThread>? questionThreads,
    List<QuestionThread>? questionThreadsOnlyAnsweredByCurrUser,
    bool? hasReachedMax,
    int? updateCounter,
    int? draftsCount,
    int? waitingOnOthersQuestionCount,
    int? waitingOnYouQuestionCount,
  }) {
    return QuestionThreadsPageLoaded(
      chatThreadId: chatThreadId ?? this.chatThreadId,
      questionThreads: questionThreads ?? this.questionThreads,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      updateCounter: updateCounter ?? this.updateCounter,
      draftsCount: draftsCount ?? this.draftsCount,
      waitingOnOthersQuestionCount:
          waitingOnOthersQuestionCount ?? this.waitingOnOthersQuestionCount,
      waitingOnYouQuestionCount:
          waitingOnYouQuestionCount ?? this.waitingOnYouQuestionCount,
    );
  }

  @override
  List<Object> get props => [
        chatThreadId,
        questionThreads,
        hasReachedMax,
        updateCounter,
        draftsCount,
        waitingOnOthersQuestionCount,
        waitingOnYouQuestionCount,
      ];
}

class QuestionThreadsPageError extends QuestionThreadsPageState {
  const QuestionThreadsPageError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
