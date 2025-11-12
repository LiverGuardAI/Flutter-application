import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'blood_test_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  Map<String, dynamic>? userProfile;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        print('토큰 없음 - 더미 데이터 사용');
        setState(() {
          userProfile = {
            'name': '홍길동',
            'birth_date': '1990-01-01',
            'sex': 'male',
            'height': 175,
            'weight': 70,
          };
          isLoading = false;
        });
        return;
      }

      print('토큰 있음 - 실제 API 호출');
      final profile = await ApiService().fetchUserProfile(token);

      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      print('Home: Profile load error: $e');
      setState(() {
        userProfile = {
          'name': '테스트 사용자',
          'birth_date': '1990-01-01',
          'sex': 'male',
          'height': 175,
          'weight': 70,
        };
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildBodyModel(context),
              SizedBox(height: 20),
              SizedBox(height: 20),
              _buildProfileCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 32),
          SizedBox(width: 12),
          Text(
            'Home 화면',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 인체 모델 (간 위치만 터치)
  Widget _buildBodyModel(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '인터랙티브 인체 모델',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Container(
            height: 400,
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/body.png',
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                ),

                // 🔴 간 - 오른쪽 중상단 (폐 아래, 간 위치)
                Positioned(
                  top: 180,
                  left: 160,
                  child: _buildOrganButton(
                    color: Colors.pink.shade300,
                    onTap: () {
                      print('🔴 간 터치!');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BloodTestPage(initialTab: 'liver'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),
          Text(
            '🔍 간을 터치하면 해당 검사 결과를 볼 수 있습니다',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 동그란 버튼 위젯 (재사용)
  Widget _buildOrganButton({
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.85),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(),
      ),
    );
  }

  // API 데이터로 프로필 카드 표시
  Widget _buildProfileCard() {
    if (isLoading) {
      return Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 12),
            Text(
              '프로필을 불러올 수 없습니다',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // API에서 받은 데이터 사용
    final name = userProfile?['name'] ?? '사용자';
    final birthDate = userProfile?['birth_date'] ?? '';
    final sex = userProfile?['sex'] == 'male' ? '남성' : '여성';
    final height = userProfile?['height']?.toString() ?? '-';
    final weight = userProfile?['weight']?.toString() ?? '-';

    // 나이 계산
    int age = 0;
    if (birthDate.isNotEmpty) {
      try {
        final birth = DateTime.parse(birthDate);
        age = DateTime.now().year - birth.year;
      } catch (e) {
        age = 0;
      }
    }

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name님의 프로필',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Divider(height: 24),
          _buildProfileItem(Icons.person, '나이', '${age}세'),
          _buildProfileItem(Icons.wc, '성별', sex),
          _buildProfileItem(Icons.height, '신장/체중', '${height}cm / ${weight}kg'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
