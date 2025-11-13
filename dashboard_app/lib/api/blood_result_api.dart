import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';
import '../api/dio_client.dart';

class BloodResultApi {
  static final Dio _dio = DioClient.dio;

  // ---------------------------------------------------
  //  혈액검사 기록 추가 API
  // ---------------------------------------------------
  static Future<bool> addBloodResult({
    required double afp,
    required double ast,
    required double alt,
    required double ggt,
    required double rGtp,
    required double bilirubin,
    required double albumin,
    required double alp,
    required double totalProtein,
    required double pt,
    required double platelet,
    required DateTime takenAt,
  }) async {
    try {
      // 🔥 여기에 저장된 patient_id 읽기
      final storedPatientId = await SecureStorage.read("patient_id");
      if (storedPatientId == null) {
        return false;
      }
      final response = await _dio.post(
        "/blood-results/", // ✔ baseUrl 뒤에 자동으로 붙음
        data: {
          "patient_id": storedPatientId,
          "afp": afp,
          "ast": ast,
          "alt": alt,
          "ggt": ggt,
          "r_gtp": rGtp,
          "bilirubin": bilirubin,
          "albumin": albumin,
          "alp": alp,
          "total_protein": totalProtein,
          "pt": pt,
          "platelet": platelet,
          "taken_at": DateFormat("yyyy-MM-dd").format(takenAt),
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print("❌ BloodResultApi.addBloodResult Error: $e");
      return false;
    }
  }
}
