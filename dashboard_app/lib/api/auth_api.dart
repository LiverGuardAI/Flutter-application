// lib/api/auth_api.dart
import 'package:dio/dio.dart';
import 'dio_client.dart';

class AuthApi {
  /// Django 커스텀 로그인: POST /api/login/
  /// body: { "user_id": "...", "password": "..." }
  /// response 예시: { "access": "...", "refresh": "..." }  또는 { "token": "..." }
  static Future<Map<String, dynamic>> login(
    String userId,
    String password,
  ) async {
    final dio = DioClient.dio;

    try {
      final res = await dio.post(
        "/auth/login/", // 최종: http://10.0.2.2:8000/api/login/
        data: {"user_id": userId.trim(), "password": password.trim()},
      );

      // 백엔드 응답 키에 유연하게 대응
      final data = res.data ?? {};
      final access = data["access"] ?? data["token"]; // token 하나만 주는 경우 대응
      final refresh = data["refresh"]; // 없으면 null

      if (access == null) {
        return {"success": false, "message": "토큰이 응답에 없습니다."};
      }

      return {
        "success": true,
        "access": access,
        "refresh": refresh, // 없을 수도 있음
      };
    } on DioException catch (e) {
      // DRF 표준 에러 메시지 혹은 커스텀 메시지 안전 추출
      final msg =
          e.response?.data is Map && (e.response?.data["detail"] != null)
          ? e.response?.data["detail"].toString()
          : (e.response?.data?.toString() ?? "로그인 실패");
      return {"success": false, "message": msg};
    } catch (_) {
      return {"success": false, "message": "네트워크/파싱 에러"};
    }
  }
}
