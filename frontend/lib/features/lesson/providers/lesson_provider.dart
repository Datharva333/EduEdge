import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../services/api_service.dart';
import '../models/lesson.dart';

class LessonProvider extends ChangeNotifier {
  List<Lesson> _lessons = const [];
  bool _loading = false;
  String? _errorMessage;
  bool _hasLoaded = false;
  bool _backendOnline = false;

  List<Lesson> get lessons => List.unmodifiable(_lessons);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _hasLoaded;
  bool get backendOnline => _backendOnline;

  List<String> get subjects {
    final values = _lessons.map((lesson) => lesson.subject).toSet().toList();
    values.sort();
    return values;
  }

  Lesson? findById(String id) {
    for (final lesson in _lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  Future<void> loadLessons({bool force = false}) async {
    if (_loading) return;
    if (_hasLoaded && !force) return;

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lessons = await ApiService.getLessons();
      _hasLoaded = true;
      _backendOnline = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _backendOnline = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Lesson> loadLesson(String id) async {
    final existing = findById(id);
    if (existing != null) return existing;

    try {
      final lesson = await ApiService.getLesson(id);
      _lessons = [..._lessons, lesson];
      notifyListeners();
      return lesson;
    } on ApiException {
      rethrow;
    }
  }
}
