import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.length >= 4) {
      _isLoggedIn = true;
      _userName = email.split('@').first;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    notifyListeners();
  }
}
