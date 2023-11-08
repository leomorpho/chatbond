import 'dart:async';

import 'package:chatbond/bootstrap.dart';
import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/db/db.dart';
import 'package:chatbond/data/db/hive/draft_question_thread.dart';
import 'package:chatbond/data/db/hive/question.dart';
import 'package:chatbond/data/db/hive/question_chat_interaction_event.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/realtime_repo/realtime_repo.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loggy/loggy.dart';

// LocalHiveRepo uses the singleton pattern.
// The single instance of LocalHiveRepo listens to the RealtimeRepo for updates
// and saves these updates into Hive boxes. It also provides streams that emit
// the current state of the Hive boxes whenever they are updated.
//
// Every object type that must be persisted in the local DB should have an
// associated sink stream passed to LocalHiveRepo's constructor.
class LocalHiveRepo with RepoLogger {
  // Private constructor to enforce the singleton pattern.
  LocalHiveRepo._({
    required this.realtimeRepo,
    required this.chatThreadsBox,
    required this.questionThreadsBox,
    required this.questionChatsBox,
    required this.interlocutorsBox,
    required Stream<List<ChatThread>> chatThreadsStream,
    required Stream<List<QuestionThread>> questionThreadsStream,
    required Stream<List<QuestionChat>> questionChatsStream,
    required Stream<List<Interlocutor>> interlocutorsStream,
    required this.chatThreadsRequestsSink,
    required this.questionThreadsRequestsSink,
    required this.interlocutorRequestsSink,
    required this.numTotalNotificationsSink,
  }) {
    chatThreadsStream.listen(updateChatThreadBox);
    questionThreadsStream.listen(updateQuestionThreadBox);
    questionChatsStream.listen(updateQuestionChatBox);
    interlocutorsStream.listen(updateInterlocutorBox);

    // Listen to the RealtimeRepo and update the Hive boxes with new data.
    // The RealtimeRepo provides real-time updates from a WebSocket connection.
    _questionThreadRealtimeSubscription = realtimeRepo
        .questionThreadRealtimeEventController.stream
        .listen((realtimeUpdateEvent) {
      logInfo('LocalHiveRepo received a new QuestionThread update event');

      final newQuestionThread =
          QuestionThread.fromJson(realtimeUpdateEvent.data.content);
      logDebug(
        'LocalHiveRepo deserialized a QuestionThread: $newQuestionThread',
      );
      try {
        updateQuestionThreadBox([newQuestionThread]);
        logInfo(
          'LocalHiveRepo upserted a new QuestionThread object in hive box',
        );
      } catch (e) {
        logError('LocalHiveRepo failed to update QuestionThread box: $e');
      }
    });

    _chatThreadRealtimeSubscription =
        realtimeRepo.chatThreadRealtimeEventController.stream.listen(
      (realtimeUpdateEvent) {
        logInfo('LocalHiveRepo received a new ChatThread update event');

        final newChatThread =
            ChatThread.fromJson(realtimeUpdateEvent.data.content);
        logDebug('LocalHiveRepo deserialized a ChatThread: $newChatThread');

        try {
          updateChatThreadBox([newChatThread]);
          logInfo('LocalHiveRepo upserted a new ChatThread object in hive box');
        } catch (e) {
          logError('LocalHiveRepo failed to update ChatThread box: $e');
        }
      },
    );

    _questionChatRealtimeSubscription =
        realtimeRepo.questionChatRealtimeEventController.stream.listen(
      (realtimeUpdateEvent) {
        logInfo('LocalHiveRepo received a new QuestionChat update event');

        final newQuestionChat =
            QuestionChat.fromJson(realtimeUpdateEvent.data.content);
        logDebug(
          'LocalHiveRepo deserialized a QuestionChat: $newQuestionChat',
        );
        try {
          updateQuestionChatBox([newQuestionChat]);
          logInfo(
            'LocalHiveRepo upserted a new QuestionChat object in hive box',
          );
        } catch (e) {
          logError('LocalHiveRepo failed to update QuestionChat box: $e');
        }
      },
    );

    // Watch for changes in the Hive boxes and emit them through the streams.
    chatThreadsBox.watch().listen((event) {
      if (event.value is HiveChatThread) {
        final hiveChatThread = event.value as HiveChatThread;
        _chatThreadStreamController.add(_fromHiveChatThread(hiveChatThread));
        logInfo(
          'LocalHiveRepo emitted a new ChatThread to a public stream',
        );
      }
    });

    questionThreadsBox.watch().listen((event) {
      if (event.value is HiveQuestionThread) {
        final hiveQuestionThread = event.value as HiveQuestionThread;
        _questionThreadStreamController
            .add(_fromHiveQuestionThread(hiveQuestionThread));
        logInfo(
          'LocalHiveRepo emitted a new QuestionThread to a public stream',
        );
      }
    });

    questionChatsBox.watch().listen((event) {
      if (event.value is HiveQuestionChat) {
        final hiveQuestionChat = event.value as HiveQuestionChat;
        _questionChatStreamController
            .add(_fromHiveQuestionChat(hiveQuestionChat));
        logInfo(
          'LocalHiveRepo emitted a new QuestionChat to a public stream',
        );
      }
    });
  }

