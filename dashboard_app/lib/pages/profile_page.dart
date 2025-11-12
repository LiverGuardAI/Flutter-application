import 'package:flutter/material.dart';
import '../utils/secure_storage.dart';
import '../api/auth_api.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthApi.logout(); // ✅ 서버에 refresh token 전달
    await SecureStorage.deleteAll(); // ✅ 로컬 토큰 삭제

    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("프로필")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: const Text("로그아웃", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
