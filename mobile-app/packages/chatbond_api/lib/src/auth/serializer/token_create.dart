class TokenCreate {
  TokenCreate({
    required this.access,
    required this.refresh,
  });

  factory TokenCreate.fromJson(Map<String, dynamic> json) {
    return TokenCreate(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }
  final String access;
  final String refresh;

  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
    };
  }
}
