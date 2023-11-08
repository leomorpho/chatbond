part of 'chat_threads_bloc.dart';

@immutable
abstract class ChatThreadsEvent extends Equatable {
  const ChatThreadsEvent();

  @override
  List<Object> get props => [];
}

class ChatThreadsConsumedDataFromSource extends ChatThreadsEvent {
  const ChatThreadsConsumedDataFromSource({required this.chatThreads});
  final List<ChatThread> chatThreads;

  @override
  List<Object> get props => [chatThreads];
}

class ChatThreadRealtimeUpdate extends ChatThreadsEvent {
  const ChatThreadRealtimeUpdate({required this.chatThread});
  final ChatThread chatThread;

  @override
  List<Object> get props => [chatThread];
}

class ChatThreadRealtimeUpdateNotifications extends ChatThreadsEvent {
  const ChatThreadRealtimeUpdateNotifications({required this.questionThread});
  final QuestionThread questionThread;

  @override
  List<Object> get props => [questionThread];
}

class ChatThreadsConsumerDataError extends ChatThreadsEvent {
  const ChatThreadsConsumerDataError({required this.errorMessage});
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}

class ChatThreadCreationRequest extends ChatThreadsEvent {
  const ChatThreadCreationRequest({required this.chatThreadToCreate});
  final ChatThread chatThreadToCreate;
}

class ChatThreadLeftRequest extends ChatThreadsEvent {
  const ChatThreadLeftRequest({required this.chatThreadId});
  final String chatThreadId;

  @override
  List<Object> get props => [chatThreadId];
}

@immutable
class QuestionChatSeenEvent extends ChatThreadsEvent {
  const QuestionChatSeenEvent({required this.questionThreadId});

  final String questionThreadId;
}
