import '../api/dio_client.dart';
import 'package:dio/dio.dart';

class SurvivalService {
  /// 생존확률 예측 API 호출
  ///
  /// 필수 파라미터:
  /// - sex: 'male' or 'female'
  /// - age_at_index: 나이
  /// - height: 신장 (cm)
  /// - weight: 체중 (kg)
  /// - bmi: BMI
  /// - AFP: AFP 수치
  /// - albumin: Albumin 수치
  /// - PT: PT 수치
  static Future<Map<String, dynamic>> predictSurvival({
    required String sex,
    required int ageAtIndex,
    required double height,
    required double weight,
    required double bmi,
    required double afp,
    required double albumin,
    required double pt,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/predict-survival/',
        data: {
          'sex': sex,
          'age_at_index': ageAtIndex,
          'height': height,
          'weight': weight,
          'bmi': bmi,
          'afp': afp,  // 소문자로 변경
          'albumin': albumin,
          'pt': pt,  // 소문자로 변경
        },
      );

      print('✅ 생존확률 예측 성공: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ 생존확률 예측 실패: ${e.message}');
      print('📤 요청 데이터: ${e.requestOptions.data}');
      print('📥 응답 데이터: ${e.response?.data}');
      throw Exception('생존확률 예측 실패: ${e.message}');
    }
  }

  /// BMI 계산 헬퍼 함수
  static double calculateBMI(double height, double weight) {
    if (height <= 0 || weight <= 0) return 0.0;
    final heightInMeters = height / 100.0;
    return weight / (heightInMeters * heightInMeters);
  }
}
