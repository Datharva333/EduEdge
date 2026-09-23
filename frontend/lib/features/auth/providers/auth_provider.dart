// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../services/api_service.dart';

// class AuthProvider extends ChangeNotifier {
//   bool _isLoggedIn = false;
//   String _userName = '';
//   String _token = '';
//   String _error = '';

//   bool get isLoggedIn => _isLoggedIn;
//   String get userName => _userName;
//   String get token => _token;
//   String get error => _error;

//   Future<bool> login(String email, String password) async {
//     _error = '';
//     notifyListeners();
//     final result = await ApiService.login(email, password);
//     if (result == null) {
//       _error = 'Something went wrong';
//       notifyListeners();
//       return false;
//     }
//     if (result.containsKey('error')) {
//       _error = result['error'];
//       notifyListeners();
//       return false;
//     }
//     _token = result['token'] ?? '';
//     _userName = result['user']['name'] ?? email.split('@').first;
//     _isLoggedIn = true;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('token', _token);
//     await prefs.setString('userName', _userName);
//     notifyListeners();
//     return true;
//   }

//   Future<bool> register(String name, String email, String password) async {
//     _error = '';
//     notifyListeners();
//     final result = await ApiService.register(name, email, password);
//     if (result == null) {
//       _error = 'Something went wrong';
//       notifyListeners();
//       return false;
//     }
//     if (result.containsKey('error')) {
//       _error = result['error'];
//       notifyListeners();
//       return false;
//     }
//     _token = result['token'] ?? '';
//     _userName = name;
//     _isLoggedIn = true;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('token', _token);
//     await prefs.setString('userName', _userName);
//     notifyListeners();
//     return true;
//   }

//   Future<void> logout() async {
//     _isLoggedIn = false;
//     _userName = '';
//     _token = '';
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';

/// Tracks the student's local identity for EduEdge.
///
/// There is no server, no token, and no password anywhere in this class —
/// "logging in" just means a name + class have been saved on-device once.
/// Everything here works fully offline.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String _userName = '';
  String _studentClass = '';
  String _error = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String get userName => _userName;
  String get studentClass => _studentClass;
  String get error => _error;

  /// Call once, early in app startup (e.g. from a splash widget or the
  /// router's redirect), to load any profile already saved on this device.
  Future<void> init() async {
    final profile = await LocalStorageService.getProfile();

    if (profile != null) {
      _userName = profile['name'] ?? '';
      _studentClass = profile['studentClass'] ?? '';
      _isLoggedIn = true;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Saves the student's name + class locally and marks them as "logged
  /// in". Called once from the onboarding screen. Returns false only if
  /// the input is invalid — there is nothing to fail over the network.
  Future<bool> setupProfile(String name, String studentClass) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _error = 'Please enter your name';
      notifyListeners();
      return false;
    }

    if (studentClass.isEmpty) {
      _error = 'Please select your class';
      notifyListeners();
      return false;
    }

    _error = '';

    await LocalStorageService.saveProfile(
      name: trimmedName,
      studentClass: studentClass,
    );

    _userName = trimmedName;
    _studentClass = studentClass;
    _isLoggedIn = true;

    notifyListeners();
    return true;
  }

  /// Clears the local profile only. Quiz scores/progress are untouched —
  /// this just forces onboarding to run again next launch.
  Future<void> logout() async {
    await LocalStorageService.clearProfile();

    _isLoggedIn = false;
    _userName = '';
    _studentClass = '';

    notifyListeners();
  }
}
