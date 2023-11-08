import 'package:chatbond/data/db/hive/question_chat_interaction_event.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'question_chat.g.dart'; // Name of the generated file

@HiveType(typeId: 2)
class HiveQuestionChat extends HiveObject with EquatableMixin {
  HiveQuestionChat({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.questionThread,
    required this.questionThreadId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.interactionEvents,
    required this.seenByCurrInterlocutor,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String authorId;

  @HiveField(2)
  final String authorName;

  @HiveField(3)
  late HiveList? questionThread; // QuestionThread

  @HiveField(4)
  late final String questionThreadId;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final List<HiveQuestionChatInteractionEvent> interactionEvents;

  @HiveField(10)
  final bool seenByCurrInterlocutor;

  HiveQuestionChat copyWith({
    String? id,
    String? authorId,
    String? authorName,
    HiveList? questionThread,
    String? questionThreadId,
    String? content,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<HiveQuestionChatInteractionEvent>? interactionEvents,
    bool? seenByCurrInterlocutor,
  }) {
    return HiveQuestionChat(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      questionThread: questionThread ?? this.questionThread,
      questionThreadId: questionThreadId ?? this.questionThreadId,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interactionEvents: interactionEvents ?? this.interactionEvents,
      seenByCurrInterlocutor:
          seenByCurrInterlocutor ?? this.seenByCurrInterlocutor,
    );
  }

  @override
  List<Object> get props => [
        id,
        authorId,
        authorName,
        questionThread ?? 1,
        questionThreadId,
        content,
        status,
        createdAt,
        updatedAt,
        interactionEvents,
        seenByCurrInterlocutor,
      ];
}
