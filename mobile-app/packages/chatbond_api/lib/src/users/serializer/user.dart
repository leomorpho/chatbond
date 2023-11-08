import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
    );
  }
  final String id;
  final String name;
  final String email;
  final String? dateOfBirth;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? dateOfBirth,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'date_of_birth': dateOfBirth,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, '
        'dateOfBirth: $dateOfBirth}';
  }

  @override
  List<Object> get props => [id, name, email, dateOfBirth ?? ''];
}
