import 'package:chatbond/data/db/hive/interlocutor.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'draft_question_thread.g.dart'; // Name of the generated file

@HiveType(typeId: 6) // Define a unique typeId for this class
class HiveDraftQuestionThread extends Equatable {
  const HiveDraftQuestionThread({
    this.id,
    this.chatThread,
    required this.content,
    required this.question,
    required this.otherInterlocutor,
    this.createdAt,
    this.publishedAt,
    this.questionThread,
  });

  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String? chatThread;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? createdAt;

  @HiveField(4)
  final String question;

  @HiveField(5)
  final HiveInterlocutor
      otherInterlocutor; // Make sure Interlocutor is Hive compatible

  @HiveField(6)
  final String? publishedAt;

  @HiveField(7)
  final String? questionThread;

  @override
  List<Object?> get props => [
        id,
        chatThread,
        content,
        createdAt,
        question,
        otherInterlocutor,
        publishedAt,
        questionThread,
      ];
}
