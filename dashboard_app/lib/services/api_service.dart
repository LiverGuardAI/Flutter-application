import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_model.dart';

class ApiService {
  static const String baseUrl = 'http://34.67.62.238:8000';

  // 헬퍼: 저장된 토큰 가져오기
  static Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        print('토큰 로드: ${token.substring(0, 20)}...');
      } else {
        print('저장된 토큰 없음');
      }

      return token;
    } catch (e) {
      print('토큰 로드 오류: $e');
      return null;
    }
  }

  // 헬퍼: 토큰 저장 (로그인 페이지에서 사용 가능)
  static Future<void> saveToken(String accessToken, String refreshToken) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      print('토큰 저장 완료');
    } catch (e) {
      print('토큰 저장 오류: $e');
    }
  }

  // 헬퍼: 토큰 삭제 (로그아웃 시)
  static Future<void> clearToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      print('토큰 삭제 완료');
    } catch (e) {
      print('토큰 삭제 오류: $e');
    }
  }

  // 사용자 프로필 가져오기
  Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    try {
      print('프로필 로드 시작...');
      print('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/auth/user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final profile = jsonDecode(utf8.decode(response.bodyBytes));
        print('프로필 로드 성공: ${profile['name']}');
        return profile;
      } else {
        print('오류: ${response.body}');
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      rethrow;
    }
  }

  // 혈액검사 그래프 가져오기
  Future<DashboardGraphs> fetchDashboardGraphs(String token) async {
    try {
      print('그래프 로드 시작...');
      print('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/dashboard/graphs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        print('그래프 로드 성공');
        return DashboardGraphs.fromJson(json);
      } else {
        print('오류: ${response.body}');
        throw Exception('Failed to load graphs: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      rethrow;
    }
  }
}
