import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'question_chat_interaction_event.g.dart';

@HiveType(typeId: 4) // Ensure a unique typeId
class HiveQuestionChatInteractionEvent extends HiveObject with EquatableMixin {
  HiveQuestionChatInteractionEvent({
    required this.interlocutor,
    this.receivedAt,
    this.seenAt,
  });

  @HiveField(0)
  final String interlocutor;

  @HiveField(1)
  final DateTime? receivedAt;

  @HiveField(2)
  final DateTime? seenAt;

  HiveQuestionChatInteractionEvent copyWith({
    String? interlocutor,
    DateTime? receivedAt,
    DateTime? seenAt,
  }) {
    return HiveQuestionChatInteractionEvent(
      interlocutor: interlocutor ?? this.interlocutor,
      receivedAt: receivedAt ?? this.receivedAt,
      seenAt: seenAt ?? this.seenAt,
    );
  }

  @override
  List<Object> get props => [interlocutor, receivedAt ?? 1, seenAt ?? 1];
}
