import 'dart:async';

import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/realtime_repo/realtime_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:loggy/loggy.dart';

part 'question_chats_page_state.dart';

const chatbondUser = 'chatbond';

class QuestionChatsPageCubit extends Cubit<QuestionChatsPageState> {
  QuestionChatsPageCubit({
    required Question question,
    required ChatThreadsRepo chatThreadsRepo,
    required List<Interlocutor> interlocutors,
    required RealtimeRepo realtimeRepo,
    required void Function() onSetToSeenSucceeded,
  })  : _question = question,
        _chatThreadsRepo = chatThreadsRepo,
        _interlocutors = interlocutors,
        _onSetToSeenSucceededCallback = onSetToSeenSucceeded,
        super(QuestionChatsPageInitial()) {
    _questionChatRealtimeSubscription =
        realtimeRepo.questionChatRealtimeEventController.stream.listen(
      (realtimeUpdateEvent) {
        logInfo(
          'QuestionChatsPageCubit received a new QuestionChat update event',
        );

        final newQuestionChat =
            QuestionChat.fromJson(realtimeUpdateEvent.data.content);
        logDebug(
          'QuestionChatsPageCubit deserialized a QuestionChat: $newQuestionChat',
        );
        try {
          final flutterChatMessage =
              convertToFlutterChatMessages([newQuestionChat])[0];
          appendQuestionChatInRealTime(flutterChatMessage);
          logInfo(
            'QuestionChatsPageCubit appended a new QuestionChat to the question thread',
          );
        } catch (e) {
          logError(
            'QuestionChatsPageCubit failed to update the question thread: $e',
          );
        }
      },
    );
  }

  final Question _question;
  final ChatThreadsRepo _chatThreadsRepo;
  final void Function() _onSetToSeenSucceededCallback;
  late Interlocutor? currentInterlocutor;
  late String _questionThreadId;
  late final List<Interlocutor> _interlocutors;
  Map<String, chat_types.User>? _cachedInterlocutorIdToChatUsersMap;
  late final StreamSubscription<RealtimeUpdateEvent>
      _questionChatRealtimeSubscription;

  Map<String, chat_types.User> interlocutorsToChatUsersMap() {
    if (_cachedInterlocutorIdToChatUsersMap != null) {
      return _cachedInterlocutorIdToChatUsersMap!;
    }
    final chatUsersMap = <String, chat_types.User>{};

    for (final interlocutor in _interlocutors) {
      final chatUser = interlocutor.toFlutterChatUser();
      chatUsersMap[interlocutor.id] = chatUser;
    }
    _cachedInterlocutorIdToChatUsersMap = chatUsersMap;
    return chatUsersMap;
  }

  List<chat_types.Message> convertToFlutterChatMessages(
    List<QuestionChat> questionChats,
  ) {
    final interlocutorIdToChatUserMap = interlocutorsToChatUsersMap();

    return questionChats.map<chat_types.Message>((questionChat) {
      final user = interlocutorIdToChatUserMap[questionChat.authorId]!;

      return questionChat.toFlutterChatMessage(
        currentInterlocutorId: questionChat.authorId,
        user: user,
      );
    }).toList();
  }

  Future<void> loadQuestionChats(String questionThreadId) async {
    _questionThreadId = questionThreadId;
    // Check if messagesByThreadId has the questionThreadId, otherwise emit loading state
    if (!state.messagesByThreadId.containsKey(questionThreadId)) {
      emit(QuestionChatsPageLoading());
    }

    currentInterlocutor = await _chatThreadsRepo.getCurrentInterlocutor();
    try {
      final questionChats =
          await _chatThreadsRepo.getQuestionChats(_questionThreadId);
      final messages = convertToFlutterChatMessages(questionChats);

      // Add a new message at the beginning of the messages list with the author "chatBond" and createdAt=question.createdAd
      final questionMessage = chat_types.SystemMessage(
        type: MessageType.system,
        author: chat_types.User(
          id: chatbondUser,
          firstName: chatbondUser,
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        ),
        createdAt: DateTime.parse(_question.createdAt).millisecondsSinceEpoch,
        id: _question.id,
        roomId: _questionThreadId,
        text: _question.content,
        status: chat_types.Status.sent,
      );

      messages.add(questionMessage);

      final setToSeenSucceeded =
          await _chatThreadsRepo.setQuestionChatsSeenAt(_questionThreadId);

      if (setToSeenSucceeded) {
        // Call callback to update the chatThread in the QuestionThreads view
        _onSetToSeenSucceededCallback();
        await _chatThreadsRepo.getAllChatThreads();
      }
      logDebug('messages: $messages');

      // Update the messages map
      final updatedMessagesByThreadId =
          Map<String, List<chat_types.Message>>.from(state.messagesByThreadId);
      updatedMessagesByThreadId[_questionThreadId] = messages;

      emit(
        QuestionChatsPageLoaded(
          messagesByThreadId: updatedMessagesByThreadId,
          user: currentInterlocutor!.toFlutterChatUser(),
          question: _question, // TODO: not currently used
        ),
      );
    } catch (e) {
      emit(QuestionChatsPageError(message: e.toString()));
    }
  }

