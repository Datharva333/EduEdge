class ApiConstants {
  /// Override at run/build time instead of editing source code:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/api/v1/auth/register';

  static const String lessons = '/api/v1/lessons';
  static const String aiHealth = '/api/v1/ai/health';
  static const String summarize = '/api/v1/ai/summarize';

  // These tools still use the legacy contract until their proper backend
  // routes are implemented in the same way as summarize.
  static const String quiz = '/ai/quiz';
  static const String chat = '/ai/chat';
}
