enum RealtimePayloadType {
  questionThread,
  chatThread,
  questionChat,
  invitation
}

extension ParseRealtimePayloadTypeEnum on RealtimePayloadType {
  String get value {
    switch (this) {
      case RealtimePayloadType.chatThread:
        return 'chat_thread';
      case RealtimePayloadType.questionThread:
        return 'question_thread';
      case RealtimePayloadType.questionChat:
        return 'question_chat';
      case RealtimePayloadType.invitation:
        return 'invitation';
    }
  }

  static RealtimePayloadType fromString(String string) {
    switch (string) {
      case 'chat_thread':
        return RealtimePayloadType.chatThread;
      case 'question_thread':
        return RealtimePayloadType.questionThread;
      case 'question_chat':
        return RealtimePayloadType.questionChat;
      case 'invitation':
        return RealtimePayloadType.invitation;
      default:
        throw ArgumentError('Invalid string for RealtimePayloadType: $string');
    }
  }
}

enum RealtimeUpdateAction { upsert, delete }

extension ParseRealtimeUpdateActionsEnum on RealtimeUpdateAction {
  String get value {
    switch (this) {
      case RealtimeUpdateAction.upsert:
        return 'upsert';
      case RealtimeUpdateAction.delete:
        return 'delete';
    }
  }

  static RealtimeUpdateAction fromString(String string) {
    switch (string) {
      case 'upsert':
        return RealtimeUpdateAction.upsert;
      case 'delete':
        return RealtimeUpdateAction.delete;

      default:
        throw ArgumentError('Invalid string for RealtimeUpdateAction: $string');
    }
  }
}

class RealtimeData {
  RealtimeData({required this.type, required this.content});

  factory RealtimeData.fromJson(Map<String, dynamic> json) {
    return RealtimeData(
        type: ParseRealtimePayloadTypeEnum.fromString(json['type'] as String),
        content: json['content'] as Map<String, dynamic>);
  }

  RealtimePayloadType type;
  Map<String, dynamic> content;

  @override
  String toString() {
    return 'RealtimeData(type: $type, content: $content)';
  }
}

class RealtimeUpdateEvent {
  RealtimeUpdateEvent({required this.data, required this.action});

  factory RealtimeUpdateEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeUpdateEvent(
      data: RealtimeData.fromJson(json['data'] as Map<String, dynamic>),
      action: ParseRealtimeUpdateActionsEnum.fromString(
        json['action'] as String,
      ),
    );
  }

  RealtimeData data;
  RealtimeUpdateAction action;

  @override
  String toString() {
    return 'RealtimeUpdateEvent(data: $data, action: $action)';
  }
}
