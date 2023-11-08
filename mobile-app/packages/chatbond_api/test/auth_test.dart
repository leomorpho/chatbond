import 'package:chatbond_api/chatbond_api.dart';
import 'package:test/test.dart';

class Persister {
  Persister() : data = {};

  final Map<String, String> data;

  Future<void> persistAccessToken(String? accessToken) async {
    if (accessToken != null) {
      data['accessToken'] = accessToken;
    } else {
      data.remove('accessToken');
    }
  }

  Future<void> persistRefreshToken(String? refreshToken) async {
    if (refreshToken != null) {
      data['refreshToken'] = refreshToken;
    } else {
      data.remove('refreshToken');
    }
  }
}

void main() {
  group('ApiClient updates tokens', () {
    late ApiClient apiClient;
    late Persister persister;

    setUp(() {
      persister = Persister();

      apiClient = ApiClient(
          baseUrl: 'https://api.example.com',
          realtimeUrl: 'blah.com',
          persistAccessToken: persister.persistAccessToken,
          persistRefreshToken: persister.persistRefreshToken,
          getAccessTokenFromCookie: () async {
            return null;
          },
          getRefreshTokenFromCookie: () async {
            return null;
          });
    });

    test('update tokens', () async {
      const accessToken = 'access_token';
      const refreshToken = 'refresh_token';

      expect(apiClient.getAccessToken(), null);
      expect(apiClient.getRefreshToken(), null);
      expect(persister.data['accessToken'], null);
      expect(persister.data['refreshToken'], null);

      await apiClient.updateAccessToken(accessToken);
      await apiClient.updateRefreshToken(refreshToken);

      expect(apiClient.getAccessToken(), accessToken);
      expect(apiClient.getRefreshToken(), refreshToken);
      expect(persister.data['accessToken'], accessToken);
      expect(persister.data['refreshToken'], refreshToken);
    });
  });
}
