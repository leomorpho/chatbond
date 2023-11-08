import 'package:chatbond_api/src/questions/serializer/question.dart';

class PaginatedQuestions {
  PaginatedQuestions({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedQuestions.fromJson(Map<String, dynamic> json) {
    return PaginatedQuestions(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((i) => Question.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
  final int count;
  final String? next;
  final String? previous;
  final List<Question> results;
}
