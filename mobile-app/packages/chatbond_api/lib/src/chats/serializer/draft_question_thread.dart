import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';

class UpsertResult {
  UpsertResult({required this.draft, required this.wasCreated});

  final DraftQuestionThread draft;
  final bool wasCreated;
}

class DraftQuestionThread extends Equatable {
  const DraftQuestionThread({
    required this.content,
    required this.question,
    required this.otherInterlocutor, // TODO: only supports 2 people in chat
    this.id,
    this.chatThread,
    this.createdAt,
    this.publishedAt,
    this.questionThread,
  });

  factory DraftQuestionThread.fromJson(Map<String, dynamic> json) {
    return DraftQuestionThread(
      id: json['id'] as String,
      chatThread: json['chat_thread'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      question: json['question'] as String,
      otherInterlocutor:
          Interlocutor.fromJson(json['interlocutor'] as Map<String, dynamic>),
      publishedAt: json['published_at'] as String?,
      questionThread: json['question_thread'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (id != null) {
      json['id'] = id;
    }
    if (chatThread != null) {
      json['chat_thread'] = chatThread;
    }
    json['content'] = content;
    if (createdAt != null) {
      json['created_at'] = createdAt;
    }
    json['question'] = question;
    json['interlocutor'] = otherInterlocutor.toJson();

    return json;
  }

  final String? id;
  final String? chatThread;
  final String content;
  final String? createdAt;
  final String question;
  final Interlocutor otherInterlocutor;
  final String? publishedAt;
  final String? questionThread;

  @override
  List<Object> get props => [
        id ?? 1,
        chatThread ?? 1,
        content,
        createdAt ?? 1,
        question,
        otherInterlocutor,
        publishedAt ?? 1,
        questionThread ?? 1
      ];

  DraftQuestionThread copyWith({
    String? id,
    String? chatThread,
    String? content,
    String? createdAt,
    String? question,
    Interlocutor? otherInterlocutor,
    String? publishedAt,
    String? questionThread,
  }) {
    return DraftQuestionThread(
      id: id ?? this.id,
      chatThread: chatThread ?? this.chatThread,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      question: question ?? this.question,
      otherInterlocutor: otherInterlocutor ?? this.otherInterlocutor,
      publishedAt: publishedAt ?? this.publishedAt,
      questionThread: questionThread ?? this.questionThread,
    );
  }
}