  // Initialization function that opens the Hive boxes and returns a
  // fully initialized instance of LocalHiveRepo.
  static Future<LocalHiveRepo> initialize({
    required RealtimeRepo realtimeRepo,
    required Stream<List<ChatThread>> chatThreadsStream,
    required Stream<List<QuestionThread>> questionThreadsStream,
    required Stream<List<QuestionChat>> questionChatsStream,
    required Stream<List<Interlocutor>> interlocutorsStream,
    required Sink<String> chatThreadsRequestsSink,
    required Sink<String> questionThreadsRequestsSink,
    required Sink<String> interlocutorRequestsSink,
    required Sink<int> numTotalNotificationsSink,
  }) async {
    logDebug(
      'LocalHiveRepo is initializing...',
    );

    final chatThreadsBox =
        await Hive.openBox<HiveChatThread>(hiveChatThreadsBoxKey);
    final questionThreadsBox =
        await Hive.openBox<HiveQuestionThread>(hiveQuestionThreadsBoxKey);
    final questionChatsBox =
        await Hive.openBox<HiveQuestionChat>(hiveQuestionChatsBoxKey);
    final interlocutorsBox =
        await Hive.openBox<HiveInterlocutor>(hiveInterlocutorBoxKey);

    final repo = LocalHiveRepo._(
      realtimeRepo: realtimeRepo,
      chatThreadsBox: chatThreadsBox,
      questionThreadsBox: questionThreadsBox,
      questionChatsBox: questionChatsBox,
      interlocutorsBox: interlocutorsBox,
      chatThreadsStream: chatThreadsStream,
      questionThreadsStream: questionThreadsStream,
      questionChatsStream: questionChatsStream,
      interlocutorsStream: interlocutorsStream,
      chatThreadsRequestsSink: chatThreadsRequestsSink,
      questionThreadsRequestsSink: questionThreadsRequestsSink,
      interlocutorRequestsSink: interlocutorRequestsSink,
      numTotalNotificationsSink: numTotalNotificationsSink,
    );

    logDebug(
      'LocalHiveRepo finished initializing',
    );

    // Create the LocalHiveRepo instance.
    return repo;
  }

  // To consume from realtime websocket.
  final RealtimeRepo realtimeRepo;
  late final StreamSubscription<RealtimeUpdateEvent>
      _chatThreadRealtimeSubscription;
  late final StreamSubscription<RealtimeUpdateEvent>
      _questionThreadRealtimeSubscription;
  late final StreamSubscription<RealtimeUpdateEvent>
      _questionChatRealtimeSubscription;

  // Hive boxes.
  final Box<HiveChatThread> chatThreadsBox;
  final Box<HiveQuestionThread> questionThreadsBox;
  final Box<HiveQuestionChat> questionChatsBox;
  final Box<HiveInterlocutor> interlocutorsBox;

  // Broadcast source of truth based on hive boxes.
  final _chatThreadStreamController = StreamController<ChatThread>.broadcast();
  Stream<ChatThread> get chatThreadUpdates =>
      _chatThreadStreamController.stream;

  final _questionThreadStreamController =
      StreamController<QuestionThread>.broadcast();
  Stream<QuestionThread> get questionThreadUpdates =>
      _questionThreadStreamController.stream;

