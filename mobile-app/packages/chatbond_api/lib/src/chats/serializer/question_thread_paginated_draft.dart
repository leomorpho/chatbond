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
      results: List<DraftQuestionThread>.from(
        (json['results'] as List<dynamic>).map(
            (x) => DraftQuestionThread.fromJson(x as Map<String, dynamic>),),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  final int count;
  final String? next;
  final String? previous;
  final List<DraftQuestionThread> results;

  @override
  List<Object> get props => [count, results];

  PaginatedDraftQuestionThreadList copyWith({
    int? count,
    String? next,
    String? previous,
    List<DraftQuestionThread>? results,
  }) {
    return PaginatedDraftQuestionThreadList(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}
