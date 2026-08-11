import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = '';
  String _token = '';
  String _error = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get token => _token;
  String get error => _error;

  Future<bool> login(String email, String password) async {
    _error = '';
    notifyListeners();
    final result = await ApiService.login(email, password);
    if (result == null) {
      _error = 'Something went wrong';
      notifyListeners();
      return false;
    }
    if (result.containsKey('error')) {
      _error = result['error'];
      notifyListeners();
      return false;
    }
    _token = result['token'] ?? '';
    _userName = result['user']['name'] ?? email.split('@').first;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token);
    await prefs.setString('userName', _userName);
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _error = '';
    notifyListeners();
    final result = await ApiService.register(name, email, password);
    if (result == null) {
      _error = 'Something went wrong';
      notifyListeners();
      return false;
    }
    if (result.containsKey('error')) {
      _error = result['error'];
      notifyListeners();
      return false;
    }
    _token = result['token'] ?? '';
    _userName = name;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token);
    await prefs.setString('userName', _userName);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _token = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
