import 'dart:async';

import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:loggy/loggy.dart';

part 'home_feed_state.dart';

class HomeFeedCubit extends Cubit<HomeFeedState> {
  HomeFeedCubit({required this.questionsRepo, required this.chatsRepo})
      : super(HomeFeedLoading()) {
    unawaited(chatsRepo.getChatInterlocutors(includeSelf: true));

    _questionFavoritingEvent = questionsRepo.questionFavoritingStream
        .listen((favoritingQuestionEvent) {
      _updateFavoritedStatus(
        favoritingQuestionEvent.questionId,
        favoritingQuestionEvent.favoritedStatus!,
      );
    });
    _questionVotingEvent =
        questionsRepo.questionVotingStream.listen((votingQuestionEvent) {
      _updateVotingScore(
        votingQuestionEvent.questionId,
        votingQuestionEvent.oldVotingStatus!,
        votingQuestionEvent.newVotingStatus!,
      );
    });

    _draftPublishedEventSubscription = chatsRepo.draftPublishedStream
        .listen(_removePublishedDraftFromQuestion);

    _draftUpsertEvent =
        chatsRepo.draftUpsertStream.listen(_upsertDraftLinkedToQuestion);

    _draftDeleteEvent =
        chatsRepo.draftDeletedStream.listen(_removeDraftLinkedToQuestion);

    _setupAutoRefetch(const Duration(hours: 6));
  }

  final QuestionsRepo questionsRepo;
  final ChatThreadsRepo chatsRepo;
  late QuestionFeedWithMetadata _paginatedHomeFeed;

  /// All interlocutors connected to the currently logged in interlocutor
  List<Interlocutor>? allConnectedInterlocutors;

  StreamSubscription<DraftPublishedEvent>? _draftPublishedEventSubscription;
  StreamSubscription<DraftUpsertEvent>? _draftUpsertEvent;
  StreamSubscription<DraftDeleteEvent>? _draftDeleteEvent;

  StreamSubscription<QuestionFavoritingEvent>? _questionFavoritingEvent;
  StreamSubscription<QuestionVotingEvent>? _questionVotingEvent;

  DateTime? _lastFetchTime;
  bool _isLoadingPage = false;

  Future<void> loadHomeFeed({bool reloadFromStart = false}) async {
    if (_isLoadingPage) {
      return;
    }
    try {
      _isLoadingPage = true;
      if (state is HomeFeedLoading || reloadFromStart) {
        allConnectedInterlocutors ??= await chatsRepo.getChatInterlocutors();
        _paginatedHomeFeed = await questionsRepo.getHomeFeed();
        final hasReachedMax = _paginatedHomeFeed.next == null;
        final questions = _paginatedHomeFeed.questions;

        emit(
          HomeFeedLoaded(
            questions: questions,
            hasReachedMax: hasReachedMax,
            allConnectedInterlocutors: allConnectedInterlocutors,
            feedGenerationDatetime:
                DateTime.parse(_paginatedHomeFeed.feedCreatedAt),
          ),
        );
      } else if (state is HomeFeedLoaded) {
        final oldState = state as HomeFeedLoaded;
        final allConnectedInterlocutors = oldState.allConnectedInterlocutors ??
            await chatsRepo.getChatInterlocutors();

        _paginatedHomeFeed = oldState.hasReachedMax
            ? _paginatedHomeFeed
            : await questionsRepo.getHomeFeed(
                pageUrl: _paginatedHomeFeed?.next,
              );
        final hasReachedMax = _paginatedHomeFeed?.next == null;
        final questions = List.of(oldState.questions)
          ..addAll(_paginatedHomeFeed?.questions ?? []);
        emit(
          oldState.copyWith(
            questions: questions,
            hasReachedMax: hasReachedMax,
            allConnectedInterlocutors: allConnectedInterlocutors,
          ),
        );
      }
      _isLoadingPage = false;
    } catch (e) {
      _isLoadingPage = false;
      // Retry with gradual backoff, as this happens XMLHttpRequest error.
      logError('failed to load home feed with error $e');
      emit(const HomeFeedError('Failed to load home feed. Are you online?'));
    }
    _lastFetchTime = DateTime.now();
  }

