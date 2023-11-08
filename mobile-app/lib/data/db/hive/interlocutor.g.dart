// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interlocutor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveInterlocutorAdapter extends TypeAdapter<HiveInterlocutor> {
  @override
  final int typeId = 1;

  @override
  HiveInterlocutor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveInterlocutor(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      username: fields[3] as String,
      createdAt: fields[4] as String,
      email: fields[6] as String,
      updatedAt: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveInterlocutor obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.email);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveInterlocutorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
