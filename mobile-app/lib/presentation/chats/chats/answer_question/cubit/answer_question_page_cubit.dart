import 'package:bloc/bloc.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:loggy/loggy.dart';

part 'answer_question_page_state.dart';

class AnswerQuestionPageCubit extends Cubit<AnswerQuestionPageState> {
  AnswerQuestionPageCubit({
    required this.question,
    required this.allConnectedInterlocutors,
    required this.chatThreadsRepo,
  }) : super(AnswerQuestionPageLoading(question: question)) {
    _fetchData();
  }

  final Question question;
  final ChatThreadsRepo chatThreadsRepo;
  final List<Interlocutor> allConnectedInterlocutors;

  Future<void> _fetchData() async {
    try {
      final drafts = await chatThreadsRepo.fetchDraftsByQuestionId(question.id);
      final interlocutorToDraftMap =
          drafts != null ? _createInterlocutorToDraftMap(drafts) : null;

      Interlocutor? selectedInterlocutor;
      int? cursorPosition;
      if (interlocutorToDraftMap?.isNotEmpty ?? false) {
        for (final interlocutor in interlocutorToDraftMap!.keys) {
          final drafter = interlocutorToDraftMap[interlocutor];
          if (drafter != null && drafter.publishedAt == null) {
            selectedInterlocutor = interlocutor;
            cursorPosition = drafter.content.length;
            break;
          }
        }
      }

      emit(
        AnswerQuestionPageLoaded(
          interlocutors: allConnectedInterlocutors,
          interlocutorToDraftMap: interlocutorToDraftMap,
          question: question,
          selectedInterlocutor: selectedInterlocutor,
          cursorPosition: cursorPosition,
        ),
      );
    } catch (error) {
      emit(
        AnswerQuestionPageFailed(
          question: question,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> saveText(
    DraftQuestionThread newDraft,
    int cursorPosition,
  ) async {
    // Your save logic here
  }

  Future<void> upsertDraft(
    DraftQuestionThread draft,
    int cursorPosition,
  ) async {
    try {
      final newDraft = await chatThreadsRepo.upsertDraft(draft);

      // Obtain current state
      final currentState = state;
      if (currentState is AnswerQuestionPageLoaded) {
        // Clone the interlocutorToDraftMap and add/replace the new draft
        final updatedInterlocutorToDraftMap = {
          ...?currentState.interlocutorToDraftMap,
        };

        updatedInterlocutorToDraftMap[newDraft.otherInterlocutor] = newDraft;

        /// Add draft to the question object as QuestionCard shows different
        /// feedback based on that.
        if (newDraft.publishedAt == null) {
          final existingDraftIndex = question.unpublishedDrafts
              ?.indexWhere((d) => d.id == newDraft.id);

          if (existingDraftIndex != null && existingDraftIndex >= 0) {
            // Replace existing draft
            question.unpublishedDrafts![existingDraftIndex] = newDraft;
          } else {
            // Add new draft
            question.unpublishedDrafts?.add(newDraft);
          }
        }

        // Emit a new state reflecting the updated draft
        emit(
          AnswerQuestionPageLoaded(
            interlocutors: currentState.interlocutors,
            interlocutorToDraftMap: updatedInterlocutorToDraftMap,
            selectedInterlocutor: newDraft.otherInterlocutor,
            question: question,
            cursorPosition: cursorPosition,
          ),
        );
      }
    } catch (error) {
      logError('Caught error in AnswerQuestionPageCubit.upsertDraft: $error');
      emit(
        AnswerQuestionPageFailed(
          question: question,
          error: error.toString(),
        ),
      );
    }
  }

  Future<DraftQuestionThread?> publishDraft(String draftId) async {
    final publishedDraft = await chatThreadsRepo.publishDraft(draftId);
    if (publishedDraft == null) {
      emit(
        AnswerQuestionPageFailed(
          question: question,
          error: 'failed to publish draft',
        ),
      );
    }
    return publishedDraft;
  }

  Future<void> deleteDraft(DraftQuestionThread draft) async {
    try {
      await chatThreadsRepo.deleteDraft(draft);
      final currentState = state;

      if (currentState is AnswerQuestionPageLoaded) {
        final updatedInterlocutorToDraftMap =
            <Interlocutor, DraftQuestionThread>{};

        for (final entry in currentState.interlocutorToDraftMap!.entries) {
          if (entry.value.id != draft.id) {
            updatedInterlocutorToDraftMap[entry.key] = entry.value;
          }
        }

        /// Remove draft from question object as QuestionCard shows different
        /// feedback based on that.
        question.unpublishedDrafts?.removeWhere((d) => d.id == draft.id);

        emit(
          currentState.copyWith(
            interlocutorToDraftMap: updatedInterlocutorToDraftMap,
            question: question,
          ),
        );
      }
    } catch (error) {
      logError('Caught error in AnswerQuestionPageCubit.deleteDraft: $error');
      emit(
        AnswerQuestionPageFailed(
          question: question,
          error: error.toString(),
        ),
      );
    }
  }

  Map<Interlocutor, DraftQuestionThread> _createInterlocutorToDraftMap(
    List<DraftQuestionThread> threads,
  ) {
    final threadMap = <Interlocutor, DraftQuestionThread>{};

    for (final thread in threads) {
      threadMap[thread.otherInterlocutor] = thread;
    }

    return threadMap;
  }
}
