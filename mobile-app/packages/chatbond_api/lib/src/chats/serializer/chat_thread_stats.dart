import 'package:equatable/equatable.dart';

class ChatThreadStats extends Equatable {
  const ChatThreadStats({
    required this.draftsCount,
    required this.waitingOnOthersQuestionCount,
    required this.waitingOnYouQuestionCount,
    this.favoritedQuestionsCount,
  });

  factory ChatThreadStats.fromJson(Map<String, dynamic> json) {
    return ChatThreadStats(
      draftsCount: json['drafts_count'] as int,
      waitingOnOthersQuestionCount:
          json['waiting_on_others_question_count'] as int,
      waitingOnYouQuestionCount: json['waiting_on_you_question_count'] as int,
      favoritedQuestionsCount: json['favorited_questions_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drafts_count': draftsCount,
      'waiting_on_others_question_count': waitingOnOthersQuestionCount,
      'waiting_on_you_question_count': waitingOnYouQuestionCount,
      'favorited_questions_count': favoritedQuestionsCount,
    };
  }

  final int draftsCount;
  final int waitingOnOthersQuestionCount;
  final int waitingOnYouQuestionCount;
  final int? favoritedQuestionsCount;

  @override
  List<Object?> get props => [
        draftsCount,
        waitingOnOthersQuestionCount,
        waitingOnYouQuestionCount,
        favoritedQuestionsCount
      ];

  ChatThreadStats copyWith({
    int? draftsCount,
    int? waitingOnOthersQuestionCount,
    int? waitingOnYouQuestionCount,
    int? favoritedQuestionsCount,
  }) {
    return ChatThreadStats(
      draftsCount: draftsCount ?? this.draftsCount,
      waitingOnOthersQuestionCount:
          waitingOnOthersQuestionCount ?? this.waitingOnOthersQuestionCount,
      waitingOnYouQuestionCount:
          waitingOnYouQuestionCount ?? this.waitingOnYouQuestionCount,
      favoritedQuestionsCount:
          favoritedQuestionsCount ?? this.favoritedQuestionsCount,
    );
  }

  @override
  String toString() {
    return 'ChatThreadStats { draftsCount: $draftsCount, '
        'waitingOnOthersQuestionCount: $waitingOnOthersQuestionCount, '
        'waitingOnYouQuestionCount: $waitingOnYouQuestionCount, '
        'favoritedQuestionsCount: $favoritedQuestionsCount }';
  }
}
