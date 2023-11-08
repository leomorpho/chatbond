class CreateInvitation {
  CreateInvitation({
    required this.inviteeName,
  });
  factory CreateInvitation.fromJson(Map<String, dynamic> json) {
    return CreateInvitation(
      inviteeName: json['invitee_name'] as String,
    );
  }

  final String inviteeName;

  Map<String, dynamic> toJson() {
    return {
      'invitee_name': inviteeName,
    };
  }
}
