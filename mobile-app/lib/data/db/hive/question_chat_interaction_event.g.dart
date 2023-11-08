// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_chat_interaction_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveQuestionChatInteractionEventAdapter
    extends TypeAdapter<HiveQuestionChatInteractionEvent> {
  @override
  final int typeId = 4;

  @override
  HiveQuestionChatInteractionEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveQuestionChatInteractionEvent(
      interlocutor: fields[0] as String,
      receivedAt: fields[1] as DateTime?,
      seenAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveQuestionChatInteractionEvent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.interlocutor)
      ..writeByte(1)
      ..write(obj.receivedAt)
      ..writeByte(2)
      ..write(obj.seenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveQuestionChatInteractionEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
