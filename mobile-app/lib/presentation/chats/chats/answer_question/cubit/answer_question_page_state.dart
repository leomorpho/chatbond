part of 'answer_question_page_cubit.dart';

abstract class AnswerQuestionPageState extends Equatable {
  const AnswerQuestionPageState({
    required this.question,
  });
  final Question question;

  @override
  List<Object?> get props => [];
}

class AnswerQuestionPageLoading extends AnswerQuestionPageState {
  const AnswerQuestionPageLoading({required super.question});
}

class AnswerQuestionPageLoaded extends AnswerQuestionPageState {
  const AnswerQuestionPageLoaded({
    required this.interlocutors,
    required this.interlocutorToDraftMap,
    this.selectedInterlocutor,
    this.cursorPosition,
    required super.question,
  });

  final List<Interlocutor>? interlocutors;
  final Map<Interlocutor, DraftQuestionThread>? interlocutorToDraftMap;
  final Interlocutor? selectedInterlocutor; // Nullable
  final int? cursorPosition; // Nullable

  @override
  List<Object?> get props => [
        interlocutors,
        interlocutorToDraftMap,
        question,
        selectedInterlocutor,
        cursorPosition,
      ];

  AnswerQuestionPageLoaded copyWith({
    List<Interlocutor>? interlocutors,
    Map<Interlocutor, DraftQuestionThread>? interlocutorToDraftMap,
    Question? question,
    Interlocutor? selectedInterlocutor,
    int? cursorPosition,
  }) {
    return AnswerQuestionPageLoaded(
      interlocutors: interlocutors ?? this.interlocutors,
      interlocutorToDraftMap:
          interlocutorToDraftMap ?? this.interlocutorToDraftMap,
      question: question ?? this.question,
      selectedInterlocutor: selectedInterlocutor ?? this.selectedInterlocutor,
      cursorPosition: cursorPosition ?? this.cursorPosition,
    );
  }
}

class AnswerQuestionPageFailed extends AnswerQuestionPageState {
  const AnswerQuestionPageFailed(
      {required super.question, required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
