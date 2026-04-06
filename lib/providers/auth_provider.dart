import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String pin) async {
    // Simular un delay de API y verificar PIN (1234)
    await Future.delayed(const Duration(seconds: 1));
    if (pin == "1234") {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