  final _questionChatStreamController =
      StreamController<QuestionChat>.broadcast();
  Stream<QuestionChat> get questionChatUpdates =>
      _questionChatStreamController.stream;

  Sink<String> chatThreadsRequestsSink;
  Sink<String> questionThreadsRequestsSink;
  Sink<String> interlocutorRequestsSink;
  Sink<int> numTotalNotificationsSink;

  void updateChatThreadNotifications() {
    // Calculate the total count of unseen messages across all chat threads
    final currentCount = chatThreadsBox.values.fold<int>(
      0,
      (previousValue, chatThread) =>
          previousValue + (chatThread.numNewUnseenMessages ?? 0),
    );

    numTotalNotificationsSink.add(currentCount);
  }

  Future<void> updateChatThreadBox(List<ChatThread> chatThreads) async {
    logDebug('LocalHiveRepo is updating the ChatThread box...');

    for (final chatThread in chatThreads) {
      final key = chatThread.id;

      // NOTE: Below steps establishes a relationship between the HiveList and
      // the Box but does not add any objects.
      final hiveInterlocutors = HiveList(interlocutorsBox);

      for (final interlocutor in chatThread.interlocutors) {
        final hiveInterlocutor = interlocutorsBox.get(interlocutor.id);
        if (hiveInterlocutor == null) {
          interlocutorRequestsSink.add(interlocutor.id);
          logDebug(
            'updateChatThreadBox - request interlocutor with id ${interlocutor.id}',
          );
        } else {
          hiveInterlocutors.add(hiveInterlocutor);
        }
      }

      final hiveChatThread = HiveChatThread(
        id: chatThread.id,
        interlocutors: hiveInterlocutors,
        interlocutorIds: chatThread.interlocutors.map((e) => e.id).toList(),
        owner: _interlocutorToHive(chatThread.owner),
        updatedAt: chatThread.updatedAt,
        createdAt: chatThread.createdAt,
        numNewUnseenMessages: chatThread.numNewUnseenMessages,
      );

      // Add or update the chat thread in the box
      await chatThreadsBox.put(key, hiveChatThread);

      // Create a HiveList containing the chat thread
      final chatThreadHiveList = HiveList(chatThreadsBox)..add(hiveChatThread);

      // Update any missing links between questionThreads and chatThreads
      for (final questionThread in questionThreadsBox.values
          .where((qt) => qt.chatThreadId == chatThread.id)) {
        questionThread.chatThread = chatThreadHiveList;
        await questionThreadsBox.put(questionThread.id, questionThread);
      }
    }

    updateChatThreadNotifications();

    logDebug('LocalHiveRepo finished updating the ChatThread box');
  }

  Future<void> updateQuestionThreadBox(
    List<QuestionThread> questionThreads,
  ) async {
    logDebug('LocalHiveRepo is updating the QuestionThread box...');
    for (final questionThread in questionThreads) {
      final key = questionThread.id;

      final hiveChatThread = chatThreadsBox.get(questionThread.chatThread);
      if (hiveChatThread == null) {
        chatThreadsRequestsSink.add(questionThread.chatThread);
        logDebug(
          'updateQuestionThreadBox - request chat thread with id ${questionThread.chatThread}',
        );
      }
      HiveList? chatThreadHiveList;
      if (hiveChatThread != null) {
        // Create a list within the chatThreadsBox and add the hiveChatThread
        chatThreadHiveList = HiveList(chatThreadsBox)..add(hiveChatThread);
      }

      final hiveQuestionThread = HiveQuestionThread(
        id: questionThread.id,
        chatThread: chatThreadHiveList,
        chatThreadId: questionThread.chatThread,
        question: _questionToHiveQuestion(questionThread.question),
        updatedAt: questionThread.updatedAt,
        createdAt: questionThread.createdAt,
        allInterlocutorsAnswered: questionThread.allInterlocutorsAnswered,
        numNewUnseenMessages: questionThread.numNewUnseenMessages,
      );

      if (questionThreadsBox.containsKey(key)) {
        logDebug('LocalHiveRepo found QuestionThread to update in box');

        final existingQuestionThread = questionThreadsBox.get(key)!;
        if (existingQuestionThread != hiveQuestionThread) {
          await questionThreadsBox.put(key, hiveQuestionThread);
          logDebug('LocalHiveRepo updated a QuestionThread in box');
        }
      } else {
        await questionThreadsBox.put(key, hiveQuestionThread);

        if (hiveChatThread != null) {
          // Increase unseen message count for related ChatThread
          hiveChatThread.numNewUnseenMessages =
              hiveChatThread.numNewUnseenMessages! + 1;
          await chatThreadsBox.put(hiveChatThread.id, hiveChatThread);
        }

        logDebug('LocalHiveRepo added a new QuestionThread in box');
      }

      // Check if questionChats depend on the updated questionThreads,
      // and if yes, update relationships.
      final hiveQuestionThreadHiveList = HiveList(questionThreadsBox)
        ..add(hiveQuestionThread);
      for (final questionChat in questionChatsBox.values
          .where((qc) => qc.questionThreadId == questionThread.id)) {
        questionChat.questionThread = hiveQuestionThreadHiveList;
        await questionChatsBox.put(questionChat.id, questionChat);
      }
    }
    updateChatThreadNotifications();

    logDebug('LocalHiveRepo updated the QuestionThread box');
  }