  // TODO: not efficient, improve once we hit 10,000 chat threads
  Future<void> addQuestionChatForCurrentUserAsAuthor(
    chat_types.PartialText message,
  ) async {
    if (state is QuestionChatsPageLoaded) {
      final oldState = state as QuestionChatsPageLoaded;
      final newMessage = chat_types.TextMessage(
        author: currentInterlocutor!.toFlutterChatUser(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now()
            .toIso8601String(), // Temporary ID until confirmed from the server
        roomId: _questionThreadId,
        text: message.text,
        status: chat_types.Status.sending,
      );

      // Update the messages map
      final updatedMessagesByThreadId =
          Map<String, List<chat_types.Message>>.from(state.messagesByThreadId);
      updatedMessagesByThreadId[_questionThreadId]!.add(newMessage);

      /// Update local UI
      emit(
        oldState.copyWith(
          messagesByThreadId: updatedMessagesByThreadId,
          user: currentInterlocutor!.toFlutterChatUser(),
        ),
      );

      try {
        await _chatThreadsRepo.createQuestionChat(
          _questionThreadId,
          message.text,
          contentStatusToString(ContentStatus.pending),
        );
        await loadQuestionChats(_questionThreadId);
      } catch (e) {
        updatedMessagesByThreadId[_questionThreadId]!
            .removeLast(); // Remove the message with the "sending" status
        updatedMessagesByThreadId[_questionThreadId]!.add(
          newMessage.copyWith(
            status: chat_types.Status.error,
          ),
        ); // Add the updated message with the "error" status

        /// Failed to send message, undo optimistic update of UI
        /// TODO: should return an error field within the state so UI
        /// can show an error notification
        emit(
          oldState.copyWith(
            messagesByThreadId: updatedMessagesByThreadId,
            user: currentInterlocutor!.toFlutterChatUser(),
          ),
        );
      }
    }
  }

  Future<void> appendQuestionChatInRealTime(
    chat_types.Message flutterChatMessage,
  ) async {
    if (state is QuestionChatsPageLoaded) {
      // TODO: this is a hack and reloads all messages for every new message x,
      // even if message x was received from BE...just for POC
      await loadQuestionChats(_questionThreadId);

      // Execute the callback to indicate that the message has been seen
      _onSetToSeenSucceededCallback();
    } else {
      logError(
        'Cannot append message. The state is not QuestionChatsPageLoaded.',
      );
    }
  }

  void dispose() {
    _questionChatRealtimeSubscription.cancel();
  }
}

extension QuestionChatToFlutterChatMessage on QuestionChat {
  chat_types.TextMessage toFlutterChatMessage({
    required String currentInterlocutorId,
    required chat_types.User user,
  }) {
    chat_types.Status messageStatus;

    if (currentInterlocutorId == authorId) {
      messageStatus = chat_types.Status.sent;
    } else {
      final interactionEvent =
          interactionEvents.isNotEmpty ? interactionEvents.first : null;
      if (interactionEvent != null && interactionEvent.seenAt != null) {
        messageStatus = chat_types.Status.seen;
      } else if (interactionEvent != null &&
          interactionEvent.receivedAt != null) {
        messageStatus = chat_types.Status.delivered;
      } else {
        messageStatus = chat_types.Status.sending;
      }
    }

    return chat_types.TextMessage(
      author: user,
      createdAt: createdAt.millisecondsSinceEpoch,
      id: id,
      roomId: questionThread,
      text: content,
      status: messageStatus,
      showStatus: true,
    );
  }
}

extension FlutterChatMessageToQuestionChat on chat_types.TextMessage {
  QuestionChat toQuestionChat({
    required String currentInterlocutorId,
    required chat_types.User user,
  }) {
    return QuestionChat(
      id: id,
      authorId: user.id,
      authorName: user.firstName!,
      questionThread: roomId!,
      content: text,
      status: currentInterlocutorId == user.id ? 'sent' : 'delivered',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt!),
      updatedAt: DateTime.now(),
      interactionEvents: const [], // You might need to adjust this based on your use case
    );
  }
}

extension InterlocutorToFlutterChatUser on Interlocutor {
  chat_types.User toFlutterChatUser() {
    return chat_types.User(
      id: id,
      firstName: name,
      lastName: '',
      // createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
      // lastSeen: DateTime.parse(updatedAt).millisecondsSinceEpoch, // Removed from BE as it's sensitive and shouldn't be shared with everyone
    );
  }
}

enum ContentStatus { published, pending, draft, deleted }

// Convert a string to a ContentStatus enum value
ContentStatus contentStatusFromString(String status) {
  switch (status) {
    case 'published':
      return ContentStatus.published;
    case 'pending':
      return ContentStatus.pending;
    case 'draft':
      return ContentStatus.draft;
    case 'deleted':
      return ContentStatus.deleted;
    default:
      throw ArgumentError('Invalid content status: $status');
  }
}

// Convert a ContentStatus enum value to a string
String contentStatusToString(ContentStatus status) {
  switch (status) {
    case ContentStatus.published:
      return 'published';
    case ContentStatus.pending:
      return 'pending';
    case ContentStatus.draft:
      return 'draft';
    case ContentStatus.deleted:
      return 'deleted';
    default:
      throw ArgumentError('Invalid content status: $status');
  }
}
