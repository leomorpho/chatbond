import 'package:chatbond_api/src/chats/serializer/question_thread.dart';

class PaginatedQuestionThreadList {
  PaginatedQuestionThreadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedQuestionThreadList.fromJson(Map<String, dynamic> json) {
    return PaginatedQuestionThreadList(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => QuestionThread.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int count;
  final String? next;
  final String? previous;
  final List<QuestionThread> results;

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}
