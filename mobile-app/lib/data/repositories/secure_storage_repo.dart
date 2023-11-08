import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loggy/loggy.dart';

const String accessTokenKey = 'accessToken';
const String refreshTokenKey = 'refreshToken';

abstract class StorageRepoInterface {
  Future<void> saveAccessToken(String accessToken);
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();

  Future<void> persistAccessToken(String? newAccessToken);
  Future<void> persistRefreshToken(String? newRefreshToken);

  Future<void> emptySecureStorageNow();
}

class SecureStorageRepo implements StorageRepoInterface {
  SecureStorageRepo(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    String? token;
    try {
      token = await _storage.read(key: accessTokenKey);
    } catch (e) {
      logWarning('failed to get access token');
    }
    return token;
  }

  @override
  Future<String?> getRefreshToken() async {
    String? token;
    try {
      token = await _storage.read(key: refreshTokenKey);
    } catch (e) {
      logWarning('failed to get refresh token');
    }
    return token;
  }

  @override
  Future<void> persistAccessToken(String? newAccessToken) async {
    if (newAccessToken != null) {
      await saveAccessToken(newAccessToken);
    } else {
      await emptySecureStorageNow();
    }
  }

  @override
  Future<void> persistRefreshToken(String? newRefreshToken) async {
    if (newRefreshToken != null) {
      await saveRefreshToken(newRefreshToken);
    } else {
      await emptySecureStorageNow();
    }
  }

  @override
  Future<void> emptySecureStorageNow() async {
    await _storage.deleteAll();
  }
}