  Future<void> updateQuestionChatBox(List<QuestionChat> questionChats) async {
    logDebug('LocalHiveRepo is updating the QuestionChat box...');

    for (final questionChat in questionChats) {
      final key = questionChat.id;

      final hiveQuestionThread =
          questionThreadsBox.get(questionChat.questionThread);
      if (hiveQuestionThread == null) {
        questionThreadsRequestsSink.add(questionChat.questionThread);
        logDebug(
          'updateQuestionChatBox - request question thread with id ${questionChat.questionThread}',
        );
      }

      HiveList? questionThreadHiveList;
      if (hiveQuestionThread != null) {
        questionThreadHiveList = HiveList(chatThreadsBox)
          ..add(hiveQuestionThread);
      }

      final hiveQuestionChat = HiveQuestionChat(
        id: questionChat.id,
        authorId: questionChat.authorId,
        authorName: questionChat.authorName,
        questionThread: questionThreadHiveList,
        questionThreadId: questionChat.questionThread,
        content: questionChat.content,
        status: questionChat.status,
        createdAt: questionChat.createdAt,
        updatedAt: questionChat.updatedAt,
        interactionEvents: questionChat.interactionEvents
            .map(_questionChatInteractionEventToHive)
            .toList(),
        seenByCurrInterlocutor: questionChat.hasInterlocutorSeenChat(
          getIt.get<GlobalState>().currentInterlocutor!.id,
        ),
      );

      if (questionChatsBox.containsKey(key)) {
        logDebug('LocalHiveRepo found QuestionChat to update in box');

        final existingQuestionChat = questionChatsBox.get(key)!;
        if (existingQuestionChat != hiveQuestionChat) {
          await questionChatsBox.put(key, hiveQuestionChat);
          logDebug('LocalHiveRepo updated a QuestionChat in box');
        }
      } else {
        await questionChatsBox.put(key, hiveQuestionChat);

        if (!questionChat.hasInterlocutorSeenChat(
          getIt.get<GlobalState>().currentInterlocutor!.id,
        )) {
          /**
           * TODO: the below update of unseen message count is VERY HACKY.
           * Ideally, we sync FE DB with BE DB and determine on the FE what the
           * unseen count is.
           */

          final hiveQuestionThread =
              questionThreadsBox.get(questionChat.questionThread);
          if (hiveQuestionThread == null) {
            questionThreadsRequestsSink.add(questionChat.questionThread);
            logDebug(
              'updateQuestionChatBox - request question thread with id ${questionChat.questionThread}',
            );
          }

          // Increase unseen message count for related QuestionThread
          if (hiveQuestionThread != null) {
            hiveQuestionThread.numNewUnseenMessages =
                hiveQuestionThread.numNewUnseenMessages! + 1;
            await questionThreadsBox.put(
              questionChat.questionThread,
              hiveQuestionThread,
            );
          }

          // TODO: below functionality must be reimplemented after refactor
          // // Below call will trigger updates to notifs count used by the tab bar
          // await chatThreadsRepo.getAllChatThreads();
        }

        logDebug('LocalHiveRepo added a new QuestionChat in box');
      }
    }
    logDebug('LocalHiveRepo updated the QuestionChat box.');
  }

