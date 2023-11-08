class QuestionChatInteractionEvent {
  QuestionChatInteractionEvent({
    required this.interlocutor,
    this.receivedAt,
    this.seenAt,
  });

  factory QuestionChatInteractionEvent.fromJson(Map<String, dynamic> json) {
    return QuestionChatInteractionEvent(
      interlocutor: json['interlocutor'] as String,
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'] as String)
          : null,
      seenAt: json['seen_at'] != null
          ? DateTime.parse(json['seen_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interlocutor': interlocutor,
      'received_at': receivedAt?.toIso8601String(),
      'seen_at': seenAt?.toIso8601String(),
    };
  }

  final String interlocutor;
  final DateTime? receivedAt;
  final DateTime? seenAt;
}
