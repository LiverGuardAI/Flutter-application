import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HospitalMapPage extends StatefulWidget {
  const HospitalMapPage({super.key});

  @override
  State<HospitalMapPage> createState() => _HospitalMapPageState();
}

class _HospitalMapPageState extends State<HospitalMapPage> {
  final MapController _mapController = MapController();

  // 서울 중심 좌표 (기본값)
  final LatLng _center = const LatLng(37.5665, 126.9780);

  // 병원 마커 예시 데이터
  final List<Marker> _hospitalMarkers = [
    Marker(
      point: const LatLng(37.5665, 126.9780),
      width: 80,
      height: 80,
      child: const Icon(Icons.local_hospital, color: Colors.red, size: 40),
    ),
    Marker(
      point: const LatLng(37.5700, 126.9850),
      width: 80,
      height: 80,
      child: const Icon(Icons.local_hospital, color: Colors.red, size: 40),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('병원 지도'), backgroundColor: Colors.blue),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13.0,
          minZoom: 5.0,
          maxZoom: 18.0,
        ),
        children: [
          // OpenStreetMap 타일 레이어 (Leaflet 기본 스타일)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.dashboard_app',
            maxZoom: 19,
          ),
          // 병원 마커 레이어
          MarkerLayer(markers: _hospitalMarkers),
        ],
      ),
      // 지도 컨트롤 버튼
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'my_location',
            mini: true,
            onPressed: () {
              _mapController.move(_center, 13.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
