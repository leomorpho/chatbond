part of 'profile_page_cubit.dart';

abstract class ProfilePageState extends Equatable {
  const ProfilePageState();

  @override
  List<Object> get props => [];
}

class ProfilePageInitial extends ProfilePageState {}

class ProfilePageLoadInProgress extends ProfilePageState {}

class ProfilePageLoadSuccess extends ProfilePageState {
  const ProfilePageLoadSuccess({
    required this.user,
    required this.allInterlocutors,
    required this.draftsCount,
    required this.waitingOnOthersQuestionCount,
    required this.waitingOnYouQuestionCount,
    required this.favoritedQuestionsCount,
    this.updateCounter = 0,
  });

  final User user;
  final List<Interlocutor> allInterlocutors;
  final int draftsCount;
  final int waitingOnOthersQuestionCount;
  final int waitingOnYouQuestionCount;
  final int favoritedQuestionsCount;
  final int updateCounter;

  ProfilePageLoadSuccess copyWith({
    User? user,
    List<Interlocutor>? allInterlocutors,
    bool? hasReachedMax,
    int? draftsCount,
    int? waitingOnOthersQuestionCount,
    int? waitingOnYouQuestionCount,
    int? favoritedQuestionsCount,
    int? updateCounter,
  }) {
    return ProfilePageLoadSuccess(
      user: user ?? this.user,
      allInterlocutors: allInterlocutors ?? this.allInterlocutors,
      draftsCount: draftsCount ?? this.draftsCount,
      waitingOnOthersQuestionCount:
          waitingOnOthersQuestionCount ?? this.waitingOnOthersQuestionCount,
      waitingOnYouQuestionCount:
          waitingOnYouQuestionCount ?? this.waitingOnYouQuestionCount,
      favoritedQuestionsCount:
          favoritedQuestionsCount ?? this.favoritedQuestionsCount,
      updateCounter: updateCounter ?? this.updateCounter,
    );
  }

  @override
  List<Object> get props => [
        user,
        allInterlocutors,
        draftsCount,
        waitingOnOthersQuestionCount,
        waitingOnYouQuestionCount,
        favoritedQuestionsCount,
        updateCounter,
      ];
}

class ProfilePageLoadFailure extends ProfilePageState {}
