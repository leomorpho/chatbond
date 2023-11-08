part of 'multipurpose_question_threads_page_cubit.dart';

abstract class MultipurposeQuestionThreadsPageState extends Equatable {
  const MultipurposeQuestionThreadsPageState();

  @override
  List<Object> get props => [];
}

class MultipurposeQuestionThreadsPageLoading
    extends MultipurposeQuestionThreadsPageState {}

class MultipurposeQuestionThreadsPageLoaded
    extends MultipurposeQuestionThreadsPageState {
  const MultipurposeQuestionThreadsPageLoaded({
    required this.questionThreads,
    required this.hasReachedMax,
    required this.allInterlocutors,
    this.updateCounter = 0,
  });
  final List<QuestionThread> questionThreads;
  final bool hasReachedMax;
  final int updateCounter;
  final List<Interlocutor> allInterlocutors;

  MultipurposeQuestionThreadsPageLoaded copyWith({
    List<QuestionThread>? questionThreads,
    bool? hasReachedMax,
    List<Interlocutor>? allInterlocutors,
    int? updateCounter,
  }) {
    return MultipurposeQuestionThreadsPageLoaded(
      questionThreads: questionThreads ?? this.questionThreads,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      allInterlocutors: allInterlocutors ?? this.allInterlocutors,
      updateCounter: updateCounter ?? this.updateCounter,
    );
  }

  @override
  List<Object> get props => [
        questionThreads,
        hasReachedMax,
        allInterlocutors,
        updateCounter,
      ];
}

class MultipurposeQuestionThreadsPageError
    extends MultipurposeQuestionThreadsPageState {
  const MultipurposeQuestionThreadsPageError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
