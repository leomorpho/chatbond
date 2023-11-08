part of 'multipurpose_questions_page_cubit.dart';

abstract class MultipurposeQuestionsPageState extends Equatable {
  const MultipurposeQuestionsPageState();

  @override
  List<Object> get props => [];
}

class MultipurposeQuestionsPageLoading extends MultipurposeQuestionsPageState {}

class MultipurposeQuestionsPageLoaded extends MultipurposeQuestionsPageState {
  const MultipurposeQuestionsPageLoaded({
    required this.questions,
    required this.hasReachedMax,
    this.otherInterlocutors,
    this.updateCounter = 0,
  });
  final List<Question> questions;
  final bool hasReachedMax;
  final List<Interlocutor>? otherInterlocutors;
  final int updateCounter;

  MultipurposeQuestionsPageLoaded copyWith({
    List<Question>? questions,
    bool? hasReachedMax,
    List<Interlocutor>? otherInterlocutors,
    int? updateCounter,
  }) {
    return MultipurposeQuestionsPageLoaded(
      questions: questions ?? this.questions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      otherInterlocutors: otherInterlocutors ?? this.otherInterlocutors,
      updateCounter: updateCounter ?? this.updateCounter,
    );
  }

  @override
  List<Object> get props =>
      [questions, hasReachedMax, otherInterlocutors ?? 1, updateCounter];
}

class MultipurposeQuestionsPageError extends MultipurposeQuestionsPageState {
  const MultipurposeQuestionsPageError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
