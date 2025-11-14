import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // Nominatim API - OpenStreetMap의 무료 geocoding 서비스
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  /// 장소명을 좌표로 변환 (geocoding)
  ///
  /// [query]: 검색할 장소명 (예: "서울시청", "강남역", "서울 종로구")
  /// [countryCode]: 국가 코드 (기본값: 'kr' - 한국)
  ///
  /// Returns: 좌표(LatLng) 또는 null (검색 결과 없음)
  static Future<LatLng?> searchPlace(String query, {String countryCode = 'kr'}) async {
    if (query.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$_nominatimUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'countrycodes': countryCode,
          'limit': '1',
          'addressdetails': '1',
        },
      );

      print('🌍 Geocoding: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'LiverGuard Healthcare Map App/1.0', // Nominatim 요구사항
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        if (results.isEmpty) {
          print('⚠️ 검색 결과 없음: $query');
          return null;
        }

        final first = results[0];
        final lat = double.parse(first['lat']);
        final lon = double.parse(first['lon']);

        print('✅ 좌표 변환 성공: $query -> ($lat, $lon)');
        return LatLng(lat, lon);
      } else {
        print('❌ Geocoding API 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Geocoding 실패: $e');
      return null;
    }
  }

  /// 여러 장소 검색 결과 반환 (자동완성용)
  ///
  /// [query]: 검색할 장소명
  /// [limit]: 최대 결과 개수 (기본값: 5)
  ///
  /// Returns: 검색 결과 목록
  static Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    String countryCode = 'kr',
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_nominatimUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'countrycodes': countryCode,
          'limit': limit.toString(),
          'addressdetails': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'LiverGuard Healthcare Map App/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results
            .map((json) => PlaceSearchResult.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Places search 실패: $e');
      return [];
    }
  }
}

/// 장소 검색 결과 모델
class PlaceSearchResult {
  final String displayName;
  final LatLng coordinates;
  final String? type;

  PlaceSearchResult({
    required this.displayName,
    required this.coordinates,
    this.type,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      displayName: json['display_name'],
      coordinates: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      type: json['type'],
    );
  }
}
