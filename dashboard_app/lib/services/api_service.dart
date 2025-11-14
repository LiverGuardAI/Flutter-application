import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/dashboard_model.dart'; // 기존 모델
import '../utils/secure_storage.dart';

// --- [신규] DDI 모델 임포트 ---
// (이 파일들은 React의 결과 JSON을 기반으로 생성해야 합니다)
// 예시: import '../models/ddi_models.dart';

class ApiService {
  // 기존 인증/대시보드 서버
  static const String baseUrl = 'http://10.0.2.2:8000';

  // --- [신규] DDI 서버 (api_v2.py) ---
  // [중요!] 안드로이드 에뮬레이터는 10.0.2.2가 PC의 127.0.0.1입니다.
  // 실제 폰 테스트 시에는 PC의 LAN IP (예: 192.168.0.x:5000)를 사용하세요.
  static const String ddiBaseUrl = 'http://10.0.2.2:5000';

  // --- 기존 코드 (토큰 및 프로필) ---
  // (헬퍼: 저장된 토큰 가져오기)
  static Future<String?> getToken() async {
    try {
      final token = await SecureStorage.read('access');
      if (token != null && token.isNotEmpty) {
        print(
          '토큰 로드: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
        return token;
      }
      print('저장된 토큰 없음');
      return null;
    } catch (e) {
      print('토큰 로드 오류: $e');
      return null;
    }
  }

  // (헬퍼: 토큰 저장)
  static Future<void> saveToken(String accessToken, String refreshToken) async {
    try {
      await SecureStorage.save('access', accessToken);
      await SecureStorage.save('refresh', refreshToken);
      print('토큰 저장 완료');
    } catch (e) {
      print('토큰 저장 오류: $e');
    }
  }

  // (헬퍼: 토큰 삭제)
  static Future<void> clearToken() async {
    try {
      await SecureStorage.delete('access');
      await SecureStorage.delete('refresh');
      print('토큰 삭제 완료');
    } catch (e) {
      print('토큰 삭제 오류: $e');
    }
  }

  // (사용자 프로필 가져오기)
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

  // (혈액검사 그래프 가져오기)
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

  // --- [신규] DDI API 함수들 ---

  // 1. (DDI) 약물 비동기 검색
  Future<List<Map<String, String>>> searchDrugs(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      // [중요] ddiBaseUrl 사용
      final response = await http.get(
        Uri.parse('$ddiBaseUrl/api/search_drugs?query=$query'),
      );

      if (response.statusCode == 200) {
        // [{value: '...', label: '...'}, ...]
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Map<String, String>.from(item)).toList();
      } else {
        throw Exception('Failed to search drugs');
      }
    } catch (e) {
      print('searchDrugs 오류: $e');
      rethrow;
    }
  }

  // 2. (DDI) 통합 검사 실행
  Future<Map<String, dynamic>> checkAllDDI(List<String> drugs) async {
    try {
      final response = await http.post(
        Uri.parse('$ddiBaseUrl/api/check_all'), // [중요] ddiBaseUrl 사용
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drugs': drugs}),
      );

      if (response.statusCode == 200) {
        // { ai_predictions, drugbank_checks, ... }
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to check DDI: ${response.body}');
      }
    } catch (e) {
      print('checkAllDDI 오류: $e');
      rethrow;
    }
  }

  // 3. (DDI) 대체 약물 추천
  Future<Map<String, dynamic>> getAlternatives(
    String drugToReplace,
    List<String> opponentDrugs,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$ddiBaseUrl/api/get_alternatives'), // [중요] ddiBaseUrl 사용
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'drug_to_replace': drugToReplace,
          'opponent_drugs': opponentDrugs,
        }),
      );

      if (response.statusCode == 200) {
        // { safe_alternatives, risky_alternatives }
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get alternatives: ${response.body}');
      }
    } catch (e) {
      print('getAlternatives 오류: $e');
      rethrow;
    }
  }
}
