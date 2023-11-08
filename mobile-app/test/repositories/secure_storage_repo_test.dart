import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chatbond/data/repositories/secure_storage_repo.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  const accessToken = '123';
  const refreshToken = '456';

  group('SecureStorageRepo', () {
    late FlutterSecureStorage mockedSecureStorage;
    late SecureStorageRepo repo;

    setUp(() {
      mockedSecureStorage = MockFlutterSecureStorage();
      repo = SecureStorageRepo(mockedSecureStorage);
    });

    test('saveAccessToken', () async {
      when(
        () => mockedSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await repo.saveAccessToken(accessToken);

      verify(
        () =>
            mockedSecureStorage.write(key: accessTokenKey, value: accessToken),
      ).called(1);
    });

    test('saveRefreshToken', () async {
      when(
        () => mockedSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await repo.saveRefreshToken(refreshToken);

      verify(
        () => mockedSecureStorage.write(
          key: refreshTokenKey,
          value: refreshToken,
        ),
      ).called(1);
    });

    test('getAccessToken', () async {
      when(() => mockedSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => accessToken);

      final result = await repo.getAccessToken();

      expect(result, accessToken);
      verify(() => mockedSecureStorage.read(key: accessTokenKey)).called(1);
    });

    test('getRefreshToken', () async {
      when(() => mockedSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => refreshToken);

      final result = await repo.getRefreshToken();

      expect(result, refreshToken);
      verify(() => mockedSecureStorage.read(key: refreshTokenKey)).called(1);
    });

    test('persistAccessToken', () async {
      when(
        () => mockedSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockedSecureStorage.deleteAll()).thenAnswer((_) async {});

      await repo.persistAccessToken(accessToken);
      verify(
        () => mockedSecureStorage.write(
          key: accessTokenKey,
          value: accessToken,
        ),
      ).called(1);

      await repo.persistAccessToken(null);
      verify(() => mockedSecureStorage.deleteAll()).called(1);
    });

    test('persistRefreshToken', () async {
      when(
        () => mockedSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockedSecureStorage.deleteAll()).thenAnswer((_) async {});

      await repo.persistRefreshToken(refreshToken);
      verify(
        () => mockedSecureStorage.write(
          key: refreshTokenKey,
          value: refreshToken,
        ),
      ).called(1);

      await repo.persistRefreshToken(null);
      verify(() => mockedSecureStorage.deleteAll()).called(1);
    });

    test('emptySecureStorageNow', () async {
      when(() => mockedSecureStorage.deleteAll()).thenAnswer((_) async {});

      await repo.emptySecureStorageNow();

      verify(() => mockedSecureStorage.deleteAll()).called(1);
    });
  });
}
