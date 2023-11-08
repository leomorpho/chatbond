import 'package:chatbond_api/chatbond_api.dart';

abstract class ChatsInterface {
  Future<Interlocutor> getCurrentInterlocutor();
  Future<ChatThread> fetchChatThreadWithQuestionThreads(String id);
  Future<PaginatedQuestionThreadList> getChatThreadQuestionThreads(
    String chatThreadId, {
    String? pageUrl,
    bool? waitingOnOther,
  });
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnOthers({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnCurrUser({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<QuestionThread> fetchQuestionThread(String id);
  Future<List<QuestionChat>> fetchQuestionChats(
    String questionThreadId,
  );
  Future<List<ChatThread>> getChatThreads();
  Future<QuestionChat> createQuestionChat(
    String questionThreadId,
    String content,
    String status,
  );
  Future<void> setSeenAt(String questionThreadId);
  Future<List<Interlocutor>> getChatInterlocutors({bool? includeSelf});

  Future<List<DraftQuestionThread>?> fetchDraftsByQuestionId(
    String questionId,
  );
  Future<PaginatedDraftQuestionThreadList?> listDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<DraftQuestionThread?> createDraftQuestionThread(
    DraftQuestionThread draftQuestionThread,
  );
  Future<DraftQuestionThread> publishDraft(String draftId);
  Future<DraftQuestionThread> retrieveDraft(String draftId);
  Future<void> deleteDraftQuestionThread(String id);
  Future<PaginatedQuestions> listPaginatedQuestionsOfDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<UpsertResult> upsertDraft(DraftQuestionThread draft);
  Future<ChatThreadStats> getChatThreadStats({String? chatThreadId});
}
