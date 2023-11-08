part of 'chat_threads_bloc.dart';

enum ChatThreadsStatus { loading, loaded, failure }

class ChatThreadsState extends Equatable {
  const ChatThreadsState({
    this.status = ChatThreadsStatus.loading,
    this.chatThreads = const [],
  });

  const ChatThreadsState._({
    this.status = ChatThreadsStatus.loading,
    this.chatThreads = const [],
  });

  const ChatThreadsState.loading() : this._();
  const ChatThreadsState.loaded(List<ChatThread> chatThreads)
      : this._(
          status: ChatThreadsStatus.loaded,
          chatThreads: chatThreads,
        );

  const ChatThreadsState.failure() : this._(status: ChatThreadsStatus.failure);

  final ChatThreadsStatus status;
  final List<ChatThread> chatThreads;

  ChatThreadsState copyWith({
    ChatThreadsStatus? status,
    List<ChatThread>? chatThreads,
  }) {
    return ChatThreadsState._(
      status: status ?? this.status,
      chatThreads: chatThreads ?? this.chatThreads,
    );
  }

  @override
  List<Object> get props => [status, chatThreads];
}
