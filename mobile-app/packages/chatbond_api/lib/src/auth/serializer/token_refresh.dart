class TokenRefresh {
  TokenRefresh({
    required this.access,
    required this.refresh,
  });

  factory TokenRefresh.fromJson(Map<String, dynamic> json) {
    return TokenRefresh(
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
