class Invitation {
  Invitation({
    required this.id,
    required this.inviter,
    required this.inviteeName,
    required this.inviteUrl,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.validityDurationInDays,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      inviter: json['inviter'] as String,
      inviteeName: json['invitee_name'] as String,
      inviteUrl: json['invite_url'] as String,
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      validityDurationInDays: json['validity_duration_in_days'] as int,
    );
  }

  final String id;
  final String inviter;
  final String inviteeName;
  final String inviteUrl;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int validityDurationInDays;
}
