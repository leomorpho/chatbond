import 'package:chatbond_api/src/auth/auth.dart';
import 'package:chatbond_api/src/chatbond_api_interface.dart';
import 'package:chatbond_api/src/chats/chats.dart';
import 'package:chatbond_api/src/http_interceptor.dart';
import 'package:chatbond_api/src/invitations/invitations.dart';
import 'package:chatbond_api/src/questions/questions.dart';
import 'package:chatbond_api/src/realtime/realtime.dart';
import 'package:chatbond_api/src/users/users.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';

export 'auth/auth.dart';

typedef TokenUpdater = void Function(String? token);
typedef TokenGetter = String? Function();
typedef PersistAccessToken = Future<void> Function(String? accessToken);
typedef PersistRefreshToken = Future<void> Function(String? refreshToken);
typedef GetAccessTokenFromCookie = Future<String?> Function();
typedef GetRefreshTokenFromCookie = Future<String?> Function();

class ApiClient implements ApiClientInterface {
  factory ApiClient({
    required String baseUrl,
    required String realtimeUrl,
    required PersistAccessToken persistAccessToken,
    required PersistRefreshToken persistRefreshToken,
    required GetAccessTokenFromCookie getAccessTokenFromCookie,
    required GetRefreshTokenFromCookie getRefreshTokenFromCookie,
  }) {
    _singleton.baseUrl = baseUrl;
    _singleton.realtimeUrl = realtimeUrl;
    _singleton.persistAccessToken = persistAccessToken;
    _singleton.persistRefreshToken = persistRefreshToken;
    _singleton.getAccessTokenFromCookie = getAccessTokenFromCookie;
    _singleton.getRefreshTokenFromCookie = getRefreshTokenFromCookie;
    return _singleton;
  }

  ApiClient._internal();
  static final ApiClient _singleton = ApiClient._internal();

  Future<void> init() async {
    // TODO: no Interception of request/responses for auth because
    //  InterceptedClient depends on auth. Can create custom one.
    auth = Auth(
      baseUrl: baseUrl,
      accessTokenUpdater: updateAccessToken,
      refreshTokenUpdater: updateRefreshToken,
      accessTokenGetter: getAccessToken,
      refreshTokenGetter: getRefreshToken,
      getAccessTokenFromCookie: getAccessTokenFromCookie,
      getRefreshTokenFromCookie: getRefreshTokenFromCookie,
    );
    final apiHttpInterceptor = ApiHttpInterceptor(auth: auth);
    final browserClient = BrowserClient()..withCredentials = true;

    // Wrap BrowserClient with InterceptedClient
    _client = InterceptedClient.build(
      client: browserClient, // Use the BrowserClient instance
      interceptors: [apiHttpInterceptor],
    );

    // Wrap _client with TimeoutClient
    _client = TimeoutClient(
      _client,
      const Duration(seconds: 10),
    ); // 10 seconds timeout

    users = Users(
      baseUrl: baseUrl,
      client: _client,
      accessTokenGetter:
          getAccessToken, // TODO: Remove from here as interceptor should take care of it
    );
    chats = Chats(
      baseUrl: baseUrl,
      client: _client,
      accessTokenGetter:
          getAccessToken, // TODO: Remove from here as interceptor should take care of it
    );
    invitations = Invitations(
      baseUrl: baseUrl,
      client: _client,
      accessTokenGetter:
          getAccessToken, // TODO: Remove from here as interceptor should take care of it
    );
    questions = Questions(
      baseUrl: baseUrl,
      client: _client,
      accessTokenGetter:
          getAccessToken, // TODO: Remove from here as interceptor should take care of it
    );
    realtime = Realtime(
      realtimeUrl: realtimeUrl,
      accessTokenGetter: getAccessToken,
      refreshTokenGetter: getRefreshToken,
      refreshTokenFunction: auth.refreshToken,
    );

    // Get tokens from cookies if applicable
    _jwtToken = await auth.getAccessTokenFromCookie();
    _refreshToken = await auth.getRefreshTokenFromCookie();
  }

  late String baseUrl;
  late String realtimeUrl;
  late Auth auth;
  late final Users users;
  late final Chats chats;
  late final Invitations invitations;
  late final Questions questions;
  late final Realtime realtime;

  String? _jwtToken;
  String? _refreshToken;

  late Client _client;
  late PersistAccessToken persistAccessToken;
  late PersistRefreshToken persistRefreshToken;
  late GetAccessTokenFromCookie getAccessTokenFromCookie;
  late GetRefreshTokenFromCookie getRefreshTokenFromCookie;

  @override
  Future<void> updateAccessToken(String? newAccessToken) async {
    _jwtToken = newAccessToken;
    await persistAccessToken(newAccessToken);
  }

  @override
  Future<void> updateRefreshToken(String? newRefreshToken) async {
    _refreshToken = newRefreshToken;
    await persistRefreshToken(newRefreshToken);
  }

  @override
  String? getAccessToken() {
    return _jwtToken;
  }

  @override
  String? getRefreshToken() {
    return _refreshToken;
  }
}

class TimeoutClient extends BaseClient {
  TimeoutClient(this._inner, this._timeout);

  final Client _inner;
  final Duration _timeout;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    return _inner.send(request).timeout(_timeout);
  }
}
