import 'package:equatable/equatable.dart';

class Interlocutor extends Equatable {
  const Interlocutor({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    required this.createdAt,
    this.updatedAt,
  });

  factory Interlocutor.fromJson(Map<String, dynamic> json) {
    return Interlocutor(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'username': username,
      'email': email,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  final String id;
  final String userId;
  final String name;
  final String username;
  final String email;
  final String createdAt;
  final String? updatedAt;

  @override
  List<Object> get props => [id, userId, name, username, email, createdAt];

  Interlocutor copyWith({
    String? id,
    String? userId,
    String? name,
    String? username,
    String? email,
    String? createdAt,
    String? updatedAt,
  }) {
    return Interlocutor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Interlocutor { id: $id, userId: $userId, name: $name, '
        'email: $email, username: $username, createdAt: $createdAt, '
        'updatedAt: $updatedAt }';
  }
}
