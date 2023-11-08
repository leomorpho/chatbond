import 'package:chatbond_api/src/questions/serializer/question.dart';

class QuestionFeedWithMetadata {
  QuestionFeedWithMetadata({
    required this.feedCreatedAt,
    required this.count,
    this.next,
    this.previous,
    required this.questions,
  });

  factory QuestionFeedWithMetadata.fromJson(Map<String, dynamic> json) {
    return QuestionFeedWithMetadata(
      feedCreatedAt: json['feed_created_at'] as String,
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      questions: (json['questions'] as List)
          .map((i) => Question.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  final String feedCreatedAt;
  final int count;
  final String? next;
  final String? previous;
  final List<Question> questions;
}
