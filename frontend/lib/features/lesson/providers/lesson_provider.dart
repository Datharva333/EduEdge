import 'package:flutter/foundation.dart';

import '../../../services/mock_service.dart';
import '../models/lesson.dart';

class LessonProvider extends ChangeNotifier {
  List<Lesson> _lessons = const [];
  bool _loading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  List<Lesson> get lessons => List.unmodifiable(_lessons);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _hasLoaded;

  bool get backendOnline => false;

  List<String> get subjects {
    final values = _lessons.map((lesson) => lesson.subject).toSet().toList();
    values.sort();
    return values;
  }

  Lesson? findById(String id) {
    for (final lesson in _lessons) {
      if (lesson.id == id) {
        return lesson;
      }
    }

    return null;
  }

  Future<void> loadLessons({bool force = false}) async {
    if (_loading) {
      return;
    }

    if (_hasLoaded && !force) {
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lessons = MockService.lessons
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();

      _hasLoaded = true;
    } catch (error) {
      _errorMessage = 'Could not load local lessons: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Lesson> loadLesson(String id) async {
    final existing = findById(id);

    if (existing != null) {
      return existing;
    }

    if (!_hasLoaded) {
      await loadLessons();
    }

    final lesson = findById(id);

    if (lesson == null) {
      throw Exception('Local lesson not found: $id');
    }

    return lesson;
  }
}
