part of 'home_feed_cubit.dart';

abstract class HomeFeedState extends Equatable {
  const HomeFeedState();

  @override
  List<Object> get props => [];
}

class HomeFeedLoading extends HomeFeedState {}

class HomeFeedLoaded extends HomeFeedState {
  const HomeFeedLoaded({
    required this.questions,
    required this.hasReachedMax,
    required this.feedGenerationDatetime,
    this.allConnectedInterlocutors,
    this.updateCounter = 0,
  });
  final List<Question> questions;
  final bool hasReachedMax;
  final DateTime feedGenerationDatetime;

  final List<Interlocutor>? allConnectedInterlocutors;
  final int updateCounter;

  HomeFeedLoaded copyWith({
    List<Question>? questions,
    bool? hasReachedMax,
    DateTime? feedGenerationDatetime,
    List<Interlocutor>? allConnectedInterlocutors,
    int? updateCounter,
  }) {
    return HomeFeedLoaded(
      questions: questions ?? this.questions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      feedGenerationDatetime:
          feedGenerationDatetime ?? this.feedGenerationDatetime,
      allConnectedInterlocutors:
          allConnectedInterlocutors ?? this.allConnectedInterlocutors,
      updateCounter: updateCounter ?? this.updateCounter,
    );
  }

  @override
  List<Object> get props =>
      [questions, hasReachedMax, updateCounter, feedGenerationDatetime];
}

class HomeFeedError extends HomeFeedState {
  const HomeFeedError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
