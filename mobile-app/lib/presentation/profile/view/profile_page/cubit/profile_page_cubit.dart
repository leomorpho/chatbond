import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/data/repositories/user_repo/user_repo.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:loggy/loggy.dart';

part 'profile_page_state.dart';

class ProfilePageCubit extends Cubit<ProfilePageState> {
  ProfilePageCubit(
    this._userRepository,
    this._chatsRepo,
    this._questionsRepo,
    this._notificationCountStream,
  ) : super(ProfilePageInitial()) {
    fetchUser();
    // TODO: no need to pass any repos to this page, use service locator instead
    _questionFavoritingEvent = _questionsRepo.questionFavoritingStream
        .listen((favoritingQuestionEvent) {
      _updateFavoritedStatus(
        favoritingQuestionEvent.favoritedStatus!,
      );
    });
    _draftCreatedEventSubscription =
        _chatsRepo.draftCreatedStream.listen(_updateNumDraftsInProgress);
    _draftPublishedEventSubscription =
        _chatsRepo.draftPublishedStream.listen(_updateNumDraftPublished);
    _draftDeleteEventSubscription =
        _chatsRepo.draftDeletedStream.listen(_decrementNumDrafts);

    _notificationCountSubscription =
        _notificationCountStream.listen(_refreshChatThreadStats);

    _currUserUpdatesSubscription =
        _userRepository.userUpdatesStream.listen(_updateCurrUser);
  }

  final UserRepo _userRepository;
  final ChatThreadsRepo _chatsRepo;
  final QuestionsRepo _questionsRepo;

  /// When the total notif count changes, a new query to get stats is triggered,
  /// which will refresh the profile page. Not super intuitive mechanism.
  /// TODO: improve the above
  final Stream<int> _notificationCountStream;

  StreamSubscription<QuestionFavoritingEvent>? _questionFavoritingEvent;
  StreamSubscription<DraftCreatedEvent>? _draftCreatedEventSubscription;
  StreamSubscription<DraftPublishedEvent>? _draftPublishedEventSubscription;
  StreamSubscription<DraftDeleteEvent>? _draftDeleteEventSubscription;

  late StreamSubscription<int> _notificationCountSubscription;
  late StreamSubscription<User> _currUserUpdatesSubscription;

  Future<void> fetchUser() async {
    emit(ProfilePageLoadInProgress());

    final userResult = getIt.get<GlobalState>().currUser;
    if (userResult == null) {
      throw Exception('user should be set before getting to the profile page');
    }
    final allInterlocutors =
        await _chatsRepo.getChatInterlocutors(includeSelf: true);

    final stats = await _chatsRepo.getChatThreadStats();

    emit(
      ProfilePageLoadSuccess(
        user: userResult,
        allInterlocutors: allInterlocutors,
        draftsCount: stats.draftsCount,
        waitingOnOthersQuestionCount: stats.waitingOnOthersQuestionCount,
        waitingOnYouQuestionCount: stats.waitingOnYouQuestionCount,
        favoritedQuestionsCount: stats.favoritedQuestionsCount!,
      ),
    );
  }

  Future<void> saveName(String newName) async {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;

      final updatedUser = oldState.user.copyWith(name: newName);
      try {
        await _userRepository.updateUser(updatedUser);
      } catch (e) {
        logError('failed to update user with error $e');
        return;
      }
    }
  }

  void _updateCurrUser(User user) {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;

      emit(
        oldState.copyWith(
          user: user,
        ),
      );
    }
  }

  Future<void> _refreshChatThreadStats(int count) async {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;

      final stats = await _chatsRepo.getChatThreadStats();

      emit(
        oldState.copyWith(
          draftsCount: stats.draftsCount,
          waitingOnOthersQuestionCount: stats.waitingOnOthersQuestionCount,
          waitingOnYouQuestionCount: stats.waitingOnYouQuestionCount,
          favoritedQuestionsCount: stats.favoritedQuestionsCount!,
        ),
      );
    }
  }

  void _updateFavoritedStatus(
    FavoriteState newFavoriteState,
  ) {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;

      var newFavoriteCount = oldState.favoritedQuestionsCount;

      switch (newFavoriteState) {
        case FavoriteState.favorite:
          newFavoriteCount = newFavoriteCount + 1;
          break;
        case FavoriteState.unfavorite:
          newFavoriteCount = newFavoriteCount - 1;
      }

      emit(
        oldState.copyWith(
          favoritedQuestionsCount: newFavoriteCount,
        ),
      );
    }
  }

  void _updateNumDraftsInProgress(DraftCreatedEvent _) {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;
      emit(
        oldState.copyWith(
          draftsCount: oldState.draftsCount + 1,
        ),
      );
    }
  }

  void _updateNumDraftPublished(DraftPublishedEvent _) {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;
      emit(
        oldState.copyWith(
          draftsCount: oldState.draftsCount - 1,
          waitingOnOthersQuestionCount:
              oldState.waitingOnOthersQuestionCount + 1,
        ),
      );
    }
  }

  void _decrementNumDrafts(DraftDeleteEvent _) {
    if (state is ProfilePageLoadSuccess) {
      final oldState = state as ProfilePageLoadSuccess;
      emit(
        oldState.copyWith(
          draftsCount: oldState.draftsCount - 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    // Clean up any resources used by the cubit
    _questionFavoritingEvent?.cancel();
    _draftCreatedEventSubscription?.cancel();
    _draftPublishedEventSubscription?.cancel();
    _draftDeleteEventSubscription?.cancel();
    _notificationCountSubscription.cancel();
    _currUserUpdatesSubscription.cancel();
    return super.close();
  }
}
