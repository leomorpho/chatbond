import 'dart:async';

import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:loggy/loggy.dart';

part 'multipurpose_question_threads_page_state.dart';

// TODO: lost of code repetition from the main question threads page
class MultipurposeQuestionThreadsPageCubit
    extends Cubit<MultipurposeQuestionThreadsPageState> {
  MultipurposeQuestionThreadsPageCubit({
    required this.chatThreadsRepo,
    required this.questionsRepo,
    required this.questionThreadsPageType,
    required this.allInterlocutors,
    this.chatThreadId,
  }) : super(MultipurposeQuestionThreadsPageLoading()) {
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

    _questionChatsSeenEventSubscription = chatThreadsRepo
        .questionChatsSeenStream
        .listen((questionChatsSeenEvent) {
      setQuestionThreadToSeen(questionChatsSeenEvent.questionThreadId);
    });

    /// If a draft linked to a question thread in the current page is
    /// published, we want to remove it from the list of question threads,
    /// since it cannot be pending anymore, and will instead now show in
    /// the main question threads pages.
    final waitingOnCurrUser = questionThreadsPageType ==
            QuestionThreadsPageType.waitingForCurrUserForAllChatThreads ||
        questionThreadsPageType ==
            QuestionThreadsPageType.waitingForCurrUserForSpecificChatThread;

    if (waitingOnCurrUser) {
      _draftPublishedEventSubscription =
          chatThreadsRepo.draftPublishedStream.listen((draftPublishedEvent) {
        if (allInterlocutors
            .contains(draftPublishedEvent.draft.otherInterlocutor)) {
          // TODO: finish this and properly remove question thread
          removeQuestionThreadFromCurrentPage(
            // NOTE: only published drafts have an associated question thread
            draftPublishedEvent.draft.questionThread!,
          );
        }
      });
    }
  }
  final QuestionsRepo questionsRepo;
  final ChatThreadsRepo chatThreadsRepo;
  final QuestionThreadsPageType questionThreadsPageType;
  PaginatedQuestionThreadList? _paginatedQuestionThreadList;
  final String? chatThreadId;
  List<Interlocutor> allInterlocutors;

  StreamSubscription<QuestionChatsSeenEvent>?
      _questionChatsSeenEventSubscription;
  StreamSubscription<DraftPublishedEvent>? _draftPublishedEventSubscription;
  StreamSubscription<QuestionFavoritingEvent>? _questionFavoritingEvent;
  StreamSubscription<QuestionVotingEvent>? _questionVotingEvent;

  bool _isLoadingPage = false;

  Future<PaginatedQuestionThreadList> getChatThreadQuestionThreadsFromRepo({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    switch (questionThreadsPageType) {
      case QuestionThreadsPageType.waitingForCurrUserForSpecificChatThread:
        return chatThreadsRepo.getQuestionThreadsWaitingOnCurrUser(
          chatThreadId: chatThreadId,
          pageUrl: pageUrl,
        );
      case QuestionThreadsPageType.waitingOnOthersForSpecificChatThread:
        return chatThreadsRepo.getQuestionThreadsWaitingOnOthers(
          chatThreadId: chatThreadId,
          pageUrl: pageUrl,
        );
      case QuestionThreadsPageType.waitingForCurrUserForAllChatThreads:
        return chatThreadsRepo.getQuestionThreadsWaitingOnCurrUser(
          pageUrl: pageUrl,
        );
      case QuestionThreadsPageType.waitingOnOthersForAllChatThreads:
        return chatThreadsRepo.getQuestionThreadsWaitingOnOthers(
          pageUrl: pageUrl,
        );
    }
  }

  Future<void> loadQuestionThreads(String? chatThreadId) async {
    try {
      _isLoadingPage = true;
      if (state is MultipurposeQuestionThreadsPageLoading) {
        _paginatedQuestionThreadList =
            await getChatThreadQuestionThreadsFromRepo(
          chatThreadId: chatThreadId,
        );

        final hasReachedMax = _paginatedQuestionThreadList?.next == null;
        final allMultipurposeQuestionThreads =
            _paginatedQuestionThreadList?.results ?? [];

        emit(
          MultipurposeQuestionThreadsPageLoaded(
            questionThreads:
                sortQuestionThreadsByDate(allMultipurposeQuestionThreads),
            hasReachedMax: hasReachedMax,
            allInterlocutors: allInterlocutors,
          ),
        );
      } else if (state is MultipurposeQuestionThreadsPageLoaded) {
        final oldState = state as MultipurposeQuestionThreadsPageLoaded;
        _paginatedQuestionThreadList = oldState.hasReachedMax
            ? _paginatedQuestionThreadList
            : await getChatThreadQuestionThreadsFromRepo(
                chatThreadId: chatThreadId,
                pageUrl: _paginatedQuestionThreadList?.next,
              ); // TODO: doesn't that just get the same list again?

        final hasReachedMax = _paginatedQuestionThreadList?.next == null;
        final allMultipurposeQuestionThreads = List.of(oldState.questionThreads)
          ..addAll(_paginatedQuestionThreadList?.results ?? []);

        emit(
          oldState.copyWith(
            questionThreads: allMultipurposeQuestionThreads,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      _isLoadingPage = false;
    } catch (e) {
      _isLoadingPage = false;
      logError('loadMultipurposeQuestionThreads failed with error: $e');
      emit(
        const MultipurposeQuestionThreadsPageError(
          'Failed to load question threads',
        ),
      );
    }
  }

  void _updateVotingScore(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) {
    if (state is MultipurposeQuestionThreadsPageLoaded) {
      final oldState = state as MultipurposeQuestionThreadsPageLoaded;

      // loop through the questionThreads and update the voting score
      final updatedMultipurposeQuestionThreads =
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
      logError(
        '_updateVotingScore questionThreads: $updatedMultipurposeQuestionThreads',
      );

      emit(
        oldState.copyWith(
          questionThreads: updatedMultipurposeQuestionThreads,
          updateCounter: oldState.updateCounter + 1,
        ),
      );
    }
  }

  void _updateFavoritedStatus(
    String questionId,
    FavoriteState newFavoriteState,
  ) {
    if (state is MultipurposeQuestionThreadsPageLoaded) {
      final oldState = state as MultipurposeQuestionThreadsPageLoaded;

      // loop through the questionThreads and update the favorited status
      final updatedMultipurposeQuestionThreads =
          oldState.questionThreads.map((questionThread) {
        if (questionThread.question.id == questionId) {
          final updatedQuestion = questionThread.question.copyWith(
            isFavorited: newFavoriteState == FavoriteState.favorite,
          );
          return questionThread.copyWith(question: updatedQuestion);
        }
        return questionThread;
      }).toList();

      logError(
        '_updateFavoritedStatus questionThreads: $updatedMultipurposeQuestionThreads',
      );
      emit(
        oldState.copyWith(
          questionThreads: updatedMultipurposeQuestionThreads,
          updateCounter: oldState.updateCounter + 1,
        ),
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

  Future<void> setQuestionThreadToFullySeen(String questionThreadId) async {
    await chatThreadsRepo.setQuestionChatsSeenAt(questionThreadId);
  }

// TODO: this is a dupe function form question_threads_page_cubit, update so
// that we have only 1.
  void setQuestionThreadToSeen(String questionThreadId) {
    // TODO: only call this method if question thread is not yet set to fully seen
    if (state is MultipurposeQuestionThreadsPageLoaded) {
      final oldState = state as MultipurposeQuestionThreadsPageLoaded;

      // Loop through the questionThreads and update the seen status
      final updatedMultipurposeQuestionThreads =
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
        'setQuestionThreadToSeen in question_threads_page_cubit: $updatedMultipurposeQuestionThreads',
      );
      emit(
        oldState.copyWith(
          questionThreads: updatedMultipurposeQuestionThreads,
          updateCounter: oldState.updateCounter + 1,
        ),
      );
    }
  }

  Future<void> removeQuestionThreadFromCurrentPage(
    String questionThreadId,
  ) async {
    if (questionThreadsPageType ==
            QuestionThreadsPageType.waitingOnOthersForSpecificChatThread &&
        questionThreadId != chatThreadId) {
      return;
    }
    if (state is MultipurposeQuestionThreadsPageLoaded) {
      final oldState = state as MultipurposeQuestionThreadsPageLoaded;

      final updatedMultipurposeQuestionThreads =
          oldState.questionThreads.where((questionThread) {
        return questionThread.id != questionThreadId;
      }).toList();

      emit(
        oldState.copyWith(
          questionThreads: updatedMultipurposeQuestionThreads,
          updateCounter: oldState.updateCounter + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    // Clean up any resources used by the cubit
    _questionChatsSeenEventSubscription?.cancel();
    _draftPublishedEventSubscription?.cancel();
    _questionFavoritingEvent?.cancel();
    _questionVotingEvent?.cancel();
    return super.close();
  }
}
