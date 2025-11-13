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
    required int patientId,
    required int ast,
    required int alt,
    required int alp,
    required int ggt,
    required double bilirubin,
    required double albumin,
    required double inr,
    required int platelet,
    required int afp,
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
          "ast": ast,
          "alt": alt,
          "alp": alp,
          "ggt": ggt,
          "bilirubin": bilirubin,
          "albumin": albumin,
          "inr": inr,
          "platelet": platelet,
          "afp": afp,
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
