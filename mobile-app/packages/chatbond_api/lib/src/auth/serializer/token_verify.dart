class TokenVerify {
  TokenVerify({required this.token});
  factory TokenVerify.fromJson(Map<String, dynamic> json) {
    return TokenVerify(
      token: json['token'] as String,
    );
  }
  final String token;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