  void updateInterlocutorBox(List<Interlocutor> interlocutors) {
    logDebug('LocalHiveRepo is updating the Interlocutor box...');

    for (final interlocutor in interlocutors) {
      final key = interlocutor.id;

      final hiveInterlocutor = HiveInterlocutor(
        id: interlocutor.id,
        userId: interlocutor.userId,
        name: interlocutor.name,
        username: interlocutor.username,
        email: interlocutor.email,
        createdAt: interlocutor.createdAt,
        updatedAt: interlocutor.updatedAt,
      );

      // Check if the box contains an item with the given key.
      if (interlocutorsBox.containsKey(key)) {
        logDebug('LocalHiveRepo found Interlocutor to update in box');
        final existingInterlocutor = interlocutorsBox.get(key)!;

        // If the existing item and the new item are not equal, update the box.
        if (existingInterlocutor != hiveInterlocutor) {
          interlocutorsBox.put(key, hiveInterlocutor);
          logDebug('LocalHiveRepo updated an Interlocutor in box');
        }
      } else {
        // If the box does not contain the item, add it.
        interlocutorsBox.put(key, hiveInterlocutor);
        logDebug('LocalHiveRepo added a new Interlocutor in box');
      }
    }

    // Check if other objects depend on the updated interlocutors,
    // and if yes, update relationships.
    for (final hiveChatThread in chatThreadsBox.values) {
      final idsToFind = hiveChatThread.interlocutorIds;

      // Create a HiveList for the new interlocutors
      final newInterlocutors = HiveList(interlocutorsBox);

      // Find the interlocutors in the interlocutorsBox using their IDs
      for (final id in idsToFind) {
        final interlocutor = interlocutorsBox.get(id);
        if (interlocutor != null) {
          newInterlocutors.add(interlocutor);
        }
      }
      // If the interlocutors have changed, update the chat thread
      if (hiveChatThread.interlocutors != newInterlocutors) {
        hiveChatThread.interlocutors =
            newInterlocutors; // Update the interlocutors field
        chatThreadsBox.put(
          hiveChatThread.id,
          hiveChatThread,
        ); // Save the updated chat thread
        logDebug('LocalHiveRepo updated ChatThread with new interlocutors');
      }
    }

    logDebug('LocalHiveRepo updated the Interlocutor box.');
  }

  Interlocutor _fromHiveInterlocutor(HiveInterlocutor hiveInterlocutor) {
    return Interlocutor(
      id: hiveInterlocutor.id,
      userId: hiveInterlocutor.userId,
      name: hiveInterlocutor.name,
      username: hiveInterlocutor.username,
      email: hiveInterlocutor.email,
      createdAt: hiveInterlocutor.createdAt,
      updatedAt: hiveInterlocutor.updatedAt,
    );
  }

  HiveInterlocutor _interlocutorToHive(Interlocutor interlocutor) {
    return HiveInterlocutor(
      id: interlocutor.id,
      userId: interlocutor.userId,
      name: interlocutor.name,
      username: interlocutor.username,
      email: interlocutor.email,
      createdAt: interlocutor.createdAt,
      updatedAt: interlocutor.updatedAt,
    );
  }

  ChatThread _fromHiveChatThread(HiveChatThread hiveChatThread) {
    final interlocutors = hiveChatThread.interlocutors
        ?.cast<HiveInterlocutor>()
        .map(_fromHiveInterlocutor)
        .toList();

    if (interlocutors == null) {
      throw ('_fromHiveChatThread - interlocutors is null for hiveChatThreads with id ${hiveChatThread.id}');
    }
    return ChatThread(
      id: hiveChatThread.id,
      interlocutors: interlocutors,
      owner: _fromHiveInterlocutor(hiveChatThread.owner),
      updatedAt: hiveChatThread.updatedAt,
      createdAt: hiveChatThread.createdAt,
      numNewUnseenMessages: hiveChatThread.numNewUnseenMessages,
    );
  }

