// import 'package:chatbond/data/datasources/chat_data_source.dart';
// import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
// import 'package:chatbond/domain/entities/chat_thread.dart';
// import 'package:chatbond/domain/entities/user.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';

// class MockChatDataSource extends Mock implements ChatDataSource {}

// class MockCollection extends Mock implements RecordService {}

// class MockRecordModel extends Mock implements RecordModel {}

// void main() {
//   late ChatThreadsRepo chatThreadsRepo;
//   late MockCollection collection;
//   late MockChatDataSource chatDataSource;

//   setUp(() {
//     collection = MockCollection();
//     chatDataSource = MockChatDataSource();
//     chatThreadsRepo = ChatThreadsRepo(chatDataSource: chatDataSource);

//   });

//   group('updateChatThreads', () {
//     test('should update existing chat thread', () {
//       // Create a list of existing chat threads
//       final existingChatThreads = [
//         ChatThread(
//           id: '1',
//           users: const [User('1', 'user1', 'user1@email.com', 'user1_avatar')],
//           createdAt: DateTime.now(),
//         ),
//         ChatThread(
//           id: '2',
//           users: const [User('2', 'user2', 'user2@email.com', 'user2_avatar')],
//           createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
//         ),
//       ];

//       // Create an updated chat thread
//       final updatedChatThread = ChatThread(
//         id: '1',
//         users: const [
//           User(
//             '1',
//             'updated_user1',
//             'updated_user1@email.com',
//             'updated_user1_avatar',
//           )
//         ],
//         createdAt: DateTime.now(),
//       );

//       // Call the updateChatThreads method
//       chatThreadsRepo.updateChatThreads(existingChatThreads, updatedChatThread);

//       // Verify the results
//       expect(existingChatThreads.length, 2);
//       expect(existingChatThreads[0].id, '1');
//       expect(existingChatThreads[0].users[0].username, 'updated_user1');
//     });

//     test('should add a new chat thread to the list', () {
//       // Create a list of existing chat threads
//       final existingChatThreads = [
//         ChatThread(
//           id: '1',
//           users: const [User('1', 'user1', 'user1@email.com', 'user1_avatar')],
//           createdAt: DateTime.now(),
//         ),
//         ChatThread(
//           id: '2',
//           users: const [User('2', 'user2', 'user2@email.com', 'user2_avatar')],
//           createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
//         ),
//       ];

//       // Create a new chat thread
//       final newChatThread = ChatThread(
//         id: '3',
//         users: const [User('3', 'user3', 'user3@email.com', 'user3_avatar')],
//         createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
//       );

//       // Call the updateChatThreads method
//       chatThreadsRepo.updateChatThreads(existingChatThreads, newChatThread);

//       // Verify the results
//       expect(existingChatThreads.length, 3);
//       expect(
//         existingChatThreads.any((chatThread) => chatThread.id == '3'),
//         true,
//       );
//     });

//     // group('createChatThread', () {
//     //   test('should create a chat thread and add it to the stream', () async {
//     //     // Arrange
//     //     final mockRecordModel = MockRecordModel();
//     //     const chatThread = ChatThread(
//     //       users: [
//     //         User('1', 'user1', 'user1@example.com', 'avatar1'),
//     //       ],
//     //     );

//     //     when(
//     //       () => collection.create(
//     //         body: {
//     //           'users': [for (var user in chatThread.users) user.id.toString()]
//     //         },
//     //       ),
//     //     ).thenAnswer((_) async => mockRecordModel);

//     //     when(() => mockRecordModel.toJson()).thenReturn({
//     //       'id': '1',
//     //       'created': '2023-04-05T10:00:00.000Z',
//     //       'users': [
//     //         {
//     //           'id': '1',
//     //           'username': 'user1',
//     //           'email': 'user1@example.com',
//     //           'avatar': 'avatar1'
//     //         }
//     //       ],
//     //     });

//     //     final remoteChatThread = RemoteChatThread.fromRecord(mockRecordModel);

//     //     // Act
//     //     await chatThreadsRepo.createChatThread(chatThread);

//     //     // Assert
//     //     expect(chatThreadsRepo.stream, emits(anything));
//     //     expect(
//     //       chatThreadsRepo.stream,
//     //       emits(
//     //         predicate<List<ChatThread>>((list) {
//     //           return list.any((ct) => ct.id == remoteChatThread.id);
//     //         }),
//     //       ),
//     //     );
//     //   });
//     // });
//   });
// }
