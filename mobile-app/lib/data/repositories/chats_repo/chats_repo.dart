import 'dart:async';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo_interface.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/subjects.dart';

class ChatThreadsRepo with RepoLogger implements ChatThreadsRepoInterface {
  ChatThreadsRepo({
    required ApiClient apiClient,
    required StreamSink<List<ChatThread>> chatThreadsSink,
    required StreamSink<List<QuestionThread>> questionThreadsSink,
    required StreamSink<List<QuestionChat>> questionChatsSink,
    required StreamSink<List<Interlocutor>> interlocutorSink,
    required Stream<String> chatThreadRequestsStream,
    required Stream<String> questionThreadRequestsStream,
    required Stream<String> interlocutorRequestsStream,
  })  : _apiClient = apiClient,
        _chatThreadsSink = chatThreadsSink,
        _questionThreadsSink = questionThreadsSink,
        _questionChatsSink = questionChatsSink,
        _interlocutorSink = interlocutorSink {
    chatThreadRequestsStream.listen(
      // TODO: implement getChatThreadById and be more precise
      (_) => getAllChatThreads(),
    );
    // questionThreadRequestsStream.listen(getQuestionThread);
    interlocutorRequestsStream.listen(
        // TODO: implement getInterlocutorById
        (_) => getChatInterlocutors(includeSelf: true));
  }

  final ApiClient _apiClient;
  final StreamSink<List<ChatThread>> _chatThreadsSink;
  final StreamSink<List<QuestionThread>> _questionThreadsSink;
  final StreamSink<List<QuestionChat>> _questionChatsSink;
  final StreamSink<List<Interlocutor>> _interlocutorSink;

  /// Source of truth for this repo. Listen to the streams for updates.
  /// TODO: can this be updated? Having 1 new stream per event type seems like
  /// a lot. To rethink at some point if it becomes cumbersome to add stuff.
  final StreamController<QuestionChatsSeenEvent>
      _questionChatsSeenStreamController =
      StreamController<QuestionChatsSeenEvent>.broadcast();

  @override
  Stream<QuestionChatsSeenEvent> get questionChatsSeenStream =>
      _questionChatsSeenStreamController.stream;

  final StreamController<DraftCreatedEvent> _draftCreatedStreamController =
      StreamController<DraftCreatedEvent>.broadcast();

  // TODO: replace all uses of following stream with draftUpsertStream since
  // upsert = create + update
  @override
  Stream<DraftCreatedEvent> get draftCreatedStream =>
      _draftCreatedStreamController.stream;

  final StreamController<DraftPublishedEvent> _draftPublishedStreamController =
      StreamController<DraftPublishedEvent>.broadcast();

  @override
  Stream<DraftPublishedEvent> get draftPublishedStream =>
      _draftPublishedStreamController.stream;

  final StreamController<DraftUpsertEvent> _draftUpsertStreamController =
      StreamController<DraftUpsertEvent>.broadcast();

  @override
  Stream<DraftUpsertEvent> get draftUpsertStream =>
      _draftUpsertStreamController.stream;

  final _chatThreadsController = BehaviorSubject<List<ChatThread>>();

  final StreamController<DraftDeleteEvent> _draftDeleteStreamController =
      StreamController<DraftDeleteEvent>.broadcast();

  @override
  Stream<DraftDeleteEvent> get draftDeletedStream =>
      _draftDeleteStreamController.stream;

  // TODO: add more error handling for API failures
  // TODO: do we actually need this stream? Is it used anywhere?
  // Expose the chatThreads stream
  @override
  Stream<List<ChatThread>> get dataSourceStream =>
      _chatThreadsController.asBroadcastStream();

  Interlocutor? _currInterlocutor;

  @override
  Future<List<ChatThread>> getAllChatThreads() async {
    final chatThreads = await _apiClient.chats.getChatThreads();
    _chatThreadsSink.add(chatThreads);

    _chatThreadsController.add(chatThreads);
    return chatThreads;
  }

  @override
  Future<QuestionThread> getQuestionThread(String id) async {
    final questionThread = await _apiClient.chats.fetchQuestionThread(id);
    _questionThreadsSink.add([questionThread]);

    return questionThread;
  }

  List<QuestionChat> _sortQuestionChatsByCreatedAt(
    List<QuestionChat> questionChats,
  ) {
    questionChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return questionChats;
  }

  @override
  Future<List<QuestionChat>> getQuestionChats(String questionThreadId) async {
    var questionChats =
        await _apiClient.chats.fetchQuestionChats(questionThreadId);
    questionChats = _sortQuestionChatsByCreatedAt(questionChats);

    _questionChatsSink.add(questionChats);
    return questionChats;
  }

  @override
  Future<bool> setQuestionChatsSeenAt(String questionThreadId) async {
    try {
      await _apiClient.chats.setSeenAt(questionThreadId);

      // Emit an event on the stream.
      _questionChatsSeenStreamController.add(
        QuestionChatsSeenEvent(
          questionThreadId: questionThreadId,
        ),
      );
    } catch (e) {
      logError(
        'failed to set question chats to seen for questionThread Id $questionThreadId: $e',
      );
      return false;
    }
    return true;
  }

  @override
  Future<QuestionChat> createQuestionChat(
    String questionThreadId,
    String content,
    String status,
  ) async {
    final questionChat = await _apiClient.chats
        .createQuestionChat(questionThreadId, content, status);

    _questionChatsSink.add([questionChat]);

    return questionChat;
  }

