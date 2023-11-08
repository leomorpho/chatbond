import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:loggy/loggy.dart';

part 'multipurpose_questions_page_state.dart';

class MultipurposeQuestionsPageCubit
    extends Cubit<MultipurposeQuestionsPageState> {
  MultipurposeQuestionsPageCubit({
    required this.questionsRepo,
    required this.chatsRepo,
    required this.questionsPageType,
    this.chatThreadId,
    this.otherInterlocutors,
  }) : super(MultipurposeQuestionsPageLoading()) {
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
        .listen(_removeQuestionWithPublishedDraft);
    _draftUpsertEvent =
        chatsRepo.draftUpsertStream.listen(_upsertDraftLinkedToQuestion);
    _draftDeleteEvent =
        chatsRepo.draftDeletedStream.listen(_removeDraftLinkedToQuestion);
  }

  final QuestionsRepo questionsRepo;
  final ChatThreadsRepo chatsRepo;
  PaginatedQuestions? _paginatedQuestions;

  /// All interlocutors connected to the currently logged in interlocutor
  List<Interlocutor>? otherInterlocutors;
  final QuestionsPageType questionsPageType;
  final String? chatThreadId;

  StreamSubscription<DraftPublishedEvent>? _draftPublishedEventSubscription;
  StreamSubscription<DraftUpsertEvent>? _draftUpsertEvent;
  StreamSubscription<DraftDeleteEvent>? _draftDeleteEvent;

  StreamSubscription<QuestionFavoritingEvent>? _questionFavoritingEvent;
  StreamSubscription<QuestionVotingEvent>? _questionVotingEvent;

  bool _isLoadingPage = false;

  Future<PaginatedQuestions> getPaginatedQuestionsFromRepo({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    switch (questionsPageType) {
      case QuestionsPageType.draftsForAllChatThreads:
        return chatsRepo.listPaginatedQuestionsOfDraftQuestionThreads(
          pageUrl: pageUrl,
        );
      case QuestionsPageType.draftsForSpecificChatThread:
        return chatsRepo.listPaginatedQuestionsOfDraftQuestionThreads(
          chatThreadId: chatThreadId,
          pageUrl: pageUrl,
        );
      case QuestionsPageType.favorites:
        return questionsRepo.getFavoritedQuestions(pageUrl: pageUrl);
    }
  }

  Future<void> loadQuestions(String? chatThreadId) async {
    if (_isLoadingPage) {
      return;
    }
    try {
      _isLoadingPage = true;
      if (state is MultipurposeQuestionsPageLoading) {
        _paginatedQuestions =
            await getPaginatedQuestionsFromRepo(chatThreadId: chatThreadId);
        final hasReachedMax = _paginatedQuestions?.next == null;
        final questions = _paginatedQuestions?.results ?? [];

        emit(
          MultipurposeQuestionsPageLoaded(
            questions: questions,
            hasReachedMax: hasReachedMax,
            otherInterlocutors: otherInterlocutors,
          ),
        );
      } else if (state is MultipurposeQuestionsPageLoaded) {
        final oldState = state as MultipurposeQuestionsPageLoaded;

        _paginatedQuestions = oldState.hasReachedMax
            ? _paginatedQuestions
            : await getPaginatedQuestionsFromRepo(
                chatThreadId: chatThreadId,
                pageUrl: _paginatedQuestions?.next,
              );

        final hasReachedMax = _paginatedQuestions?.next == null;
        final questions = List.of(oldState.questions)
          ..addAll(_paginatedQuestions?.results ?? []);
        emit(
          oldState.copyWith(
            questions: questions,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      _isLoadingPage = false;
    } catch (e) {
      _isLoadingPage = false;
      logError('failed to load multipurpose questions feed with error $e');
      // TODO: error never shown in UI because we have no UI for error case
      emit(
        const MultipurposeQuestionsPageError(
          'Failed to load questions. Are you online?',
        ),
      );
    }
  }

  void _updateVotingScore(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) {
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;
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
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;

      final updatedQuestions = oldState.questions
          .updateFavoritedStatus(questionId, newFavoriteState);

      emit(
        oldState.copyWith(questions: updatedQuestions),
      );
    }
  }

  void _removeQuestionWithPublishedDraft(DraftPublishedEvent event) {
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;

      // TODO: need to check that draft is for currently selected interlocutor

      // Filter out the question that matches event.draft.question
      final updatedQuestions = oldState.questions.where((question) {
        return question.id != event.draft.question;
      }).toList();

      emit(oldState.copyWith(questions: updatedQuestions));
    }
  }

  void _upsertDraftLinkedToQuestion(DraftUpsertEvent event) {
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;
      final updatedQuestions = oldState.questions.map((question) {
        // If this is the question the draft should be added to...
        if (question.id == event.draft.question) {
          // If publishedDrafts list already contains a draft with the same id, replace it.
          final updatedUnpublishedDrafts =
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

  // TODO: This doesn't seem to work for profile/drafts page after deleting a draft
  void _removeDraftLinkedToQuestion(DraftDeleteEvent event) {
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;

      // Iterate through each question to find and remove the draft that matches the draftId.
      final updatedQuestions = oldState.questions.map((question) {
        // If unpublishedDrafts is null or empty, return the question as is.
        if (question.unpublishedDrafts == null ||
            question.unpublishedDrafts!.isEmpty) {
          return question;
        }

        // Filter out the drafts that match the event.draftId.
        final updatedUnpublishedDrafts =
            question.unpublishedDrafts!.where((draft) {
          return draft.id != event.draft.id;
        }).toList();

        // Return a new question with the updated list of unpublished drafts.
        return question.copyWith(unpublishedDrafts: updatedUnpublishedDrafts);
      }).toList();

      emit(oldState.copyWith(questions: updatedQuestions));
    }
  }

  void forceUpdate() {
    if (state is MultipurposeQuestionsPageLoaded) {
      final oldState = state as MultipurposeQuestionsPageLoaded;
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
