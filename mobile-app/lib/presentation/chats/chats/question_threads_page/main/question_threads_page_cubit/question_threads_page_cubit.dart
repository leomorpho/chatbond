import 'dart:async';

import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:loggy/loggy.dart';

part 'question_threads_page_state.dart';

class QuestionThreadsPageCubit extends Cubit<QuestionThreadsPageState> {
  QuestionThreadsPageCubit({
    required this.chatThreadsRepo,
    required this.questionsRepo,
    required this.numTotalNotificationsStream,
    required this.otherInterlocutors,
  }) : super(QuestionThreadsPageLoading()) {
    _notificationCountSubscription =
        numTotalNotificationsStream.listen(_handleNotificationCountEvent);

    _questionFavoritingEventSubscription = questionsRepo
        .questionFavoritingStream
        .listen((favoritingQuestionEvent) {
      _updateFavoritedStatus(
        favoritingQuestionEvent.questionId,
        favoritingQuestionEvent.favoritedStatus!,
      );
    });
    _questionVotingEventSubscription =
        questionsRepo.questionVotingStream.listen((votingQuestionEvent) {
      _updateVotingScore(
        votingQuestionEvent.questionId,
        votingQuestionEvent.oldVotingStatus!,
        votingQuestionEvent.newVotingStatus!,
      );
    });

    _questionChatsSeenEventSubscription = chatThreadsRepo
        .questionChatsSeenStream
        .listen((questionChatsSeenEvent) {
      setQuestionThreadToSeen(questionChatsSeenEvent.questionThreadId);
    });
    _draftCreatedEventSubscription =
        chatThreadsRepo.draftCreatedStream.listen(_updateNumDraftsInProgress);
    _draftPublishedEventSubscription =
        chatThreadsRepo.draftPublishedStream.listen(_updateNumDraftPublished);
    _draftDeleteEventSubscription = chatThreadsRepo.draftDeletedStream
        .listen(_decrementNumDraftsInProgress);
  }
  final QuestionsRepo questionsRepo;
  final ChatThreadsRepo chatThreadsRepo;
  final Stream<int> numTotalNotificationsStream;
  final List<Interlocutor> otherInterlocutors;

  PaginatedQuestionThreadList? _paginatedQuestionThreadList;

  late StreamSubscription<QuestionFavoritingEvent>
      _questionFavoritingEventSubscription;
  late StreamSubscription<QuestionVotingEvent> _questionVotingEventSubscription;
  late StreamSubscription<QuestionChatsSeenEvent>
      _questionChatsSeenEventSubscription;
  late StreamSubscription<DraftCreatedEvent> _draftCreatedEventSubscription;
  late StreamSubscription<DraftPublishedEvent> _draftPublishedEventSubscription;
  late StreamSubscription<DraftDeleteEvent> _draftDeleteEventSubscription;
  late StreamSubscription<int> _notificationCountSubscription;

