import 'dart:convert';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/chats/chats_interface.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

class Chats implements ChatsInterface {
  Chats({
    required this.baseUrl,
    required this.client,
    required this.accessTokenGetter,
  });

  final String baseUrl;
  final http.Client client;
  final TokenGetter accessTokenGetter;

  @override
  Future<Interlocutor> getCurrentInterlocutor() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/api/v1/interlocutors/me/');
    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return Interlocutor.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to fetch current interlocutor');
    }
  }

  @override
  Future<ChatThread> fetchChatThreadWithQuestionThreads(String id) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/chat-threads/$id/with-question-threads/';
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      return ChatThread.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load chat thread with question threads');
    }
  }

  @override
  Future<List<ChatThread>> getChatThreads() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/chat-threads/without-question-threads/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as List<dynamic>;
      return responseBody
          .map((json) => ChatThread.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch chat threads');
    }
  }

  @override
  Future<QuestionThread> fetchQuestionThread(String id) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/api/v1/question-threads/$id/');
    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return QuestionThread.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to fetch question thread');
    }
  }

  @override
  Future<List<QuestionChat>> fetchQuestionChats(
    String questionThreadId,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url =
        Uri.parse('$baseUrl/api/v1/question-threads/$questionThreadId/chats/');

    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as List<dynamic>;
      return jsonResponse
          .map((e) => QuestionChat.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch question chats');
    }
  }

  @override
  Future<QuestionChat> createQuestionChat(
    String questionThreadId,
    String content,
    String status,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/api/v1/question-chats/');
    final response = await client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'question_thread': questionThreadId,
        'content': content,
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      return QuestionChat.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to create question chat');
    }
  }

  @override
  Future<void> setSeenAt(String questionThreadId) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/api/v1/set-seen-at/$questionThreadId/');
    final response = await client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set seen at');
    }
  }

  @override
  Future<PaginatedQuestionThreadList> getChatThreadQuestionThreads(
    // TODO: remove waitingOnOther, not supported anymore
    String chatThreadId, {
    String? pageUrl,
    bool? waitingOnOther,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = pageUrl ??
        '$baseUrl/api/v1/chat-threads/$chatThreadId/question-threads/';

    var uri = Uri.parse(apiUrl);

    if (waitingOnOther != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['waiting_on_others'] = waitingOnOther.toString();
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PaginatedQuestionThreadList.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get question threads for chat thread');
    }
  }

  @override
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnOthers({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl =
        pageUrl ?? '$baseUrl/api/v1/waiting-on-others-question-threads/';

    var uri = Uri.parse(apiUrl);

    if (chatThreadId != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['chat_thread_id'] = chatThreadId;
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PaginatedQuestionThreadList.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get question threads for chat thread');
    }
  }

  @override
  Future<PaginatedQuestionThreadList> getQuestionThreadsWaitingOnCurrUser({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl =
        pageUrl ?? '$baseUrl/api/v1/waiting-on-you-question-threads/';

    var uri = Uri.parse(apiUrl);

    if (chatThreadId != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['chat_thread_id'] = chatThreadId;
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PaginatedQuestionThreadList.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get question threads for chat thread');
    }
  }

  @override
  Future<List<Interlocutor>> getChatInterlocutors({bool? includeSelf}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = '$baseUrl/api/v1/chat-interlocutors/';
    var uri = Uri.parse(apiUrl);

    if (includeSelf != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['include_self'] = includeSelf.toString();
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List;
      logError('getChatInterlocutors : ${body}');

      return body
          .map(
            (dynamic item) =>
                Interlocutor.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Failed to get chat interlocutors');
    }
  }

  @override
  Future<List<DraftQuestionThread>?> fetchDraftsByQuestionId(
    String questionId,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url =
        Uri.parse('$baseUrl/api/v1/draft-question-threads/get/$questionId/');
    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as List;
      return jsonResponse
          .map(
            (item) =>
                DraftQuestionThread.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      return null;
    }
  }

  @override
  Future<PaginatedDraftQuestionThreadList> listDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = pageUrl ?? '$baseUrl/api/v1/draft-question-threads/';

    var uri = Uri.parse(apiUrl);

    if (chatThreadId != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['chat_thread_id'] = chatThreadId;
      uri = uri.replace(queryParameters: queryParameters);
    }
    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedDraftQuestionThreadList.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to get drafts');
    }
  }

  @override
  Future<DraftQuestionThread?> createDraftQuestionThread(
    DraftQuestionThread draftQuestionThread,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/api/v1/draft-question-threads/');
    final response = await client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draftQuestionThread.toJson()),
    );

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return DraftQuestionThread.fromJson(jsonResponse);
    } else {
      return null;
    }
  }

  @override
  Future<DraftQuestionThread> publishDraft(String draftId) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final response = await client.post(
      Uri.parse('$baseUrl/api/v1/draft-question-threads/$draftId/publish/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return DraftQuestionThread.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to publish draft');
    }
  }

  @override
  Future<DraftQuestionThread> retrieveDraft(String draftId) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/draft-question-threads/$draftId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DraftQuestionThread.fromJson(body);
    } else {
      throw Exception('Failed to retrieve draft');
    }
  }

  @override
  Future<void> deleteDraftQuestionThread(String id) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = '$baseUrl/api/v1/draft-question-threads/$id/';

    final response = await client.delete(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete draft');
    }
  }

  @override
  Future<PaginatedQuestions> listPaginatedQuestionsOfDraftQuestionThreads({
    String? chatThreadId,
    String? pageUrl,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = pageUrl ?? '$baseUrl/api/v1/draft-question-threads-all/';

    var uri = Uri.parse(apiUrl);

    if (chatThreadId != null) {
      final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters['chat_thread_id'] = chatThreadId;
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PaginatedQuestions.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get draft question threads for chat thread');
    }
  }

  @override
  Future<UpsertResult> upsertDraft(
    DraftQuestionThread draft,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse(
      '$baseUrl/api/v1/draft-question-threads/${draft.question}/${draft.otherInterlocutor.id}/upsert/',
    );
    final response = await client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final draft = DraftQuestionThread.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      return UpsertResult(
        draft: draft,
        wasCreated: response.statusCode == 201,
      );
    } else {
      throw Exception('Failed to upsert draft');
    }
  }

  @override
  Future<ChatThreadStats> getChatThreadStats({String? chatThreadId}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    late Uri url;

    if (chatThreadId != null) {
      url = Uri.parse(
        '$baseUrl/api/v1/chat-thread-stats/$chatThreadId/',
      );
    } else {
      url = Uri.parse(
        '$baseUrl/api/v1/chat-thread-stats/',
      );
    }

    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return ChatThreadStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get chat thread stats');
    }
  }
}
