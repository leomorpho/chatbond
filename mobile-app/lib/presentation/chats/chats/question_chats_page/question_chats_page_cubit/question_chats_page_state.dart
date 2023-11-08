part of 'question_chats_page_cubit.dart';

abstract class QuestionChatsPageState extends Equatable {
  const QuestionChatsPageState();
  Map<String, List<chat_types.Message>> get messagesByThreadId;

  Map<String, dynamic> toJson();

  @override
  List<Object> get props => [];
}

class QuestionChatsPageInitial extends QuestionChatsPageState {
  @override
  Map<String, List<chat_types.Message>> get messagesByThreadId => {};

  @override
  Map<String, dynamic> toJson() => {};
}

class QuestionChatsPageLoading extends QuestionChatsPageState {
  @override
  Map<String, List<chat_types.Message>> get messagesByThreadId => {};

  @override
  Map<String, dynamic> toJson() => {};
}

class QuestionChatsPageLoaded extends QuestionChatsPageState {
  const QuestionChatsPageLoaded({
    required this.question,
    required this.messagesByThreadId,
    required this.user,
    // required this.counter, // TODO: hack to force rebuild because adding to messagesByThreadId doesn't do it
  });

  final Question question;
  @override
  final Map<String, List<chat_types.Message>> messagesByThreadId;
  final chat_types.User user;
  // final int counter;

  @override
  List<Object> get props => [messagesByThreadId, user, question];

  @override
  Map<String, dynamic> toJson() {
    final messagesByThreadIdJson = messagesByThreadId.map(
      (key, value) => MapEntry(
        key,
        value.map((chat_types.Message message) => message.toJson()).toList(),
      ),
    );

    return {
      'messagesByThreadId': messagesByThreadIdJson,
      'user': user.toJson(),
    };
  }

  QuestionChatsPageLoaded copyWith({
    Question? question,
    Map<String, List<chat_types.Message>>? messagesByThreadId,
    chat_types.User? user,
  }) {
    return QuestionChatsPageLoaded(
      question: question ?? this.question,
      messagesByThreadId: messagesByThreadId ?? this.messagesByThreadId,
      user: user ?? this.user,
    );
  }
}

class QuestionChatsPageError extends QuestionChatsPageState {
  const QuestionChatsPageError({required this.message});
  final String message;
  @override
  Map<String, List<chat_types.Message>> get messagesByThreadId => {};

  @override
  List<Object> get props => [message];

  @override
  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
