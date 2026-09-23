import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for everything EduEdge needs to
/// remember on-device, with no network or backend involved:
///   - the student's local profile (name + class)
///   - which lesson was opened last
///   - quiz scores and completion status, per lesson
///
/// All reads/writes hit local disk only, so this works identically with
/// wifi, mobile data, or fully in airplane mode.
class LocalStorageService {
  // ---- Key builders -------------------------------------------------

  static const _keyProfileName = 'profileName';
  static const _keyProfileClass = 'profileClass';
  static const _keyLastOpenedLesson = 'lastOpenedLesson';

  static String _lastScoreKey(String lessonId) => 'lastQuizScore:$lessonId';
  static String _bestScoreKey(String lessonId) => 'bestQuizScore:$lessonId';
  static String _totalKey(String lessonId) => 'lastQuizTotal:$lessonId';
  static String _completedKey(String lessonId) => 'lessonCompleted:$lessonId';

  // ---- Profile (replaces server login/register) ----------------------

  /// Saves the student's local profile. Called once during onboarding.
  static Future<void> saveProfile({
    required String name,
    required String studentClass,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileName, name);
    await prefs.setString(_keyProfileClass, studentClass);
  }

  /// Returns the saved profile, or null if onboarding hasn't happened yet.
  /// Shape: {'name': String, 'studentClass': String}
  static Future<Map<String, String>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyProfileName);
    final studentClass = prefs.getString(_keyProfileClass);

    if (name == null || name.isEmpty) {
      return null;
    }

    return {
      'name': name,
      'studentClass': studentClass ?? '',
    };
  }

  /// Clears the local profile only (does not touch quiz/progress data).
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileName);
    await prefs.remove(_keyProfileClass);
  }

  // ---- Last opened lesson --------------------------------------------

  static Future<void> setLastOpenedLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOpenedLesson, lessonId);
  }

  static Future<String?> getLastOpenedLesson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastOpenedLesson);
  }

  // ---- Quiz results ----------------------------------------------------

  /// Call this the moment a quiz finishes (e.g. when `_done` is set to
  /// true in quiz_screen.dart). Always updates the "last" score, and only
  /// overwrites "best" if this attempt beat the previous best.
  /// Marks the lesson as completed regardless of score.
  static Future<void> saveQuizResult({
    required String lessonId,
    required int score,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_lastScoreKey(lessonId), score);
    await prefs.setInt(_totalKey(lessonId), total);
    await prefs.setBool(_completedKey(lessonId), true);

    final currentBest = prefs.getInt(_bestScoreKey(lessonId)) ?? -1;
    if (score > currentBest) {
      await prefs.setInt(_bestScoreKey(lessonId), score);
    }
  }

  /// Best score ever achieved for this lesson, or null if never attempted.
  static Future<int?> getBestScore(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey(lessonId));
  }

  /// Most recent score for this lesson, or null if never attempted.
  static Future<int?> getLastScore(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastScoreKey(lessonId));
  }

  /// Total question count from the last attempt (needed to render "2/3").
  static Future<int?> getLastQuizTotal(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey(lessonId));
  }

  static Future<bool> isLessonCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey(lessonId)) ?? false;
  }

  // ---- Bulk read for the Progress screen ------------------------------

  /// Returns a per-lesson progress map, for a given list of lesson ids:
  /// { lessonId: {completed, bestScore, lastScore, total} }
  /// Lets progress_screen.dart build real stats in one call instead of
  /// awaiting each lesson's fields separately.
  static Future<Map<String, Map<String, dynamic>>> getAllProgress(
    List<String> lessonIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Map<String, dynamic>>{};

    for (final id in lessonIds) {
      result[id] = {
        'completed': prefs.getBool(_completedKey(id)) ?? false,
        'bestScore': prefs.getInt(_bestScoreKey(id)),
        'lastScore': prefs.getInt(_lastScoreKey(id)),
        'total': prefs.getInt(_totalKey(id)),
      };
    }

    return result;
  }
}