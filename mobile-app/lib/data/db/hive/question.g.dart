// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveQuestionAdapter extends TypeAdapter<HiveQuestion> {
  @override
  final int typeId = 4;

  @override
  HiveQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveQuestion(
      id: fields[0] as String,
      cumulativeVotingScore: fields[1] as int,
      timesVoted: fields[2] as int,
      timesAnswered: fields[3] as int,
      createdAt: fields[4] as String,
      updatedAt: fields[5] as String,
      content: fields[6] as String,
      answeredByFriends: (fields[13] as List).cast<String>(),
      isActive: fields[7] as bool?,
      author: fields[8] as HiveInterlocutor?,
      isPrivate: fields[9] as bool?,
      status: fields[10] as String?,
      isFavorited: fields[11] as bool?,
      currInterlocutorVotingStatus: fields[12] as String,
      unpublishedDrafts: (fields[14] as List?)?.cast<HiveDraftQuestionThread>(),
      publishedDrafts: (fields[15] as List?)?.cast<HiveDraftQuestionThread>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveQuestion obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cumulativeVotingScore)
      ..writeByte(2)
      ..write(obj.timesVoted)
      ..writeByte(3)
      ..write(obj.timesAnswered)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.content)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.author)
      ..writeByte(9)
      ..write(obj.isPrivate)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.isFavorited)
      ..writeByte(12)
      ..write(obj.currInterlocutorVotingStatus)
      ..writeByte(13)
      ..write(obj.answeredByFriends)
      ..writeByte(14)
      ..write(obj.unpublishedDrafts)
      ..writeByte(15)
      ..write(obj.publishedDrafts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
