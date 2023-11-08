import 'package:chatbond_api/src/chats/serializer/question_chat_interaction_event.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

class QuestionChat extends Equatable {
  const QuestionChat({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.questionThread,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.interactionEvents,
  });

  factory QuestionChat.fromJson(Map<String, dynamic> json) {
    return QuestionChat(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      questionThread: json['question_thread'] as String,
      content: json['content'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      interactionEvents: List<QuestionChatInteractionEvent>.from(
        (json['interaction_events'] as List<dynamic>).map(
          (x) => QuestionChatInteractionEvent.fromJson(
            x as Map<String, dynamic>,
          ),
        ),
      ),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'question_thread': questionThread,
      'content': content,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'interaction_events': interactionEvents.map((e) => e.toJson()).toList(),
    };
  }

  final String id;
  final String authorId;
  final String authorName;
  final String questionThread;
  final String content;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuestionChatInteractionEvent> interactionEvents;

  @override
  List<Object> get props => [
        id,
        authorId,
        authorName,
        content,
        status,
        createdAt,
        updatedAt,
        interactionEvents
      ];

  QuestionChat copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? questionThread,
    String? content,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<QuestionChatInteractionEvent>? interactionEvents,
  }) {
    return QuestionChat(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      questionThread: questionThread ?? this.questionThread,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interactionEvents: interactionEvents ?? this.interactionEvents,
    );
  }

  bool hasInterlocutorSeenChat(String interlocutorId) {
    // Try to find an interactionEvent where the interlocutor is the one we're looking for and seenAt is not null
    final interactionEvent = interactionEvents.firstWhereOrNull(
      (event) => event.interlocutor == interlocutorId && event.seenAt != null,
    );

    // If interactionEvent is not null, it means we found an event where the interlocutor has seen the chat
    return interactionEvent != null;
  }
}
