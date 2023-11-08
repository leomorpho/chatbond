import 'package:chatbond/data/db/hive/question.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'question_thread.g.dart'; // Name of the generated file

@HiveType(typeId: 3)
class HiveQuestionThread extends HiveObject with EquatableMixin {
  HiveQuestionThread({
    required this.id,
    this.chatThread,
    required this.chatThreadId,
    required this.question,
    required this.updatedAt,
    required this.createdAt,
    required this.allInterlocutorsAnswered,
    this.numNewUnseenMessages = 0,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  HiveList? chatThread; // ChatThread

  @HiveField(2)
  final String chatThreadId; // ChatThread

  @HiveField(3)
  final HiveQuestion question;

  @HiveField(4)
  final String updatedAt;

  @HiveField(5)
  final String createdAt;

  @HiveField(6)
  final bool allInterlocutorsAnswered;

  @HiveField(7)
  int? numNewUnseenMessages;

  @HiveField(8)
  HiveList? chats; // List<QuestionChat>

  HiveQuestionThread copyWith({
    String? id,
    HiveList? chatThread,
    String? chatThreadId,
    HiveQuestion? question,
    String? updatedAt,
    String? createdAt,
    bool? allInterlocutorsAnswered,
    int? numNewUnseenMessages,
  }) {
    return HiveQuestionThread(
      id: id ?? this.id,
      chatThread: chatThread ?? this.chatThread,
      chatThreadId: chatThreadId ?? this.chatThreadId,
      question: question ?? this.question,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      allInterlocutorsAnswered:
          allInterlocutorsAnswered ?? this.allInterlocutorsAnswered,
      numNewUnseenMessages: numNewUnseenMessages ?? this.numNewUnseenMessages,
    );
  }

  @override
  List<Object> get props => [
        id,
        chatThread ?? 1,
        chatThreadId,
        question,
        updatedAt,
        createdAt,
        allInterlocutorsAnswered,
        numNewUnseenMessages ?? 0,
      ];
}
