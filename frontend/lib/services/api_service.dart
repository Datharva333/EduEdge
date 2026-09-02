import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../features/lesson/models/lesson.dart';

class ApiService {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 330),
        sendTimeout: const Duration(seconds: 60),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    return dio;
  }

  static Future<bool> isBackendUp() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return response.data is Map && response.data['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  static Future<bool> isAiEngineUp() async {
    try {
      final response = await _dio.get(ApiConstants.aiHealth);
      return response.data is Map && response.data['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return {'error': 'Invalid email or password'};
      }
      return {'error': _messageFromDio(error, 'Could not connect to backend')};
    }
  }

  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      await _dio.post(
        ApiConstants.register,
        data: {'full_name': name, 'email': email, 'password': password},
      );

      // /api/v1/auth/register returns the created user, not a JWT.
      // Sign in immediately so AuthProvider receives a real token.
      return await login(email, password);
    } on DioException catch (error) {
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 409) {
        return {'error': _messageFromDio(error, 'Email already registered')};
      }
      return {'error': _messageFromDio(error, 'Registration failed')};
    }
  }

  static Future<List<Lesson>> getLessons() async {
    try {
      final response = await _dio.get(ApiConstants.lessons);
      final data = response.data;
      if (data is! List) {
        throw const ApiException(
          'Backend returned an invalid lessons response',
        );
      }

      return data
          .map(
            (item) => Lesson.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _asApiException(error, fallback: 'Could not load lessons');
    }
  }

  static Future<Lesson> getLesson(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.lessons}/$id');
      if (response.data is! Map) {
        throw const ApiException('Backend returned an invalid lesson response');
      }
      return Lesson.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw _asApiException(error, fallback: 'Could not load this lesson');
    }
  }

  static Future<String> summarize(String lessonId, {String? topic}) async {
    try {
      final response = await _dio.post(
        ApiConstants.summarize,
        data: {
          'lessonId': lessonId,
          if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
        },
      );

      if (response.data is! Map || response.data['summary'] is! String) {
        throw const ApiException('AI returned an invalid summary response');
      }

      final summary = (response.data['summary'] as String).trim();
      if (summary.isEmpty) {
        throw const ApiException('AI returned an empty summary');
      }
      return summary;
    } on DioException catch (error) {
      throw _asApiException(error, fallback: 'Could not generate summary');
    }
  }

  static Future<List<Map<String, dynamic>>?> getQuiz(String lessonId) async {
    try {
      final response = await _dio.post(
        ApiConstants.quiz,
        data: {'lessonId': lessonId, 'num_questions': 5},
      );

      final data = response.data;
      if (data is! Map || data['questions'] is! List) {
        return null;
      }

      final questions = <Map<String, dynamic>>[];

      for (final raw in data['questions'] as List) {
        if (raw is! Map) return null;

        final item = Map<String, dynamic>.from(raw);
        final question = item['question'];
        final options = item['options'];
        final correctIndex = item['correct_index'];

        if (question is! String ||
            options is! List ||
            correctIndex is! int ||
            options.length != 4) {
          return null;
        }

        questions.add({
          'q': question,
          'options': options
              .map((option) => option.toString())
              .toList(growable: false),
          'answer': correctIndex,
        });
      }

      return questions;
    } on DioException {
      return null;
    }
  }

  static Future<String?> chat(String message, String lessonId) async {
    try {
      final response = await _dio.post(
        ApiConstants.chat,
        data: {'message': message, 'lessonId': lessonId},
      );

      final data = response.data;
      if (data is! Map || data['reply'] is! String) {
        return null;
      }

      final reply = (data['reply'] as String).trim();
      return reply.isEmpty ? null : reply;
    } on DioException {
      return null;
    }
  }

  static ApiException _asApiException(
    DioException error, {
    required String fallback,
  }) {
    return ApiException(
      _messageFromDio(error, fallback),
      statusCode: error.response?.statusCode,
    );
  }

  static String _messageFromDio(DioException error, String fallback) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['detail'] != null) {
      return responseData['detail'].toString();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check that the backend and AI engine are running.';
      case DioExceptionType.connectionError:
        return 'Could not connect to ${ApiConstants.baseUrl}.';
      default:
        return fallback;
    }
  }
}
