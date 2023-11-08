// import 'package:bloc_test/bloc_test.dart';
// import 'package:chatbond/data/repositories/repos.dart';
// import 'package:chatbond/domain/entities/user.dart';
// import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';

// class _MockAuthenticationRepository extends Mock
//     implements AuthenticationRepository {}

// class _MockUserRepository extends Mock implements UserRepo {}

// void main() {
//   const user = User('id', 'username', 'email', 'avatar');
//   late AuthenticationRepository authenticationRepository;
//   late UserRepo userRepository;

//   setUp(() {
//     authenticationRepository = _MockAuthenticationRepository();
//     when(
//       () => authenticationRepository.status,
//     ).thenAnswer((_) => const Stream.empty());
//     userRepository = _MockUserRepository();
//   });

//   group('AuthenticationBloc', () {
//     test('initial state is AuthenticationState.unknown', () {
//       final authenticationBlock = AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       );
//       expect(authenticationBlock.state, const AuthenticationState.unknown());
//       authenticationBlock.close();
//     });
//   });

//   group('AuthenticationStatusChanged', () {
//     blocTest<AuthenticationBloc, AuthenticationState>(
//       'emits [authenticated] when status is authenticated',
//       setUp: () {
//         when(() => authenticationRepository.status).thenAnswer(
//           (_) => Stream.value(AuthenticationStatus.authenticated),
//         );
//         when(() => userRepository.getCurrentUser())
//             .thenAnswer((_) async => user);
//       },
//       build: () => AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       ),
//       expect: () => const <AuthenticationState>[
//         AuthenticationState.authenticated(user),
//       ],
//     );

//     blocTest<AuthenticationBloc, AuthenticationState>(
//       'emits [unauthenticated] when status is unauthenticated',
//       setUp: () {
//         when(() => authenticationRepository.status).thenAnswer(
//           (_) => Stream.value(AuthenticationStatus.unauthenticated),
//         );
//       },
//       build: () => AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       ),
//       expect: () => const <AuthenticationState>[
//         AuthenticationState.unauthenticated(),
//       ],
//     );

//     blocTest<AuthenticationBloc, AuthenticationState>(
//       'emits [unauthenticated] when status is authenticated but getUser fails',
//       setUp: () {
//         when(
//           () => authenticationRepository.status,
//         ).thenAnswer((_) => Stream.value(AuthenticationStatus.authenticated));
//         when(() => userRepository.getCurrentUser())
//             .thenThrow(Exception('oops'));
//       },
//       build: () => AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       ),
//       expect: () => const <AuthenticationState>[
//         AuthenticationState.unauthenticated(),
//       ],
//     );

//     blocTest<AuthenticationBloc, AuthenticationState>(
//       'emits [unauthenticated] when status is authenticated '
//       'but getUser returns null',
//       setUp: () {
//         when(
//           () => authenticationRepository.status,
//         ).thenAnswer((_) => Stream.value(AuthenticationStatus.authenticated));
//         when(() => userRepository.getCurrentUser())
//             .thenAnswer((_) async => null);
//       },
//       build: () => AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       ),
//       expect: () => const <AuthenticationState>[
//         AuthenticationState.unauthenticated(),
//       ],
//     );

//     blocTest<AuthenticationBloc, AuthenticationState>(
//       'emits [unknown] when status is unknown',
//       setUp: () {
//         when(
//           () => authenticationRepository.status,
//         ).thenAnswer((_) => Stream.value(AuthenticationStatus.unknown));
//       },
//       build: () => AuthenticationBloc(
//         authenticationRepository: authenticationRepository,
//         userRepository: userRepository,
//       ),
//       expect: () => const <AuthenticationState>[
//         AuthenticationState.unknown(),
//       ],
//     );
//   });
// }