  Future<void> loadQuestionThreads(String chatThreadId) async {
    try {
      if (state is QuestionThreadsPageLoading) {
        _paginatedQuestionThreadList =
            await chatThreadsRepo.getChatThreadQuestionThreads(chatThreadId);
        final hasReachedMax = _paginatedQuestionThreadList?.next == null;
        final allQuestionThreadsForCurrentPerson =
            _paginatedQuestionThreadList?.results ?? [];
        // Separate questionThreads into two lists
        final questionThreadsAnswered = allQuestionThreadsForCurrentPerson
            .where((thread) => thread.allInterlocutorsAnswered)
            .toList();

        final stats = await chatThreadsRepo.getChatThreadStats(
          chatThreadId: chatThreadId,
        );

        emit(
          QuestionThreadsPageLoaded(
            chatThreadId: chatThreadId,
            questionThreads: sortQuestionThreadsByDate(questionThreadsAnswered),
            hasReachedMax: hasReachedMax,
            draftsCount: stats.draftsCount,
            waitingOnOthersQuestionCount: stats.waitingOnOthersQuestionCount,
            waitingOnYouQuestionCount: stats.waitingOnYouQuestionCount,
          ),
        );
      } else if (state is QuestionThreadsPageLoaded) {
        final oldState = state as QuestionThreadsPageLoaded;
        _paginatedQuestionThreadList = oldState.hasReachedMax
            ? _paginatedQuestionThreadList
            : await chatThreadsRepo.getChatThreadQuestionThreads(
                chatThreadId,
                pageUrl: _paginatedQuestionThreadList?.next,
              );
        final hasReachedMax = _paginatedQuestionThreadList?.next == null;
        final allQuestionThreadsForCurrentPerson =
            List.of(oldState.questionThreads)
              ..addAll(_paginatedQuestionThreadList?.results ?? []);

        // Separate questionThreads into two lists
        final questionThreadsAnswered = allQuestionThreadsForCurrentPerson
            .where((thread) => thread.allInterlocutorsAnswered)
            .toList();

        emit(
          oldState.copyWith(
            questionThreads: questionThreadsAnswered,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
    } catch (e) {
      logError('loadQuestionThreads failed with error: $e');
      emit(const QuestionThreadsPageError('Failed to load question threads'));
    }
  }

  Future<void> reloadFirstPage() async {
    if (state is! QuestionThreadsPageLoaded) return;

    try {
      final newPage = await chatThreadsRepo.getChatThreadQuestionThreads(
        (state as QuestionThreadsPageLoaded).chatThreadId,
      );

      final oldState = state as QuestionThreadsPageLoaded;

      // Replace old items and prepend any new items.
      final newThreadsMap = {
        for (final thread in newPage.results) thread.id: thread,
      };
      final updatedThreads =
          <QuestionThread>[]; // Replace with your actual Thread type

      for (final oldThread in oldState.questionThreads) {
        updatedThreads.add(newThreadsMap[oldThread.id] ?? oldThread);
        newThreadsMap.remove(oldThread.id);
      }

      // Any remaining newThreadsMap entries are new and should be prepended.
      updatedThreads.insertAll(0, newThreadsMap.values);

      emit(oldState.copyWith(questionThreads: updatedThreads));
    } catch (e) {
      logError('reloadFirstPage failed with error: $e');
    }
  }

  /// TODO: the following function listens to the notif counts coming from
  /// realtime repo. On new event, it basically refreshes ALL the data. That's
  /// not ideal, but cuts a corner to get a POC asap.
  Future<void> _handleNotificationCountEvent(int _) async {
    /**
     * TODO: we are currently always doing a network request to update count
     * stats in question threads page. In the future, we would want to derive
     * that locally, although the local DB will need to have strong consistency
     * with the BE state first.
     */
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      final stats = await chatThreadsRepo.getChatThreadStats(
        chatThreadId: oldState.chatThreadId,
      );

      emit(
        oldState.copyWith(
          draftsCount: stats.draftsCount,
          waitingOnOthersQuestionCount: stats.waitingOnOthersQuestionCount,
          waitingOnYouQuestionCount: stats.waitingOnYouQuestionCount,
        ),
      );
      await reloadFirstPage(); // TODO: hack
    }
  }

  void _updateVotingScore(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      // loop through the questionThreads and update the voting score
      final updatedQuestionThreads =
          oldState.questionThreads.map((questionThread) {
        if (questionThread.question.id == questionId) {
          final updatedQuestion = questionThread.question.copyWith(
            cumulativeVotingScore: _calculateNewScore(
              questionThread.question.cumulativeVotingScore,
              oldVotingStatus,
              newVotingStatus,
            ),
            currInterlocutorVotingStatus: newVotingStatus,
          );
          return questionThread.copyWith(question: updatedQuestion);
        }
        return questionThread;
      }).toList();

      emit(
        oldState.copyWith(questionThreads: updatedQuestionThreads),
      );
    }
  }

  void _updateFavoritedStatus(
    String questionId,
    FavoriteState newFavoriteState,
  ) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      // loop through the questionThreads and update the favorited status
      final updatedQuestionThreads =
          oldState.questionThreads.map((questionThread) {
        if (questionThread.question.id == questionId) {
          final updatedQuestion = questionThread.question.copyWith(
            isFavorited: newFavoriteState == FavoriteState.favorite,
          );
          return questionThread.copyWith(question: updatedQuestion);
        }
        return questionThread;
      }).toList();

      emit(
        oldState.copyWith(questionThreads: updatedQuestionThreads),
      );
    }
  }

  // This function updates the cumulativeVotingScore based on old and new voting status
  int _calculateNewScore(
    int oldScore,
    VoteStatus oldStatus,
    VoteStatus newStatus,
  ) {
    var newScore = oldScore;
    if (oldStatus == VoteStatus.upvoted) {
      newScore--; // decrement score if it was previously upvoted
    } else if (oldStatus == VoteStatus.downvoted) {
      newScore++; // increment score if it was previously downvoted
    }

    if (newStatus == VoteStatus.upvoted) {
      newScore++; // increment score if new status is upvote
    } else if (newStatus == VoteStatus.downvoted) {
      newScore--; // decrement score if new status is downvote
    }

    return newScore;
  }

  void _updateNumDraftsInProgress(DraftCreatedEvent event) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      if (event.draft.chatThread! == oldState.chatThreadId) {
        // One of the drafts becomes a question thread, which is why we need to
        // adjust both counts.
        emit(
          oldState.copyWith(
            draftsCount: oldState.draftsCount + 1,
          ),
        );
      }
    }
  }

  void _decrementNumDraftsInProgress(DraftDeleteEvent event) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      if (event.draft.chatThread! == oldState.chatThreadId) {
        // One of the drafts becomes a question thread, which is why we need to
        // adjust both counts.
        emit(
          oldState.copyWith(
            draftsCount: oldState.draftsCount - 1,
          ),
        );
      }
    }
  }

  void _updateNumDraftPublished(DraftPublishedEvent event) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      if (event.draft.chatThread! == oldState.chatThreadId) {
        // One of the drafts becomes a question thread, which is why we need to
        // adjust both counts.
        emit(
          oldState.copyWith(
            draftsCount: oldState.draftsCount - 1,
            waitingOnOthersQuestionCount:
                oldState.waitingOnOthersQuestionCount + 1,
          ),
        );
      }
    }
  }

  void _handleRealtimeQuestionThreadUpdate(QuestionThread newQuestionThread) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      // Determine if the question thread already exists
      final existingQuestionThreadIndex = oldState.questionThreads.indexWhere(
        (questionThread) => questionThread.id == newQuestionThread.id,
      );
      final updatedQuestionThreads =
          List<QuestionThread>.from(oldState.questionThreads);

      if (existingQuestionThreadIndex >= 0) {
        // Update the existing question thread
        updatedQuestionThreads[existingQuestionThreadIndex] = newQuestionThread;
      } else {
        // Add the new question thread
        updatedQuestionThreads.add(newQuestionThread);
      }

      emit(
        oldState.copyWith(
          questionThreads: sortQuestionThreadsByDate(updatedQuestionThreads),
        ),
      );
    }
  }

  Future<void> setQuestionThreadToFullySeen(String questionThreadId) async {
    await chatThreadsRepo.setQuestionChatsSeenAt(questionThreadId);
  }

  void setQuestionThreadToSeen(String questionThreadId) {
    if (state is QuestionThreadsPageLoaded) {
      final oldState = state as QuestionThreadsPageLoaded;

      // Loop through the questionThreads and update the seen status
      final updatedQuestionThreads =
          oldState.questionThreads.map((questionThread) {
        if (questionThread.id == questionThreadId) {
          // Logic to update the seen status of the questionThread goes here
          // The exact code depends on the structure of your QuestionThread objects
          // Here's a placeholder implementation:
          final updatedQuestionThread =
              questionThread.copyWith(numNewUnseenMessages: 0);
          return updatedQuestionThread;
        }
        return questionThread;
      }).toList();
      logInfo(
        'setQuestionThreadToSeen in question_threads_page_cubit: $updatedQuestionThreads',
      );
      emit(
        oldState.copyWith(
          questionThreads: updatedQuestionThreads,
          updateCounter: oldState.updateCounter + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    // Clean up any resources used by the cubit
    _questionChatsSeenEventSubscription.cancel();
    _questionFavoritingEventSubscription.cancel();
    _questionVotingEventSubscription.cancel();
    _draftCreatedEventSubscription.cancel();
    _draftPublishedEventSubscription.cancel();
    _draftDeleteEventSubscription.cancel();
    _notificationCountSubscription.cancel();
    return super.close();
  }
}
