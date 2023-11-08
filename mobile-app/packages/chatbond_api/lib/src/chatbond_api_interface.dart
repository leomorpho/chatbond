abstract class ApiClientInterface {
  Future<void> updateAccessToken(String newToken);
  String? getAccessToken();

  Future<void> updateRefreshToken(String? newRefreshToken);
  String? getRefreshToken();
}
