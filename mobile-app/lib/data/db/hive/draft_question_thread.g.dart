// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_question_thread.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveDraftQuestionThreadAdapter
    extends TypeAdapter<HiveDraftQuestionThread> {
  @override
  final int typeId = 6;

  @override
  HiveDraftQuestionThread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveDraftQuestionThread(
      id: fields[0] as String?,
      chatThread: fields[1] as String?,
      content: fields[2] as String,
      question: fields[4] as String,
      otherInterlocutor: fields[5] as HiveInterlocutor,
      createdAt: fields[3] as String?,
      publishedAt: fields[6] as String?,
      questionThread: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveDraftQuestionThread obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatThread)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.question)
      ..writeByte(5)
      ..write(obj.otherInterlocutor)
      ..writeByte(6)
      ..write(obj.publishedAt)
      ..writeByte(7)
      ..write(obj.questionThread);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveDraftQuestionThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
