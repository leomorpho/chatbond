import 'package:chatbond_api/src/questions/serializer/question.dart';
import 'package:equatable/equatable.dart';

class QuestionThread extends Equatable {
  const QuestionThread({
    required this.id,
    required this.chatThread,
    required this.question,
    required this.updatedAt,
    required this.createdAt,
    required this.allInterlocutorsAnswered,
    this.numNewUnseenMessages,
  });

  factory QuestionThread.fromJson(Map<String, dynamic> json) {
    return QuestionThread(
      id: json['id'] as String,
      chatThread: json['chat_thread'] as String,
      question: Question.fromJson(json['question'] as Map<String, dynamic>),
      updatedAt: json['updated_at'] as String,
      createdAt: json['created_at'] as String,
      allInterlocutorsAnswered: json['all_interlocutors_answered'] as bool,
      numNewUnseenMessages: json['num_new_unseen_messages'] as int?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_thread': chatThread,
      'question': question.toJson(),
      'updatedAt': updatedAt,
      'created_at': createdAt,
      'all_interlocutors_answered': allInterlocutorsAnswered,
      'num_new_unseen_messages': numNewUnseenMessages,
    };
  }

  final String id;
  final String chatThread;
  final Question question;
  final String updatedAt;
  final String createdAt;
  final bool allInterlocutorsAnswered;
  final int? numNewUnseenMessages;

  @override
  List<Object> get props => [
        id,
        chatThread,
        question,
        updatedAt,
        allInterlocutorsAnswered,
        numNewUnseenMessages ?? 0,
      ];

  QuestionThread copyWith({
    String? id,
    String? chatThread,
    Question? question,
    String? updatedAt,
    String? createdAt,
    bool? allInterlocutorsAnswered,
    int? numNewUnseenMessages,
  }) {
    return QuestionThread(
      id: id ?? this.id,
      chatThread: chatThread ?? this.chatThread,
      question: question ?? this.question,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      allInterlocutorsAnswered:
          allInterlocutorsAnswered ?? this.allInterlocutorsAnswered,
      numNewUnseenMessages: numNewUnseenMessages ?? this.numNewUnseenMessages,
    );
  }

  @override
  String toString() {
    return 'QuestionThread { id: $id, chatThread: $chatThread, question: $question, updatedAt: $updatedAt, createdAt: $createdAt, numNewUnseenMessages: ${numNewUnseenMessages ?? 'null'} }';
  }
}