  QuestionThread _fromHiveQuestionThread(
    HiveQuestionThread hiveQuestionThread,
  ) {
    return QuestionThread(
      id: hiveQuestionThread.id,
      chatThread:
          _fromHiveChatThread(hiveQuestionThread.chatThread! as HiveChatThread)
              .id,
      question: _hiveQuestionToQuestion(hiveQuestionThread.question),
      updatedAt: hiveQuestionThread.updatedAt,
      createdAt: hiveQuestionThread.createdAt,
      allInterlocutorsAnswered: hiveQuestionThread.allInterlocutorsAnswered,
      numNewUnseenMessages: hiveQuestionThread.numNewUnseenMessages,
    );
  }

  HiveChatThread _chatThreadToHive(ChatThread chatThread) {
    final hiveInterlocutors = HiveList(interlocutorsBox);
    for (final interlocutor in chatThread.interlocutors) {
      final hiveInterlocutor = interlocutorsBox.get(interlocutor.id);
      if (hiveInterlocutor == null) {
        throw Exception(
          'Interlocutor should exist in DB before adding linked chat thread',
        );
      }
      hiveInterlocutors.add(hiveInterlocutor);
    }

    return HiveChatThread(
      id: chatThread.id,
      interlocutors: hiveInterlocutors,
      interlocutorIds: chatThread.interlocutors.map((e) => e.id).toList(),
      owner: _interlocutorToHive(chatThread.owner),
      updatedAt: chatThread.updatedAt,
      createdAt: chatThread.createdAt,
      numNewUnseenMessages: chatThread.numNewUnseenMessages,
    );
  }

  HiveQuestionThread _questionThreadToHive(QuestionThread questionThread) {
    final chatThread = chatThreadsBox.get(questionThread.chatThread);
    if (chatThread == null) {
      throw Exception(
        'ChatThread should exist in DB before adding linked questionThread',
      );
    }

    return HiveQuestionThread(
      id: questionThread.id,
      chatThread: HiveList(chatThreadsBox)..add(chatThread),
      chatThreadId: questionThread.chatThread,
      question: _questionToHiveQuestion(questionThread.question),
      updatedAt: questionThread.updatedAt,
      createdAt: questionThread.createdAt,
      allInterlocutorsAnswered: questionThread.allInterlocutorsAnswered,
      numNewUnseenMessages: questionThread.numNewUnseenMessages,
    );
  }

  QuestionChat _fromHiveQuestionChat(HiveQuestionChat hiveQuestionChat) {
    return QuestionChat(
      id: hiveQuestionChat.id,
      authorId: hiveQuestionChat.authorId,
      authorName: hiveQuestionChat.authorName,
      questionThread: _fromHiveQuestionThread(
        hiveQuestionChat.questionThread as HiveQuestionThread,
      ).id,
      content: hiveQuestionChat.content,
      status: hiveQuestionChat.status,
      createdAt: hiveQuestionChat.createdAt,
      updatedAt: hiveQuestionChat.updatedAt,
      interactionEvents: hiveQuestionChat.interactionEvents
          .map(_fromHiveQuestionChatInteractionEvent)
          .toList(),
    );
  }

  HiveQuestionChat _questionChatToHive(QuestionChat questionChat) {
    final questionThread = questionThreadsBox.get(questionChat.questionThread);
    if (questionThread == null) {
      throw Exception(
        'QuestionThread should exist in DB before adding linked questionChat',
      );
    }

    return HiveQuestionChat(
      id: questionChat.id,
      authorId: questionChat.authorId,
      authorName: questionChat.authorName,
      questionThread: HiveList(questionThreadsBox)..add(questionThread),
      questionThreadId: questionChat.questionThread,
      content: questionChat.content,
      status: questionChat.status,
      createdAt: questionChat.createdAt,
      updatedAt: questionChat.updatedAt,
      interactionEvents: questionChat.interactionEvents
          .map(_questionChatInteractionEventToHive)
          .toList(),
      seenByCurrInterlocutor: questionChat.hasInterlocutorSeenChat(
        getIt.get<GlobalState>().currentInterlocutor!.id,
      ),
    );
  }

  QuestionChatInteractionEvent _fromHiveQuestionChatInteractionEvent(
    HiveQuestionChatInteractionEvent hiveEvent,
  ) {
    return QuestionChatInteractionEvent(
      interlocutor: hiveEvent.interlocutor,
      receivedAt: hiveEvent.receivedAt,
      seenAt: hiveEvent.seenAt,
    );
  }

