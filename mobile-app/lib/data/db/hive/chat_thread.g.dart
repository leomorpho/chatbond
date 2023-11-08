// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_thread.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveChatThreadAdapter extends TypeAdapter<HiveChatThread> {
  @override
  final int typeId = 0;

  @override
  HiveChatThread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveChatThread(
      id: fields[0] as String,
      interlocutors: (fields[1] as HiveList?)?.castHiveList(),
      interlocutorIds: (fields[2] as List).cast<String>(),
      owner: fields[3] as HiveInterlocutor,
      updatedAt: fields[4] as String,
      createdAt: fields[5] as String,
      numNewUnseenMessages: fields[6] as int?,
    )..questionThreads = (fields[7] as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, HiveChatThread obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.interlocutors)
      ..writeByte(2)
      ..write(obj.interlocutorIds)
      ..writeByte(3)
      ..write(obj.owner)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.numNewUnseenMessages)
      ..writeByte(7)
      ..write(obj.questionThreads);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveChatThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
