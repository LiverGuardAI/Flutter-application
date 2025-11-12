// lib/api/auth_api.dart
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../utils/secure_storage.dart';

class AuthApi {
  /// ✅ 로그인 API
  /// - 서버에 로그인 요청
  /// - 성공 시 토큰 저장까지 처리
  static Future<Map<String, dynamic>> login(String id, String password) async {
    final dio = DioClient.dio;

    try {
      final response = await dio.post(
        "/auth/login/",
        data: {"user_id": id.trim(), "password": password.trim()},
      );

      final access = response.data["access"];
      final refresh = response.data["refresh"];

      // ✅ access token 필수 체크
      if (access == null || access.isEmpty) {
        return {
          "success": false,
          "message": "서버에서 올바른 access token이 전달되지 않았습니다.",
        };
      }

      // ✅ refresh token 필수 체크 (네 서비스 구조에서는 반드시 필요)
      if (refresh == null || refresh.isEmpty) {
        return {"success": false, "message": "서버에서 refresh token이 전달되지 않았습니다."};
      }

      // ✅ 토큰 저장
      await SecureStorage.save("access", access);
      await SecureStorage.save("refresh", refresh);
      await SecureStorage.save("user_id", id.trim());

      return {"success": true};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data.toString() ?? "로그인 실패",
      };
    }
  }

  /// ✅ 로그아웃 API
  /// - refresh token 서버로 전달
  /// - 토큰 삭제는 UI(ProfilePage 등)에서 처리
  static Future<bool> logout() async {
    final dio = DioClient.dio;

    // ✅ 로컬 refresh token 읽기
    final refresh = await SecureStorage.read("refresh");
    if (refresh == null) return false;

    try {
      await dio.post("/auth/logout/", data: {"refresh": refresh});
      return true;
    } catch (_) {
      return false;
    }
  }
}
