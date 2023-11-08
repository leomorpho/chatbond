import 'package:chatbond/data/db/hive/interlocutor.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'chat_thread.g.dart'; // Name of the generated file

@HiveType(typeId: 0)
class HiveChatThread extends HiveObject with EquatableMixin {
  // constructor, copyWith, and other methods remain the same
  HiveChatThread({
    required this.id,
    this.interlocutors,
    required this.interlocutorIds,
    required this.owner,
    required this.updatedAt,
    required this.createdAt,
    this.numNewUnseenMessages = 0,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  HiveList? interlocutors; // List<Interlocutor>

  @HiveField(2)
  final List<String> interlocutorIds;

  @HiveField(3)
  final HiveInterlocutor owner;

  @HiveField(4)
  final String updatedAt;

  @HiveField(5)
  final String createdAt;

  @HiveField(6)
  int? numNewUnseenMessages;

  @HiveField(7)
  HiveList? questionThreads; // List<QuestionThread>

  @override
  List<Object> get props =>
      [id, interlocutors ?? 1, updatedAt, createdAt, numNewUnseenMessages ?? 0];
}
