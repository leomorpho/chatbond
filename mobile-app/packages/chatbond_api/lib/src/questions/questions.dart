import 'dart:convert';
import 'dart:io';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/questions/questions_interface.dart';
import 'package:http/http.dart' as http;

class Questions implements QuestionsInterface {
  Questions({
    required this.baseUrl,
    required this.client,
    required this.accessTokenGetter,
  });

  final String baseUrl;
  final http.Client client;
  final TokenGetter accessTokenGetter;

  @override
  Future<PaginatedQuestions> getFavoritedQuestions({String? pageUrl}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = pageUrl ?? '$baseUrl/api/v1/favorite-questions/';
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return PaginatedQuestions.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to fetch favorite questions');
    }
  }

  @override
  Future<List<Question>> getOnboardingQuestions() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/onboarding-questions/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as List<dynamic>;
      return responseData
          .map((data) => Question.fromJson(data as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch onboarding questions');
    }
  }

  @override
  Future<List<Question>> getQuestionsFeed() async {
    // TODO: unused rn
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/questions-feed/';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as List<dynamic>;
      return responseData
          .map((data) => Question.fromJson(data as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load questions feed');
    }
  }

  @override
  Future<PaginatedQuestions> searchQuestions({
    required String search,
    int numResults = 10,
    int page = 1,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl =
        '$baseUrl/api/v1/search-questions/?search=$search&num_results=$numResults&page=$page';
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return PaginatedQuestions.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to search questions');
    }
  }

  @override
  Future<QuestionFeedWithMetadata> getHomeFeed({String? pageUrl}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final apiUrl = pageUrl ?? '$baseUrl/api/v1/home-feed/';
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return QuestionFeedWithMetadata.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load home feed');
    }
  }

  @override
  Future<void> markQuestionsAsSeen(List<String> questionIds) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final body = jsonEncode({
      'question_ids': questionIds,
    });

    final response = await client.post(
      Uri.parse('$baseUrl/api/v1/mark-question-as-seen/mark_as_seen/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark questions as seen');
    }
  }

  @override
  Future<bool> rateQuestion(String questionId, VoteStatus status) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final body = jsonEncode({
      'status': status.value,
    });

    final response = await client.post(
      Uri.parse(
        '$baseUrl/api/v1/questions/$questionId/rate/',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return true;
    } else if (response.statusCode == HttpStatus.conflict) {
      return false;
    } else {
      throw Exception('Failed to rate question');
    }
  }

  Future<bool> favoriteQuestion(
    String questionId,
    FavoriteState action,
  ) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final body = jsonEncode({
      'question_id': questionId,
      'action': action.value,
    });

    final response = await client.post(
      Uri.parse(
        '$baseUrl/api/v1/edit-favorites/favorite/',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to change question favorite status');
    }
  }
}
