import 'package:chatbond_api/src/chats/serializer/interlocutor.dart';
import 'package:chatbond_api/src/chats/serializer/question_thread.dart';
import 'package:equatable/equatable.dart';

class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.interlocutors,
    required this.owner,
    required this.updatedAt,
    required this.createdAt,
    this.numNewUnseenMessages,
  });
  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      interlocutors: List<Interlocutor>.from(
        (json['interlocutors'] as List<dynamic>)
            .map((x) => Interlocutor.fromJson(x as Map<String, dynamic>)),
      ),
      owner: Interlocutor.fromJson(json['owner'] as Map<String, dynamic>),
      updatedAt: json['updated_at'] as String,
      createdAt: json['created_at'] as String,
      numNewUnseenMessages: json['num_new_unseen_messages'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interlocutors': interlocutors.map((e) => e.toJson()).toList(),
      'owner': owner,
      'updatedAt': updatedAt,
      'created_at': createdAt,
      'num_new_unseen_messages': numNewUnseenMessages,
    };
  }

  final String id;
  final List<Interlocutor> interlocutors;
  final Interlocutor owner;
  final String updatedAt;
  final String createdAt;
  final int? numNewUnseenMessages;

  @override
  List<Object> get props =>
      [id, interlocutors, updatedAt, createdAt, numNewUnseenMessages ?? 0];

  ChatThread copyWith({
    String? id,
    List<Interlocutor>? interlocutors,
    Interlocutor? owner,
    List<QuestionThread>? questionThreads,
    String? updatedAt,
    String? createdAt,
    int? numNewUnseenMessages,
  }) {
    return ChatThread(
      id: id ?? this.id,
      interlocutors: interlocutors ?? this.interlocutors,
      owner: owner ?? this.owner,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      numNewUnseenMessages: numNewUnseenMessages ?? this.numNewUnseenMessages,
    );
  }
}
