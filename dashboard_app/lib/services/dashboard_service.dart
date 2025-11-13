import '../api/dio_client.dart';
import '../models/dashboard_model.dart';
import '../utils/secure_storage.dart';
import 'package:dio/dio.dart';

class DashboardService {
  // 혈액검사 그래프 데이터 가져오기
  static Future<DashboardGraphs> fetchDashboardGraphs() async {
    try {
      final response = await DioClient.dio.get('/dashboard/graphs/');
      return DashboardGraphs.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('혈액검사 데이터 로드 실패: ${e.message}');
    }
  }

  // 사용자 프로필 가져오기
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await DioClient.dio.get('/auth/user/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('프로필 로드 실패: ${e.message}');
    }
  }

  // 시계열 전체 분석 데이터 가져오기
  static Future<Map<String, dynamic>> fetchTimeSeriesAnalysis() async {
    try {
      final response = await DioClient.dio.get('/dashboard/time-series/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('시계열 데이터 로드 실패: ${e.message}');
    }
  }

  // 모든 혈액검사 기록 가져오기
  static Future<List<Map<String, dynamic>>> fetchAllBloodTests() async {
    try {
      final response = await DioClient.dio.get('/blood-results/');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('검사 기록 로드 실패: ${e.message}');
    }
  }

  // 검사 기록 추가
  static Future<void> createBloodTest(Map<String, dynamic> data) async {
    try {
      final patientId = await SecureStorage.read('patient_id');

      if (patientId == null) {
        throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
      }

      final requestData = {...data, 'patient_id': patientId};

      print('Creating blood test with data: $requestData');

      final response = await DioClient.dio.post(
        '/blood-results/',
        data: requestData,
      );

      print('✅ Create response: ${response.data}');
    } on DioException catch (e) {
      print('❌ Error creating blood test: ${e.response?.data}');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      throw Exception('검사 기록 추가 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 검사 기록 수정
  static Future<void> updateBloodTest(
    int bloodResultId,
    Map<String, dynamic> data,
  ) async {
    try {
      // patient_id 포함하여 전송 (백엔드에서 필요할 수 있음)
      final patientId = await SecureStorage.read('patient_id');

      // 불필요한 필드만 제거
      final requestData = Map<String, dynamic>.from(data);
      requestData.remove('blood_result_id');
      requestData.remove('created_at');
      requestData.remove('patient_name');

      // patient_id 추가
      if (patientId != null) {
        requestData['patient_id'] = patientId;
      }

      print('Updating blood test $bloodResultId');
      print('Request data: $requestData');
      print('URL: /blood-results/$bloodResultId/');

      final response = await DioClient.dio.put(
        '/blood-results/$bloodResultId/',
        data: requestData,
      );

      print('✅ Update response status: ${response.statusCode}');
      print('✅ Update response data: ${response.data}');
    } on DioException catch (e) {
      print('❌ Error updating blood test');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Error message: ${e.message}');
      print('❌ Request path: ${e.requestOptions.path}');
      print('❌ Request data: ${e.requestOptions.data}');

      throw Exception('검사 기록 수정 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 검사 기록 삭제
  static Future<void> deleteBloodTest(int bloodResultId) async {
    try {
      print('Deleting blood test $bloodResultId');

      final response = await DioClient.dio.delete(
        '/blood-results/$bloodResultId/',
      );

      print('✅ Delete response: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Error deleting: ${e.response?.data}');
      throw Exception('검사 기록 삭제 실패: ${e.message}');
    }
  }
}
