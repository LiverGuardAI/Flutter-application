import 'package:flutter/material.dart';
import '../utils/secure_storage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SecureStorage.deleteAll(); // ✅ 토큰 삭제

    // ✅ 전체 스택 제거하고 로그인으로 이동
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("프로필"), centerTitle: true),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: const Text(
            "로그아웃",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