  HiveQuestionChatInteractionEvent _questionChatInteractionEventToHive(
    QuestionChatInteractionEvent event,
  ) {
    return HiveQuestionChatInteractionEvent(
      interlocutor: event.interlocutor,
      receivedAt: event.receivedAt,
      seenAt: event.seenAt,
    );
  }

  HiveQuestion _questionToHiveQuestion(Question question) {
    return HiveQuestion(
      id: question.id,
      cumulativeVotingScore: question.cumulativeVotingScore,
      timesVoted: question.timesVoted,
      timesAnswered: question.timesAnswered,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt,
      content: question.content,
      isActive: question.isActive,
      author: question.author != null
          ? _interlocutorToHive(question.author!)
          : null,
      isPrivate: question.isPrivate,
      status: question.status != null
          ? question.statusToJson(question.status)
          : null,
      isFavorited: question.isFavorited,
      currInterlocutorVotingStatus:
          question.ratingToJson(question.currInterlocutorVotingStatus) ??
              VoteStatus.neutral.toString(),
      answeredByFriends: question.answeredByFriends,
      unpublishedDrafts: question.unpublishedDrafts
          ?.map(_fromDraftToHiveQuestionThread)
          .toList(),
      publishedDrafts: question.publishedDrafts
          ?.map(_fromDraftToHiveQuestionThread)
          .toList(),
    );
  }

  Question _hiveQuestionToQuestion(HiveQuestion hiveQuestion) {
    return Question(
      id: hiveQuestion.id,
      cumulativeVotingScore: hiveQuestion.cumulativeVotingScore,
      timesVoted: hiveQuestion.timesVoted,
      timesAnswered: hiveQuestion.timesAnswered,
      createdAt: hiveQuestion.createdAt,
      updatedAt: hiveQuestion.updatedAt,
      content: hiveQuestion.content,
      isActive: hiveQuestion.isActive,
      author: hiveQuestion.author != null
          ? _fromHiveInterlocutor(hiveQuestion.author!)
          : null, // Assuming you have a conversion method here
      isPrivate: hiveQuestion.isPrivate,
      status: hiveQuestion.status != null
          ? Question.statusFromJson(hiveQuestion.status!)
          : null,
      isFavorited: hiveQuestion.isFavorited,
      currInterlocutorVotingStatus:
          Question.ratingFromJson(hiveQuestion.currInterlocutorVotingStatus),

      answeredByFriends: hiveQuestion.answeredByFriends,
      unpublishedDrafts: hiveQuestion.unpublishedDrafts
          ?.map(_fromHiveDraftQuestionThread)
          .toList(),
      publishedDrafts: hiveQuestion.publishedDrafts
          ?.map(_fromHiveDraftQuestionThread)
          .toList(),
    );
  }

  DraftQuestionThread _fromHiveDraftQuestionThread(
    HiveDraftQuestionThread hiveThread,
  ) {
    return DraftQuestionThread(
      id: hiveThread.id,
      chatThread: hiveThread.chatThread,
      content: hiveThread.content,
      createdAt: hiveThread.createdAt,
      question: hiveThread.question,
      otherInterlocutor: _fromHiveInterlocutor(hiveThread.otherInterlocutor),
      publishedAt: hiveThread.publishedAt,
      questionThread: hiveThread.questionThread,
    );
  }

  HiveDraftQuestionThread _fromDraftToHiveQuestionThread(
    DraftQuestionThread thread,
  ) {
    return HiveDraftQuestionThread(
      id: thread.id,
      chatThread: thread.chatThread,
      content: thread.content,
      createdAt: thread.createdAt,
      question: thread.question,
      otherInterlocutor: _interlocutorToHive(thread.otherInterlocutor),
      publishedAt: thread.publishedAt,
      questionThread: thread.questionThread,
    );
  }

  void dispose() {
    logDebug('Disposing of LocalHiveRepo...');
    _chatThreadRealtimeSubscription.cancel();
    _questionThreadRealtimeSubscription.cancel();
    _questionChatRealtimeSubscription.cancel();

    _chatThreadStreamController.close();
    _questionThreadStreamController.close();
    _questionChatStreamController.close();

    chatThreadsBox.close();
    questionThreadsBox.close();
    questionChatsBox.close();
    logDebug('Disposed of LocalHiveRepo.');
  }
}
