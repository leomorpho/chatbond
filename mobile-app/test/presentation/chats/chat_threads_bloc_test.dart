// import 'package:bloc_test/bloc_test.dart';
// import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
// import 'package:chatbond/domain/entities/chat_thread.dart';
// import 'package:chatbond/domain/entities/user.dart';
// import 'package:chatbond/presentation/chats/bloc/chat_threads_bloc/chat_threads_bloc.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hydrated_bloc/hydrated_bloc.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';

// import 'test_plugin_register.dart';

// class _MockChatThreadsRepo extends Mock implements ChatThreadsRepo {}

// class MockUser extends Mock implements User {}

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//   registerPathProviderMocks();
//   late _MockChatThreadsRepo chatThreadsRepo;
//   final user = const User('2', 'username2', 'email2', 'avatar2');
//   final newChatThread = ChatThread(users: [user]);
//   final chatThreads = [
//     ChatThread(
//       users: [User('1', 'username', 'email', 'avatar')],
//     )
//   ];

//   setUpAll(() async {
//     // Initialize the HydratedStorage before running the tests
//     final tempDir = await getTemporaryDirectory();
//     final storagePath = path.join(tempDir.path, 'hydrated_bloc_test');
//     HydratedBloc.storage = await HydratedStorage.build(
//       storageDirectory: tempDir,
//     );
//   });
//   setUp(() {
//     chatThreadsRepo = _MockChatThreadsRepo();
//     when(
//       () => chatThreadsRepo.stream,
//     ).thenAnswer((_) => const Stream.empty());
//   });

//   group('ChatThreadsBloc', () {
//     test('initial state is ChatThreadsStatus.loading', () {
//       when(() => chatThreadsRepo.stream).thenAnswer(
//         (_) => const Stream.empty(),
//       );
//       when(() => chatThreadsRepo.getAllChatThreads())
//           .thenAnswer((_) async => []);
//       final chatThreadsBloc = ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo);
//       expect(chatThreadsBloc.state, const ChatThreadsState.loading());
//       chatThreadsBloc.close();
//     });
//   });

//   group('ChatThreadsConsumedDataFromSource', () {
//     blocTest<ChatThreadsBloc, ChatThreadsState>(
//       'emits [loaded] chatThreads when stream receives data',
//       setUp: () {
//         when(() => chatThreadsRepo.getAllChatThreads())
//             .thenAnswer((_) async => []);
//         when(() => chatThreadsRepo.stream).thenAnswer(
//           (_) => Stream.value(chatThreads),
//         );
//       },
//       build: () => ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo),
//       expect: () => <ChatThreadsState>[ChatThreadsState.loaded(chatThreads)],
//     );
//   });

//   group('ChatThreadCreationRequest', () {
//     blocTest<ChatThreadsBloc, ChatThreadsState>(
//       'emits [loaded] chatThreads when creating a new chat thread',
//       setUp: () {
//         when(() => chatThreadsRepo.getAllChatThreads())
//             .thenAnswer((_) async => []);
//         when(() => chatThreadsRepo.stream).thenAnswer(
//           (_) => Stream.value(chatThreads),
//         );
//         when(() => chatThreadsRepo.createChatThread(newChatThread)).thenAnswer(
//           (_) async => [...chatThreads, newChatThread],
//         );
//       },
//       build: () => ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo),
//       act: (bloc) => bloc
//           .add(ChatThreadCreationRequest(chatThreadToCreate: newChatThread)),
//       expect: () => <ChatThreadsState>[
//         // Upon load
//         ChatThreadsState.loaded(chatThreads),
//         // After creation
//         ChatThreadsState.loaded([...chatThreads, newChatThread])
//       ],
//     );
//   });

//   // blocTest<ChatThreadsBloc, ChatThreadsState>(
//   //   'emits ChatThreadsState with status loading on ChatThreadsLoadRequest',
//   //   build: () {
//   //     return ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo);
//   //   },
//   //   act: (bloc) => bloc.add(ChatThreadsLoadRequest()),
//   //   expect: () => [
//   //     const ChatThreadsState(status: ChatThreadsStatus.loading),
//   //   ],
//   // );

//   // blocTest<ChatThreadsBloc, ChatThreadsState>(
//   //   'emits ChatThreadsState with status loaded on ChatThreadsConsumedDataFromSource',
//   //   build: () {
//   //     return ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo);
//   //   },
//   //   act: (bloc) => bloc.add(ChatThreadsConsumedDataFromSource(chatThreads: [])),
//   //   expect: () => [
//   //     ChatThreadsState(status: ChatThreadsStatus.loaded, chatThreads: []),
//   //   ],
//   // );

//   // blocTest<ChatThreadsBloc, ChatThreadsState>(
//   //   'calls createChatThread on _chatThreadsRepo when ChatThreadCreationRequest is added',
//   //   build: () {
//   //     return ChatThreadsBloc(chatThreadsRepo: chatThreadsRepo);
//   //   },
//   //   act: (bloc) {
//   //     final chatThreadToCreate = ChatThread(users: [MockUser()]);
//   //     bloc.add(
//   //         ChatThreadCreationRequest(chatThreadToCreate: chatThreadToCreate));
//   //   },
//   //   verify: (_) {
//   //     verify(() => chatThreadsRepo.createChatThread(any())).called(1);
//   //   },
//   // );
// }