  @override
  Future<Interlocutor> getCurrentInterlocutor() async {
    if (_currInterlocutor != null) {
      return _currInterlocutor!;
    }
    if (getIt.get<GlobalState>().currentInterlocutor != null) {
      return getIt.get<GlobalState>().currentInterlocutor!;
    }
    final interlocutor = await _apiClient.chats.getCurrentInterlocutor();
    _interlocutorSink.add([interlocutor]);
    _currInterlocutor = interlocutor;

    if (getIt.get<GlobalState>().currentInterlocutor == null) {
      getIt.get<GlobalState>().currentInterlocutor = interlocutor;
    }

    return interlocutor;
  }

  @override
  Future<PaginatedQuestionThreadList> getChatThreadQuestionThreads(
    String chatThreadId, {
    String? pageUrl,
    bool? waitingOnOther,
  }) async {
    final paginatedQuestionThreadList =
        await _apiClient.chats.getChatThreadQuestionThreads(
      chatThreadId,
      pageUrl: pageUrl,
      waitingOnOther: waitingOnOther,
    );
    _questionThreadsSink.add(paginatedQuestionThreadList.results);

    return paginatedQuestionThreadList;
  }

  @override
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnOthers({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final paginatedQuestionThreadList =
        await _apiClient.chats.getQuestionThreadsWaitingOnOthers(
      chatThreadId: chatThreadId,
      pageUrl: pageUrl,
    );
    _questionThreadsSink.add(paginatedQuestionThreadList.results);

    return paginatedQuestionThreadList;
  }

  @override
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnCurrUser({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final paginatedQuestionThreadList =
        await _apiClient.chats.getQuestionThreadsWaitingOnCurrUser(
      chatThreadId: chatThreadId,
      pageUrl: pageUrl,
    );

    _questionThreadsSink.add(paginatedQuestionThreadList.results);

    return paginatedQuestionThreadList;
  }

  @override
  Future<List<Interlocutor>> getChatInterlocutors({bool? includeSelf}) async {
    final interlocutors =
        await _apiClient.chats.getChatInterlocutors(includeSelf: includeSelf);
    _interlocutorSink.add(interlocutors);

    if (includeSelf == null || !includeSelf) {
      getIt.get<GlobalState>().connectedInterlocutors = interlocutors;
    } else {
      if (getIt.get<GlobalState>().currUser == null) {
        throw Exception(
            'Current user should be set in GlobalState by this call');
      }
      getIt.get<GlobalState>().connectedInterlocutors = interlocutors
          .where(
            (interlocutor) =>
                interlocutor.userId != getIt.get<GlobalState>().currUser?.id,
          )
          .toList();
      getIt.get<GlobalState>().currentInterlocutor = interlocutors
          .where((interlocutor) =>
              interlocutor.userId == getIt.get<GlobalState>().currUser?.id)
          .first;
    }

    return interlocutors;
  }

  @override
  Future<List<Interlocutor>> getConnectedInterlocutors({
    bool? includeSelf,
  }) async {
    final interlocutors =
        await _apiClient.chats.getChatInterlocutors(includeSelf: includeSelf);
    _interlocutorSink.add(interlocutors);
    // TODO: reuse getChatInterlocutors
    return interlocutors;
  }

  @override
  Future<List<DraftQuestionThread>?> fetchDraftsByQuestionId(
    String questionId,
  ) async {
    return _apiClient.chats.fetchDraftsByQuestionId(questionId);
  }

  @override
  Future<DraftQuestionThread> upsertDraft(
    DraftQuestionThread draft,
  ) async {
    final upsertResult = await _apiClient.chats.upsertDraft(draft);

    if (upsertResult.wasCreated) {
      _draftCreatedStreamController
          .add(DraftCreatedEvent(draft: upsertResult.draft));
    }

    _draftUpsertStreamController.add(
      DraftUpsertEvent(
        draft: upsertResult.draft,
      ),
    );

    return upsertResult.draft;
  }

  @override
  Future<DraftQuestionThread?> publishDraft(String draftId) async {
    final publishedDraft = await _apiClient.chats.publishDraft(draftId);

    _draftPublishedStreamController.add(
      DraftPublishedEvent(
        draft: publishedDraft,
      ),
    );

    return publishedDraft;
  }

  @override
  Future<void> deleteDraft(DraftQuestionThread draft) async {
    await _apiClient.chats.deleteDraftQuestionThread(draft.id!);

    _draftDeleteStreamController.add(
      DraftDeleteEvent(
        draft: draft,
      ),
    );
    return;
  }

  @override
  Future<PaginatedDraftQuestionThreadList> listDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    return _apiClient.chats
        .listDraftQuestionThreads(chatThreadId: chatThreadId, pageUrl: pageUrl);
  }

  @override
  Future<PaginatedQuestions> listPaginatedQuestionsOfDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    return _apiClient.chats.listPaginatedQuestionsOfDraftQuestionThreads(
      chatThreadId: chatThreadId,
      pageUrl: pageUrl,
    );
  }

  @override
  Future<ChatThreadStats> getChatThreadStats({String? chatThreadId}) async {
    return _apiClient.chats.getChatThreadStats(chatThreadId: chatThreadId);
  }
}
