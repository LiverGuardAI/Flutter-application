import 'package:dio/dio.dart';
import '../utils/secure_storage.dart'; // ✅ utils로 대체

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000/api/dashboard", // Django API 주소
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  // ✅ 앱 시작 시 interceptor 초기화
  static Future<void> initialize() async {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ✅ utils SecureStorage 사용
          final accessToken = await SecureStorage.read("access");

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $accessToken";
          }

          return handler.next(options);
        },

        onError: (DioException error, handler) async {
          // ✅ Access Token 만료 시 자동 Refresh
          if (error.response?.statusCode == 401) {
            final refreshToken = await SecureStorage.read("refresh");

            if (refreshToken != null) {
              try {
                final refreshResponse = await dio.post(
                  "/token/refresh/",
                  data: {"refresh": refreshToken},
                );

                final newAccess = refreshResponse.data["access"];

                // ✅ 새 Access Token 저장
                await SecureStorage.save("access", newAccess);

                // ✅ 실패했던 요청 header 수정
                error.requestOptions.headers["Authorization"] =
                    "Bearer $newAccess";

                // ✅ 실패한 요청을 다시 실행
                final cloned = await dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );

                return handler.resolve(cloned);
              } catch (_) {
                // ✅ Refresh도 실패 → 로그아웃 처리
                await SecureStorage.deleteAll();
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}
