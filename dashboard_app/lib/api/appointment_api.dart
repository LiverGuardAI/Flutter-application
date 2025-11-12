// 병원 일정 관리 API
import 'package:dio/dio.dart';
import '../models/appointment.dart';
import 'dio_client.dart';
import '../utils/secure_storage.dart';

class AppointmentApi {
  static Future<List<Appointment>> getAppointments() async {
    // 전체 일정 조회
    try {
      final dio = DioClient.dio; // DioClient의 dio 인스턴스 가져오기
      final response = await dio.get('/appointments/');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAppointment(
    // 일정 추가
    Appointment appointment,
  ) async {
    try {
      final dio = DioClient.dio;

      // 로그인한 사용자의 user_id를 patient_id로 사용
      final userId = await SecureStorage.read('user_id');
      print('DEBUG: userId = $userId');

      final appointmentData = appointment.toJson();
      appointmentData['patient_id'] = userId;

      print('DEBUG: appointmentData = $appointmentData');

      final response = await dio.post('/appointments/', data: appointmentData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': '일정이 추가되었습니다.',
          'data': Appointment.fromJson(response.data),
        };
      } else {
        return {'success': false, 'message': '일정 추가에 실패했습니다.'};
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Error message: ${e.message}');

      final errorMsg = e.response?.data?.toString() ?? '서버 오류가 발생했습니다.';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      print('Error creating appointment: $e');
      return {'success': false, 'message': '서버 오류가 발생했습니다: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAppointment(
    // 일정 수정
    int appointmentId,
    Appointment appointment,
  ) async {
    try {
      final dio = DioClient.dio;
      final response = await dio.put(
        '/appointments/$appointmentId/',
        data: appointment.toJson(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '일정이 수정되었습니다.',
          'data': Appointment.fromJson(response.data),
        };
      } else {
        return {'success': false, 'message': '일정 수정에 실패했습니다.'};
      }
    } catch (e) {
      print('Error updating appointment: $e');
      return {'success': false, 'message': '서버 오류가 발생했습니다.'};
    }
  }

  static Future<Map<String, dynamic>> deleteAppointment(
    // 일정 삭제
    int appointmentId,
  ) async {
    try {
      final dio = DioClient.dio;
      final response = await dio.delete('/appointments/$appointmentId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true, 'message': '일정이 삭제되었습니다.'};
      } else {
        return {'success': false, 'message': '일정 삭제에 실패했습니다.'};
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      return {'success': false, 'message': '서버 오류가 발생했습니다.'};
    }
  }

  static Future<List<Appointment>> getAppointmentsByDateRange(
    // 날짜 범위별 조회
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dio = DioClient.dio;
      final response = await dio.get(
        '/appointments/',
        queryParameters: {
          'start_date':
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'end_date':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      print('Error fetching appointments by date range: $e');
      return [];
    }
  }
}
