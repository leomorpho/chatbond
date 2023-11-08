import 'package:chatbond_api/src/chats/serializer/draft_question_thread.dart';
import 'package:equatable/equatable.dart';

class PaginatedDraftQuestionThreadList extends Equatable {
  const PaginatedDraftQuestionThreadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedDraftQuestionThreadList.fromJson(Map<String, dynamic> json) {
    return PaginatedDraftQuestionThreadList(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) =>
              DraftQuestionThread.fromJson(item as Map<String, dynamic>),)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((item) => item.toJson()).toList(),
    };
  }

  final int count;
  final String? next;
  final String? previous;
  final List<DraftQuestionThread> results;

  @override
  List<Object> get props => [count, next ?? '', previous ?? '', results];
}
