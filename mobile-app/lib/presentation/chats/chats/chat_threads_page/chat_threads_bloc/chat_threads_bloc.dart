import 'dart:async';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'chat_threads_event.dart';
part 'chat_threads_state.dart';

// TODO: this was one of my first bloc and it's disgusting. Deserves a refactor.
class ChatThreadsBloc extends Bloc<ChatThreadsEvent, ChatThreadsState>
    with BlocLogger {
  ChatThreadsBloc({
    required ChatThreadsRepo chatThreadsRepo,
    required InvitationsRepo invitationsRepo,
    required BehaviorSubject<int> numTotalNotificationsController,
  })  : _chatThreadsRepo = chatThreadsRepo,
        _numTotalNotificationsController = numTotalNotificationsController,
        super(const ChatThreadsState.loading()) {
    // TODO: current user should probably be set after logging in as a global.

    _chatThreadsRepo.getAllChatThreads();
    _chatThreadRepoSubscription = _chatThreadsRepo.dataSourceStream.listen(
      (items) {
        add(ChatThreadsConsumedDataFromSource(chatThreads: items));
      },
      onError: (Object error) =>
          add(ChatThreadsConsumerDataError(errorMessage: error.toString())),
    );

    // If the user accepts an invitation, re-fetch all chat threads
    invitationsRepo.invitationAcceptedStream
        .listen((_) => _chatThreadsRepo.getAllChatThreads());

    on<ChatThreadsConsumedDataFromSource>(
      _onChatThreadsConsumedDataFromSource,
    );
    on<ChatThreadRealtimeUpdate>(_onRealtimeUpdate);
    on<ChatThreadRealtimeUpdateNotifications>(_updateNumNotifications);
  }

  final ChatThreadsRepo _chatThreadsRepo;
  final BehaviorSubject<int> _numTotalNotificationsController;

  late final StreamSubscription<List<ChatThread>> _chatThreadRepoSubscription;
  StreamSubscription<QuestionChatsSeenEvent>?
      _questionChatsSeenEventSubscription;

  final StreamController<String> _realtimeStreamController =
      StreamController<String>();

  List<String> filterInterlocutors(
    List<Interlocutor> interlocutors,
    String? nameToExclude,
  ) {
    return interlocutors
        .where((interlocutor) => interlocutor.name != nameToExclude)
        .map((interlocutor) => interlocutor.name)
        .toList();
  }

  void _onRealtimeUpdate(
    ChatThreadRealtimeUpdate newChatThreadRealtimeUpdate,
    Emitter<ChatThreadsState> emit,
  ) {
    if (state.status == ChatThreadsStatus.loaded) {
      final oldState = state;
      final newChatThread = newChatThreadRealtimeUpdate.chatThread;
      // Determine if the chat thread already exists
      final existingChatThreadIndex = oldState.chatThreads
          .indexWhere((chatThread) => chatThread.id == newChatThread.id);
      final updatedChatThreads = List<ChatThread>.from(oldState.chatThreads);

      if (existingChatThreadIndex >= 0) {
        // Update the existing chat thread
        updatedChatThreads[existingChatThreadIndex] = newChatThread;
      } else {
        // Add the new chat thread
        updatedChatThreads.add(newChatThread);
      }

      return emit(oldState.copyWith(chatThreads: updatedChatThreads));
    }
  }

  // TODO: derive from hive box
  void _updateNumNotifications(
    ChatThreadRealtimeUpdateNotifications event,
    Emitter<ChatThreadsState> emit,
  ) {
    if (state.status == ChatThreadsStatus.loaded) {
      final oldState = state;
      final newQuestionThread = event.questionThread;

      final updatedChatThreads = oldState.chatThreads.map((chatThread) {
        if (chatThread.id == newQuestionThread.chatThread) {}
        // This is the chat thread linked to the updated question,
        // so we increment numNewUnseenMessages by 1
        return chatThread.copyWith(
          numNewUnseenMessages: chatThread.numNewUnseenMessages != null
              ? chatThread.numNewUnseenMessages! + 1
              : 1,
        );
      }).toList();
      _numTotalNotificationsController
          .add(_numTotalNotificationsController.value + 1);

      return emit(
        oldState.copyWith(chatThreads: updatedChatThreads),
      );
    }
  }

  void _onChatThreadsConsumedDataFromSource(
    ChatThreadsConsumedDataFromSource event,
    Emitter<ChatThreadsState> emit,
  ) {
    // sort chatThreads by updatedAt in descending order
    event.chatThreads.sort(
      (a, b) =>
          DateTime.parse(b.updatedAt).compareTo(DateTime.parse(a.updatedAt)),
    );

    // Calculating the sum of all numNewUnseenMessages
    final totalUnseenMessages = event.chatThreads.fold(0, (sum, chatThread) {
      return sum + (chatThread.numNewUnseenMessages ?? 0);
    });

    _numTotalNotificationsController.add(totalUnseenMessages);
    return emit(
      ChatThreadsState.loaded(event.chatThreads),
    );
  }

  @override
  Future<void> close() {
    _chatThreadRepoSubscription.cancel();
    _questionChatsSeenEventSubscription?.cancel();
    _realtimeStreamController.close();
    return super.close();
  }
}
