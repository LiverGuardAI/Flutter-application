import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/healthcare_service.dart';
import '../services/geocoding_service.dart';
import '../models/healthcare_model.dart';
import '../themes/fitness_app/fitness_app_theme.dart';

class HospitalMapPage extends StatefulWidget {
  const HospitalMapPage({super.key});

  @override
  State<HospitalMapPage> createState() => _HospitalMapPageState();
}

class _HospitalMapPageState extends State<HospitalMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // 서울 시청 좌표
  final LatLng _center = const LatLng(37.5663, 126.9779);

  List<Hospital> _hospitals = [];
  List<Clinic> _clinics = [];
  List<Pharmacy> _pharmacies = [];

  bool _isLoading = false;
  String _selectedType = 'hospital'; // 기본값: 병원
  String? _selectedDepartment;
  List<Department> _departments = [];
  double _radius = 1.0; // 기본 반경: 1km

  // 마커 캐시
  List<Marker> _cachedMarkers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 반경을 위경도로 변환 (현재 지도 중심 기준)
  // 위도 1도 ≈ 111km, 경도 1도 ≈ 88km (서울 기준)
  Map<String, double> _getBoundsFromRadius() {
    final latDelta = _radius / 111.0; // km를 위도로 변환
    final lngDelta = _radius / 88.0; // km를 경도로 변환

    // MapController가 초기화되지 않은 경우 기본 중심 좌표 사용
    LatLng currentCenter;
    try {
      currentCenter = _mapController.camera.center;
    } catch (e) {
      currentCenter = _center; // 서울 시청 좌표
    }

    return {
      'minX': currentCenter.longitude - lngDelta,
      'maxX': currentCenter.longitude + lngDelta,
      'minY': currentCenter.latitude - latDelta,
      'maxY': currentCenter.latitude + latDelta,
    };
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final bounds = _getBoundsFromRadius();
      final result = await HealthcareService.searchHealthcare(
        type: _selectedType,
        minX: bounds['minX'],
        maxX: bounds['maxX'],
        minY: bounds['minY'],
        maxY: bounds['maxY'],
      );

      if (!mounted) return;

      setState(() {
        _hospitals = result.hospitals;
        _clinics = result.clinics;
        _pharmacies = result.pharmacies;
        _updateMarkerCache();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 초기 데이터 로드 실패: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await HealthcareService.fetchDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      print('❌ 진료과목 로드 실패: $e');
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    final searchText = _searchController.text.trim();

    try {
      // 검색어가 있으면 먼저 장소 검색 시도 (Nominatim)
      if (searchText.isNotEmpty) {
        final placeCoords = await GeocodingService.searchPlace(searchText);

        if (placeCoords != null) {
          // 장소를 찾았으면 지도 중심을 해당 위치로 이동
          _mapController.move(placeCoords, 14.0);

          // 0.1초 대기 후 해당 위치 반경 내 병원/의원/약국 검색
          await Future.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 "$searchText" 위치로 이동했습니다'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      final bounds = _getBoundsFromRadius();

      // 병원/의원/약국 검색 (장소명이 아닌 시설명으로 검색)
      final result = await HealthcareService.searchHealthcare(
        query: searchText, // 시설명 검색
        type: _selectedType,
        departmentCode: _selectedDepartment,
        minX: bounds['minX'],
        maxX: bounds['maxX'],
        minY: bounds['minY'],
        maxY: bounds['maxY'],
      );

      if (!mounted) return;

      setState(() {
        _hospitals = result.hospitals;
        _clinics = result.clinics;
        _pharmacies = result.pharmacies;
        _updateMarkerCache();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 검색 실패: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 실패: $e')),
      );
    }
  }

  // 마커 캐시 업데이트
  void _updateMarkerCache() {
    _cachedMarkers = [];

    if (_selectedType == 'hospital') {
      for (var hospital in _hospitals) {
        if (hospital.coordinateX != null && hospital.coordinateY != null) {
          _cachedMarkers.add(
            Marker(
              point: LatLng(hospital.coordinateY!, hospital.coordinateX!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showDetailDialog(
                  '병원',
                  hospital.name,
                  hospital.address,
                  hospital.phone,
                  hospital.departments,
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ),
          );
        }
      }
    }

    if (_selectedType == 'clinic') {
      for (var clinic in _clinics) {
        if (clinic.coordinateX != null && clinic.coordinateY != null) {
          _cachedMarkers.add(
            Marker(
              point: LatLng(clinic.coordinateY!, clinic.coordinateX!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showDetailDialog(
                  '의원',
                  clinic.name,
                  clinic.address,
                  clinic.phone,
                  clinic.departments,
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ),
          );
        }
      }
    }

    if (_selectedType == 'pharmacy') {
      for (var pharmacy in _pharmacies) {
        if (pharmacy.coordinateX != null && pharmacy.coordinateY != null) {
          _cachedMarkers.add(
            Marker(
              point: LatLng(pharmacy.coordinateY!, pharmacy.coordinateX!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showDetailDialog(
                  '약국',
                  pharmacy.name,
                  pharmacy.address,
                  pharmacy.phone,
                  null,
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.green,
                  size: 30,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  List<Marker> _buildMarkers() {
    return _cachedMarkers;
  }

  void _showDetailDialog(
    String type,
    String name,
    String address,
    String? phone,
    List<Department>? departments,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type 정보', style: FitnessAppTheme.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: FitnessAppTheme.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(address, style: FitnessAppTheme.body2)),
                ],
              ),
              if (phone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(phone, style: FitnessAppTheme.body2),
                  ],
                ),
              ],
              if (departments != null && departments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('진료과목', style: FitnessAppTheme.caption),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: departments
                      .map(
                        (d) => Chip(
                          label: Text(
                            d.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dashboard_app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: _buildSearchBar(),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(bottom: 20, right: 10, child: _buildControlButtons()),
          Positioned(bottom: 20, left: 10, child: _buildLegend()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '장소 또는 병원명 검색 (예: 서울시청)',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('병원'),
                  selected: _selectedType == 'hospital',
                  onSelected: (selected) {
                    if (!selected || _selectedType == 'hospital') return;
                    setState(() => _selectedType = 'hospital');
                    _performSearch();
                  },
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('의원'),
                  selected: _selectedType == 'clinic',
                  onSelected: (selected) {
                    if (!selected || _selectedType == 'clinic') return;
                    setState(() => _selectedType = 'clinic');
                    _performSearch();
                  },
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('약국'),
                  selected: _selectedType == 'pharmacy',
                  onSelected: (selected) {
                    if (!selected || _selectedType == 'pharmacy') return;
                    setState(() => _selectedType = 'pharmacy');
                    _performSearch();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('반경: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${_radius.toInt()}km',
                    onChanged: (value) {
                      setState(() => _radius = value);
                    },
                    onChangeEnd: (value) => _performSearch(),
                  ),
                ),
                Text('${_radius.toInt()}km', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'zoom_in',
          mini: true,
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, currentZoom + 1);
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'zoom_out',
          mini: true,
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, currentZoom - 1);
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'my_location',
          mini: true,
          onPressed: () => _mapController.move(_center, 13.0),
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'refresh',
          mini: true,
          onPressed: _performSearch,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  '병원 (${_hospitals.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  '의원 (${_clinics.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  '약국 (${_pharmacies.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진료과목 필터'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('전체'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedDepartment,
                  onChanged: (value) {
                    if (_selectedDepartment == value) return;
                    setState(() => _selectedDepartment = value);
                    Navigator.pop(context);
                    _performSearch();
                  },
                ),
              ),
              ..._departments.map(
                (dept) => ListTile(
                  title: Text(dept.name),
                  leading: Radio<String?>(
                    value: dept.code,
                    groupValue: _selectedDepartment,
                    onChanged: (value) {
                      if (_selectedDepartment == value) return;
                      setState(() => _selectedDepartment = value);
                      Navigator.pop(context);
                      _performSearch();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
