import 'package:chatbond/data/events.dart';
import 'package:chatbond_api/chatbond_api.dart';

abstract class ChatThreadsRepoInterface {
  Stream<QuestionChatsSeenEvent> get questionChatsSeenStream;
  Stream<DraftCreatedEvent> get draftCreatedStream;
  Stream<DraftPublishedEvent> get draftPublishedStream;
  Stream<DraftUpsertEvent> get draftUpsertStream;
  Stream<DraftDeleteEvent> get draftDeletedStream;
  Stream<List<ChatThread>> get dataSourceStream;

  Future<List<ChatThread>> getAllChatThreads();
  Future<QuestionThread> getQuestionThread(String id);
  Future<List<QuestionChat>> getQuestionChats(String questionThreadId);
  Future<bool> setQuestionChatsSeenAt(String questionThreadId);
  Future<QuestionChat> createQuestionChat(
    String questionThreadId,
    String content,
    String status,
  );
  Future<Interlocutor> getCurrentInterlocutor();
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

  Future<List<Interlocutor>> getChatInterlocutors({bool? includeSelf});
  Future<List<Interlocutor>> getConnectedInterlocutors({
    bool? includeSelf,
  });

  Future<List<DraftQuestionThread>?> fetchDraftsByQuestionId(String questionId);
  Future<DraftQuestionThread> upsertDraft(DraftQuestionThread draft);
  Future<DraftQuestionThread?> publishDraft(String draftId);
  Future<void> deleteDraft(DraftQuestionThread draftId);
  Future<PaginatedDraftQuestionThreadList> listDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<PaginatedQuestions> listPaginatedQuestionsOfDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  });
  Future<ChatThreadStats> getChatThreadStats({String? chatThreadId});
}
