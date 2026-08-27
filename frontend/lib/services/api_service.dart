import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Content-Type'] = 'application/json';
          options.headers['ngrok-skip-browser-warning'] = 'true';
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Future<bool> isBackendUp() async {
    try {
      final res = await _dio.get(ApiConstants.health);
      return res.data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final res = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {'error': 'Invalid email or password'};
      }
      return {'error': 'Connection failed. Is the backend running?'};
    }
  }

  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/register',
        data: {'full_name': name, 'email': email, 'password': password},
      );
      final data = res.data;
      return {
        'token': data['access_token'] ?? '',
        'user': {'name': name},
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {'error': 'Email already registered'};
      }
      return {'error': 'Registration failed. Try again.'};
    }
  }

  static Future<List<Map<String, dynamic>>> getLessons() async {
    try {
      final res = await _dio.get(ApiConstants.lessons);
      return List<Map<String, dynamic>>.from(res.data);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLesson(String id) async {
    try {
      final res = await _dio.get('${ApiConstants.lessons}/$id');
      return res.data;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> summarize(String lessonId) async {
    try {
      final res = await _dio.post(
        ApiConstants.summarize,
        data: {'lessonId': lessonId},
      );
      return res.data['summary'];
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getQuiz(String lessonId) async {
    try {
      final res = await _dio.post(
        ApiConstants.quiz,
        data: {'lessonId': lessonId},
      );
      return List<Map<String, dynamic>>.from(res.data['questions']);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> chat(String message, String lessonId) async {
    try {
      final res = await _dio.post(
        ApiConstants.chat,
        data: {'message': message, 'lessonId': lessonId},
      );
      return res.data['reply'];
    } catch (_) {
      return null;
    }
  }
}
