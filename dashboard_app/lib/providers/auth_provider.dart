import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../utils/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  bool isLoggedIn = false;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    final result = await AuthApi.login(username, password);

    isLoading = false;

    if (result["success"] == true) {
      // JWT 토큰 저장
      await SecureStorage.save("access", result["access"]);
      await SecureStorage.save("refresh", result["refresh"]);

      isLoggedIn = true;
      notifyListeners();

      return true;
    } else {
      return false;
    }
  }
}
