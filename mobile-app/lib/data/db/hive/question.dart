import 'package:chatbond/data/db/hive/draft_question_thread.dart';
import 'package:chatbond/data/db/hive/interlocutor.dart';
import 'package:hive/hive.dart';

part 'question.g.dart'; // Name of the generated file

@HiveType(typeId: 4)
class HiveQuestion extends HiveObject {
  HiveQuestion({
    required this.id,
    required this.cumulativeVotingScore,
    required this.timesVoted,
    required this.timesAnswered,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
    required this.answeredByFriends,
    this.isActive,
    this.author,
    this.isPrivate,
    this.status,
    this.isFavorited = false,
    required this.currInterlocutorVotingStatus,
    this.unpublishedDrafts,
    this.publishedDrafts,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  int cumulativeVotingScore;

  @HiveField(2)
  final int timesVoted;

  @HiveField(3)
  final int timesAnswered;

  @HiveField(4)
  final String createdAt;

  @HiveField(5)
  final String updatedAt;

  @HiveField(6)
  final String content;

  @HiveField(7)
  final bool? isActive;

  @HiveField(8)
  final HiveInterlocutor? author;
  @HiveField(9)
  final bool? isPrivate;

  @HiveField(10)
  final String? status;

  @HiveField(11)
  bool? isFavorited;

  @HiveField(12)
  String currInterlocutorVotingStatus;

  @HiveField(13)
  final List<String> answeredByFriends;

  @HiveField(14)
  final List<HiveDraftQuestionThread>? unpublishedDrafts;

  @HiveField(15)
  final List<HiveDraftQuestionThread>? publishedDrafts;
}
