import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/data/repositories/secure_storage_repo.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockSecureStorageRepo extends Mock implements SecureStorageRepo {}

class MockAuth extends Mock implements Auth {}

class MockApiClient extends Mock implements ApiClient {
  MockApiClient() {
    _auth = MockAuth();
  }
  late MockAuth? _auth;

  @override
  Auth get auth => _auth!;

  // You can also add mocked implementations for `updateAccessToken` and `getAccessToken` if needed.
  @override
  Future<void> updateAccessToken(String? newToken) async {
    // Implement the mock logic for this method if required
  }

  @override
  String? getAccessToken() {
    // Implement the mock logic for this method if required
    return null;
  }
}

void main() {
  const name = 'user1';
  const email = 'user1@gmail.com';
  const password = 'password';
  const dateOfBirth = '1994-04-23';

  group('AuthenticationRepository', () {
    late MockSecureStorageRepo secureStorageRepo;
    late MockApiClient mockApiClient;
    late AuthenticationRepository authenticationRepository;

    setUpAll(() {
      secureStorageRepo = MockSecureStorageRepo();
      mockApiClient = MockApiClient();
    });

    setUp(() {
      secureStorageRepo = MockSecureStorageRepo();
      mockApiClient = MockApiClient();
      authenticationRepository = AuthenticationRepository(
        secureStorageRepo: secureStorageRepo,
        apiClient: mockApiClient,
      );
    });

    test('emits [unknown, authenticated] if user is already logged in',
        () async {
      when(() => secureStorageRepo.getAccessToken())
          .thenAnswer((_) async => '123');
      when(() => mockApiClient.auth.verifyToken(token: '123'))
          .thenAnswer((_) async => true);

      expect(
        authenticationRepository.status,
        emitsInOrder([
          AuthenticationStatus.unknown,
          AuthenticationStatus.authenticated,
        ]),
      );
    });

    test('emits [unknown, unauthenticated] if user is not logged in', () async {
      when(() => secureStorageRepo.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => secureStorageRepo.getRefreshToken())
          .thenAnswer((_) async => null);

      expect(
        authenticationRepository.status,
        emitsInOrder([
          AuthenticationStatus.unknown,
          AuthenticationStatus.unauthenticated,
        ]),
      );
    });

    test('register calls ApiClient.auth.signup and logIn', () async {
      when(
        () => mockApiClient.auth.signup(
          name: name,
          email: email,
          password: password,
          dateOfBirth: dateOfBirth,
        ),
      ).thenAnswer((_) async => User(id: '1', name: 'name', email: 'email'));

      when(
        () => mockApiClient.auth.login(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => true);

      when(() => secureStorageRepo.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => secureStorageRepo.getRefreshToken())
          .thenAnswer((_) async => null);

      await authenticationRepository.register(
        name: name,
        email: email,
        password: password,
        dateOfBirth: dateOfBirth,
      );

      verify(
        () => mockApiClient.auth.signup(
          name: name,
          email: email,
          password: password,
          dateOfBirth: dateOfBirth,
        ),
      ).called(1);
      verify(
        () => mockApiClient.auth.login(
          email: email,
          password: password,
        ),
      ).called(1);

      expect(
        authenticationRepository.status,
        emitsInOrder([
          AuthenticationStatus.unknown,
          AuthenticationStatus.unauthenticated,
          AuthenticationStatus.authenticated,
        ]),
      );
    });

    test('logIn calls ApiClient.auth.login and emits authenticated', () async {
      when(
        () => mockApiClient.auth.login(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => true);

      when(() => secureStorageRepo.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => secureStorageRepo.getRefreshToken())
          .thenAnswer((_) async => null);

      await authenticationRepository.logIn(
        email: email,
        password: password,
      );

      verify(
        () => mockApiClient.auth.login(
          email: email,
          password: password,
        ),
      ).called(1);

      expect(
        authenticationRepository.status,
        emitsInOrder([
          AuthenticationStatus.unknown,
          AuthenticationStatus.unauthenticated,
          AuthenticationStatus.authenticated,
        ]),
      );
    });

    test('logOut calls ApiClient.auth.logout and emits unauthenticated',
        () async {
      when(() => mockApiClient.auth.logout()).thenReturn(null);
      when(() => secureStorageRepo.emptySecureStorageNow())
          .thenAnswer((_) async => true);
      when(() => secureStorageRepo.getAccessToken())
          .thenAnswer((_) async => '123');
      when(() => mockApiClient.auth.verifyToken(token: '123'))
          .thenAnswer((_) async => true);

      await authenticationRepository.logOut();

      verify(() => mockApiClient.auth.logout()).called(1);
      verify(() => secureStorageRepo.emptySecureStorageNow()).called(1);
      expect(
        authenticationRepository.status,
        emitsInOrder([
          AuthenticationStatus.unknown,
          AuthenticationStatus.authenticated,
          AuthenticationStatus.unauthenticated,
        ]),
      );
    });
  });
}
