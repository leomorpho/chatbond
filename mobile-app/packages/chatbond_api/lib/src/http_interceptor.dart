import 'dart:io';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:loggy/loggy.dart';

class ApiHttpInterceptor implements InterceptorContract {
  ApiHttpInterceptor({required this.auth});

  final Auth auth;

  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    // TODO: it doesn't seem like this method is ever invoked when it should
    // be, am I missing some plumping?
    var token = auth.accessTokenGetter();

    if (token == null) {
      token = await auth.getAccessTokenFromCookie(); // Assumed to be async
      auth.accessTokenUpdater(token);
    }

    var refreshToken = auth.refreshTokenGetter();
    if (refreshToken == null) {
      refreshToken =
          await auth.getRefreshTokenFromCookie(); // Assumed to be async
      auth.refreshTokenUpdater(refreshToken);
    }
    if (token != null) {
      data.headers['Authorization'] = 'Bearer $token';
    }
    logDebug('interceptRequest - $data');
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    if (data.statusCode >= 400) {
      logError(data.toString());
    }
    if (data.statusCode == 401) {
      logInfo('interceptResponse - Attempting to refresh token.');
      final refreshToken = auth.refreshTokenGetter();
      if (refreshToken != null) {
        try {
          final refreshedToken =
              await auth.refreshToken(refreshToken: refreshToken);
          logInfo(refreshedToken.toString());
          // TODO: I don't think we need to update it again here since we're
          // already doing that in `auth.refreshToken`.
          auth.refreshTokenUpdater(
            refreshedToken.refresh,
          ); // Update the refresh token
          logInfo(
            'interceptResponse - Successfully refreshed token, retrying request.',
          );
          return await _retryRequest(data);
        } catch (e) {
          // Refresh token failed; logout and return original response
          logError(
            'interceptResponse - Failed to refresh token, logging user out.',
          );
          auth.logout();
          return data;
        }
      }
    }
    return data;
  }

  Future<ResponseData> _retryRequest(ResponseData data) async {
    final request = data.request;
    final token = auth.accessTokenGetter();
    if (token != null) {
      request!.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    // Create a new Request object with the required properties from the original RequestData object
    final newRequest = Request(
      request!.method.name,
      request.url.toUri(),
    ) // Use method.value and url.uri
      ..headers.addAll(request.headers)
      ..body = request.body as String; // Cast body to String

    final response = await Client().send(newRequest);
    final httpResponse = await http.Response.fromStream(response);
    data = ResponseData.fromHttpResponse(httpResponse);
    if (data.statusCode >= 400) {
      logError('_retryRequest failed: $data');
    }
    return data;
  }
}
