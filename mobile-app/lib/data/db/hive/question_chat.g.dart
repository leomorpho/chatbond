// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveQuestionChatAdapter extends TypeAdapter<HiveQuestionChat> {
  @override
  final int typeId = 2;

  @override
  HiveQuestionChat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveQuestionChat(
      id: fields[0] as String,
      authorId: fields[1] as String,
      authorName: fields[2] as String,
      questionThread: (fields[3] as HiveList?)?.castHiveList(),
      questionThreadId: fields[4] as String,
      content: fields[5] as String,
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      interactionEvents:
          (fields[9] as List).cast<HiveQuestionChatInteractionEvent>(),
      seenByCurrInterlocutor: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveQuestionChat obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.authorName)
      ..writeByte(3)
      ..write(obj.questionThread)
      ..writeByte(4)
      ..write(obj.questionThreadId)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.interactionEvents)
      ..writeByte(10)
      ..write(obj.seenByCurrInterlocutor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveQuestionChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