  void _setupAutoRefetch(Duration duration) {
    Timer.periodic(
      const Duration(minutes: 1),
      (Timer timer) async {
        if (_lastFetchTime == null) {
          return;
        }

        final currentTime = DateTime.now();
        final timeSinceLastFetch = currentTime.difference(_lastFetchTime!);

        // If it's been more than 6 hours since the last fetch
        if (timeSinceLastFetch >= duration) {
          await loadHomeFeed(reloadFromStart: true);
        }
      },
    );
  }

  void _updateVotingScore(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;
      final updatedQuestions = oldState.questions
          .updateVotingScore(questionId, oldVotingStatus, newVotingStatus);
      emit(
        oldState.copyWith(questions: updatedQuestions),
      );
    }
  }

  void _updateFavoritedStatus(
    String questionId,
    FavoriteState newFavoriteState,
  ) {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;

      final updatedQuestions = oldState.questions
          .updateFavoritedStatus(questionId, newFavoriteState);

      emit(
        oldState.copyWith(questions: updatedQuestions),
      );
    }
  }

  void _removePublishedDraftFromQuestion(DraftPublishedEvent event) {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;
      final updatedQuestions = oldState.questions.map((question) {
        if (question.id == event.draft.question) {
          final updatedUnpublishedDrafts = question.unpublishedDrafts
                  ?.where((draft) => draft.id != event.draft.id)
                  .toList() ??
              [];

          final updatedPublishedDrafts = [
            ...?question.publishedDrafts,
            event.draft
          ];

          return question.copyWith(
            unpublishedDrafts: updatedUnpublishedDrafts,
            publishedDrafts: updatedPublishedDrafts,
          );
        } else {
          return question;
        }
      }).toList();
      emit(oldState.copyWith(questions: updatedQuestions));
    }
  }

  void _upsertDraftLinkedToQuestion(DraftUpsertEvent event) {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;
      final updatedQuestions = oldState.questions.map((question) {
        // If this is the question the draft should be added to...
        if (question.id == event.draft.question) {
          // If unpublishedDrafts list already contains a draft with the same id, replace it.
          var updatedUnpublishedDrafts =
              question.unpublishedDrafts?.map((draft) {
            return draft.id == event.draft.id ? event.draft : draft;
          }).toList();

          // If the draft is new, i.e., it's not in the list, add it to the list.
          if (updatedUnpublishedDrafts != null &&
              !updatedUnpublishedDrafts
                  .any((draft) => draft.id == event.draft.id)) {
            updatedUnpublishedDrafts.add(event.draft);
          }

          // Create a new question with updated published drafts.
          return question.copyWith(unpublishedDrafts: updatedUnpublishedDrafts);
        }
        // Otherwise, return the question as it is.
        else {
          return question;
        }
      }).toList();

      emit(oldState.copyWith(questions: updatedQuestions));
    }
  }

  void _removeDraftLinkedToQuestion(DraftDeleteEvent event) {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;
      final updatedQuestions = oldState.questions.map((question) {
        // Remove the draft with the specified id from unpublished drafts.
        final updatedUnpublishedDrafts = question.unpublishedDrafts
                ?.where((draft) => draft.id != event.draft.id)
                .toList() ??
            [];

        // Create a new question with updated unpublished drafts.
        return question.copyWith(unpublishedDrafts: updatedUnpublishedDrafts);
      }).toList();

      emit(oldState.copyWith(questions: updatedQuestions));
    }
  }

  void forceUpdate() {
    if (state is HomeFeedLoaded) {
      final oldState = state as HomeFeedLoaded;
      emit(
        oldState.copyWith(updateCounter: oldState.updateCounter + 1),
      );
    }
  }

  @override
  Future<void> close() {
    _draftPublishedEventSubscription?.cancel();
    _draftUpsertEvent?.cancel();
    _draftDeleteEvent?.cancel();
    _questionFavoritingEvent?.cancel();
    _questionVotingEvent?.cancel();
    return super.close();
  }
}
