import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/healthcare_model.dart';

class HealthcareService {
  // Healthcare Map API는 로컬 Django 서버 사용 (안드로이드 에뮬레이터)
  // 실제 기기 테스트 시: PC의 LAN IP로 변경 (예: http://192.168.0.x:8000)
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// 병원/의원/약국 통합 검색
  static Future<HealthcareSearchResult> searchHealthcare({
    String? query,
    String type = 'all', // all, hospital, clinic, pharmacy
    String? departmentCode,
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      queryParams['type'] = type;

      if (departmentCode != null) {
        queryParams['department'] = departmentCode;
      }

      // 좌표를 고정 소수점 형식으로 변환 (지수 표기 방지)
      if (minX != null) queryParams['min_x'] = minX.toStringAsFixed(6);
      if (maxX != null) queryParams['max_x'] = maxX.toStringAsFixed(6);
      if (minY != null) queryParams['min_y'] = minY.toStringAsFixed(6);
      if (maxY != null) queryParams['max_y'] = maxY.toStringAsFixed(6);

      final uri = Uri.parse(
        '$baseUrl/healthcare/search/',
      ).replace(queryParameters: queryParams);

      print('🔍 Healthcare Search: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return HealthcareSearchResult.fromJson(jsonData);
      } else if (response.statusCode >= 500) {
        // 서버 에러 - 재시도 가능
        throw Exception('서버 오류: ${response.statusCode}');
      } else if (response.statusCode >= 400) {
        // 클라이언트 에러 - 재시도 불가
        throw Exception('요청 오류: ${response.statusCode}');
      } else {
        throw Exception('검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Healthcare search error: $e');
      rethrow;
    }
  }

  /// 진료과목 목록 조회
  static Future<List<Department>> fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/healthcare/departments/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData.map((d) => Department.fromJson(d)).toList();
      } else if (response.statusCode >= 500) {
        throw Exception('서버 오류: ${response.statusCode}');
      } else if (response.statusCode >= 400) {
        throw Exception('요청 오류: ${response.statusCode}');
      } else {
        throw Exception('진료과목 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Departments fetch error: $e');
      rethrow;
    }
  }
}
