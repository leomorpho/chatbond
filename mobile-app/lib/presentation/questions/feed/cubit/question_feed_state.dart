part of 'question_feed_cubit.dart';

abstract class QuestionFeedState extends Equatable {
  const QuestionFeedState();

  @override
  List<Object> get props => [];
}

class QuestionFeedInitial extends QuestionFeedState {}

class QuestionFeedLoadInProgress extends QuestionFeedState {}

class QuestionFeedLoadSuccess extends QuestionFeedState {
  const QuestionFeedLoadSuccess({required this.questions});

  final List<Question> questions;

  @override
  List<Object> get props => [questions];
}

class QuestionFeedLoadFailure extends QuestionFeedState {}
