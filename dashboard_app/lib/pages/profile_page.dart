import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../utils/secure_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await AuthApi.getProfile();

    if (result["success"]) {
      setState(() {
        userData = result["data"];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result["message"].toString();
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SecureStorage.deleteAll();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 프로필"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "로그아웃",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final user = userData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 👤 상단 프로필
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user["name"] ?? "-",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user["birth_date"] ?? "-",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Divider(thickness: 1.2),

          // 📋 상세 정보 카드
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoTile(Icons.male, "성별", user["sex"]),
                  _infoTile(Icons.height, "키 (cm)", user["height"]),
                  _infoTile(Icons.monitor_weight, "체중 (kg)", user["weight"]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 🚪 로그아웃 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("로그아웃"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, dynamic value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        value?.toString() ?? "-",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
