import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'interlocutor.g.dart'; // Name of the generated file

@HiveType(typeId: 1)
class HiveInterlocutor extends HiveObject with EquatableMixin {
  HiveInterlocutor({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.email,
    this.updatedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String username;

  @HiveField(4)
  final String createdAt;

  @HiveField(5)
  final String? updatedAt;

  @HiveField(6)
  final String email;

  // constructor, copyWith, and other methods remain the same

  @override
  List<Object> get props => [id, name, username, createdAt, email];
}
