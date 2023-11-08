import 'dart:async';
import 'dart:convert';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

/// TODO: currently, realtime notifs are pushed from BE and received by
/// RealtimeRepo, which then triggers some BE calls to refresh local data.
/// This is clearly inneficient as the same objects (and more...) are
/// transiting over the wire for these transactions. Now, it's not anticipated
/// that realtime notifs take a huge amount of the total bandwidth. So, for now,
/// it is an acceptable compromise to get a POC to market asap.
class RealtimeRepo with RepoLogger {
  RealtimeRepo({
    required ApiClient apiClient,
    required String userId,
    required ChatThreadsRepo chatsRepo, // TODO: this is a hack, see doc above
  }) : _apiClient = apiClient {
    logInfo('Initializing RealtimeRepo...');
    _apiClient.realtime.init();
    _apiClient.realtime.connect(() {});
    _apiClient.realtime
        .subscribe('personal:#$userId', _externalEventController.sink);

    // Listen to the Realtime stream and dispatch events based on incoming messages
    _realtimeStreamSubscription = externalEventStream.listen(
      (message) {
        logInfo('RealtimeRepo received a new message from BE: $message');
        late Map<String, dynamic> jsonObject;
        try {
          jsonObject = jsonDecode(message) as Map<String, dynamic>;
        } catch (e) {
          logError('Failed to decode incoming message as json: $e');
        }
        try {
          final realtimeUpdateEvent = RealtimeUpdateEvent.fromJson(jsonObject);
          logInfo('realtimeUpdateEvent: $realtimeUpdateEvent');
          switch (realtimeUpdateEvent.data.type) {
            case RealtimePayloadType.questionThread:
              questionThreadRealtimeEventController.sink
                  .add(realtimeUpdateEvent);
              logDebug(
                'RealtimeRepo added QuestionThread object in public sink',
              );
              chatsRepo
                  .getAllChatThreads(); // TODO: this is a hack, see doc above
              break;
            case RealtimePayloadType.chatThread:
              chatThreadRealtimeEventController.sink.add(realtimeUpdateEvent);
              logDebug('RealtimeRepo added ChatThread object in public sink');
              chatsRepo
                  .getAllChatThreads(); // TODO: this is a hack, see doc above
              break;
            case RealtimePayloadType.questionChat:
              questionChatRealtimeEventController.sink.add(realtimeUpdateEvent);
              logDebug('RealtimeRepo added QuestionChat object in public sink');
              chatsRepo
                  .getAllChatThreads(); // TODO: this is a hack, see doc above
              break;
            case RealtimePayloadType.invitation:
              invitationRealtimeEventController.sink.add(realtimeUpdateEvent);
              logDebug('RealtimeRepo added Invitation object in public sink');
              chatsRepo
                  .getAllChatThreads(); // TODO: this is a hack, see doc above
              chatsRepo
                  .getChatInterlocutors(); // TODO: again a hack. Gets all the interlocutors, including the new one
          }
        } catch (e) {
          // TODO: remove log for prod
          logError(
            'failed to parse incoming message into a RealtimeUpdate object: $e',
          );
          throw Exception(
            'Failed to parse incoming message into a RealtimeUpdate object: $e',
          );
        }
      },
    );
  }

  final ApiClient _apiClient;

  // Stream to push update events to
  final _externalEventController = StreamController<String>.broadcast();

  Stream<String> get externalEventStream => _externalEventController.stream;
  late final StreamSubscription<String> _realtimeStreamSubscription;

  // Streams to consume sorted objects
  final chatThreadRealtimeEventController =
      StreamController<RealtimeUpdateEvent>.broadcast();

  final questionThreadRealtimeEventController =
      StreamController<RealtimeUpdateEvent>.broadcast();

  final questionChatRealtimeEventController =
      StreamController<RealtimeUpdateEvent>.broadcast();

  final invitationRealtimeEventController =
      StreamController<RealtimeUpdateEvent>.broadcast();

  void connect(VoidCallback onConnect) {
    _apiClient.realtime.connect(onConnect);
  }

  void subscribeChannel(String channel, StreamSink<String> streamSink) {
    _apiClient.realtime.subscribe(channel, streamSink);
  }

  void dispose() {
    _apiClient.realtime.dispose();
    chatThreadRealtimeEventController.close();
    questionThreadRealtimeEventController.close();
    questionChatRealtimeEventController.close();
    _realtimeStreamSubscription.cancel();
  }
}
