// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_thread.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveQuestionThreadAdapter extends TypeAdapter<HiveQuestionThread> {
  @override
  final int typeId = 3;

  @override
  HiveQuestionThread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveQuestionThread(
      id: fields[0] as String,
      chatThread: (fields[1] as HiveList?)?.castHiveList(),
      chatThreadId: fields[2] as String,
      question: fields[3] as HiveQuestion,
      updatedAt: fields[4] as String,
      createdAt: fields[5] as String,
      allInterlocutorsAnswered: fields[6] as bool,
      numNewUnseenMessages: fields[7] as int?,
    )..chats = (fields[8] as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, HiveQuestionThread obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatThread)
      ..writeByte(2)
      ..write(obj.chatThreadId)
      ..writeByte(3)
      ..write(obj.question)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.allInterlocutorsAnswered)
      ..writeByte(7)
      ..write(obj.numNewUnseenMessages)
      ..writeByte(8)
      ..write(obj.chats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveQuestionThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
