import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/healthcare_service.dart';
import '../services/geocoding_service.dart';
import '../services/api_service.dart';
import '../models/healthcare_model.dart';
import '../models/favorite_model.dart';
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
  LatLng? _searchLocation;

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
  List<FavoritePlace> _favorites = [];
  String _favoriteTypeFilter = 'all';
  String _favoriteSearchQuery = '';
  bool _favoritesLoading = false;

  @override
  void initState() {
    super.initState();
    _searchLocation = _center;
    _loadInitialData();
    _loadDepartments();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 반경을 위경도로 변환 (현재 검색 중심 기준)
  // 위도 1도 ≈ 111km, 경도 1도 ≈ 88km (서울 기준)
  Map<String, double> _getBoundsFromRadius() {
    final latDelta = _radius / 111.0; // km를 위도로 변환
    final lngDelta = _radius / 88.0; // km를 경도로 변환

    // 검색 위치가 있으면 우선 사용, 없으면 지도 중심
    LatLng currentCenter = _searchLocation ?? _center;
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
      final center = _searchLocation ?? _center;
      final result = await HealthcareService.searchHealthcare(
        type: _selectedType,
        minX: bounds['minX'],
        maxX: bounds['maxX'],
        minY: bounds['minY'],
        maxY: bounds['maxY'],
        centerX: center.longitude,
        centerY: center.latitude,
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
    LatLng? mapCenter;
    try {
      mapCenter = _mapController.camera.center;
    } catch (e) {
      mapCenter = null;
    }

    bool usedLocationSearch = false;

    try {
      // 검색어가 있으면 먼저 장소 검색 시도 (Nominatim)
      if (searchText.isNotEmpty) {
        final placeCoords = await GeocodingService.searchPlace(searchText);

        if (placeCoords != null) {
          // 장소를 찾았으면 지도 중심을 해당 위치로 이동
          _mapController.move(placeCoords, 14.0);
          _searchLocation = placeCoords;

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
        usedLocationSearch = true;
      } else {
        _searchLocation = _center;
      }

      final bounds = _getBoundsFromRadius();
      final center = _searchLocation ?? _center;

      // 병원/의원/약국 검색 (장소명이 아닌 시설명으로 검색)
      final result = await HealthcareService.searchHealthcare(
        query: usedLocationSearch ? null : searchText, // 장소 검색을 사용했다면 시설명 필터 제거
        type: _selectedType,
        departmentCode: _selectedDepartment,
        minX: bounds['minX'],
        maxX: bounds['maxX'],
        minY: bounds['minY'],
        maxY: bounds['maxY'],
        centerX: center.longitude,
        centerY: center.latitude,
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
                  hospital.id,
                  hospital.name,
                  hospital.address,
                  hospital.phone,
                  hospital.departments,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 32,
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
                  clinic.id,
                  clinic.name,
                  clinic.address,
                  clinic.phone,
                  clinic.departments,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 32,
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
                  pharmacy.id,
                  pharmacy.name,
                  pharmacy.address,
                  pharmacy.phone,
                  null,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 32,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    final token = await ApiService.getToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _favoritesLoading = false;
        _favorites = [];
      });
      return;
    }

    setState(() => _favoritesLoading = true);
    try {
      final favorites = await HealthcareService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _favoritesLoading = false;
      });
    } catch (e) {
      print('❌ Favorites load error: $e');
      if (!mounted) return;
      setState(() => _favoritesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 불러오기 실패: $e')),
      );
    }
  }

  Future<bool> _ensureLoggedIn() async {
    final token = await ApiService.getToken();
    if (token == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용해주세요')),
      );
      return false;
    }
    return true;
  }

  FavoritePlace? _findFavorite(String type, int facilityId) {
    try {
      return _favorites.firstWhere(
        (fav) => fav.type == type && fav.facilityId == facilityId,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isFavorite(String type, int facilityId) {
    return _findFavorite(type, facilityId) != null;
  }

  Future<void> _addFavorite({
    required String type,
    required int facilityId,
  }) async {
    if (!await _ensureLoggedIn()) return;

    try {
      final newFavorite = await HealthcareService.addFavoritePlace(
        type: type,
        facilityId: facilityId,
      );
      if (!mounted) return;
      setState(() {
        _favorites.add(newFavorite);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기에 추가되었습니다')),
      );
    } catch (e) {
      print('❌ Favorite add error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 추가 실패: $e')),
      );
    }
  }

  Future<void> _removeFavorite(FavoritePlace item) async {
    if (!await _ensureLoggedIn()) return;

    try {
      await HealthcareService.removeFavoritePlace(
        type: item.type,
        favoriteId: item.favoriteId,
      );
      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((fav) => fav.favoriteId == item.favoriteId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기가 해제되었습니다')),
      );
    } catch (e) {
      print('❌ Favorite remove error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 해제 실패: $e')),
      );
    }
  }

  Future<void> _showFavoritesModal() async {
    await _loadFavorites();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            void refreshModal(VoidCallback fn) {
              setState(fn);
              modalSetState(() {});
            }

            final filtered = _favorites.where((fav) {
              final matchesType = _favoriteTypeFilter == 'all' || fav.type == _favoriteTypeFilter;
              final query = _favoriteSearchQuery.trim().toLowerCase();
              final matchesQuery = query.isEmpty ||
                  fav.name.toLowerCase().contains(query) ||
                  fav.address.toLowerCase().contains(query);
              return matchesType && matchesQuery;
            }).toList();

            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      '즐겨찾기 리스트',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('전체'),
                            selected: _favoriteTypeFilter == 'all',
                            onSelected: (selected) {
                              if (!selected) return;
                              refreshModal(() => _favoriteTypeFilter = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('병원'),
                            selected: _favoriteTypeFilter == 'hospital',
                            onSelected: (selected) {
                              if (!selected) return;
                              refreshModal(() => _favoriteTypeFilter = 'hospital');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('의원'),
                            selected: _favoriteTypeFilter == 'clinic',
                            onSelected: (selected) {
                              if (!selected) return;
                              refreshModal(() => _favoriteTypeFilter = 'clinic');
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: '즐겨찾기 검색',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          refreshModal(() => _favoriteSearchQuery = value);
                        },
                      ),
                    ),
                    if (_favoritesLoading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      )
                    else if (_favorites.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text('등록된 즐겨찾기가 없습니다.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: filtered.isEmpty
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('조건에 맞는 즐겨찾기가 없습니다.'),
                              ))
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color: item.type == 'hospital'
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                    title: Text(item.name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.address),
                                        if (item.phone != null && item.phone!.isNotEmpty)
                                          Text(item.phone!),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.star, color: Colors.amber),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('즐겨찾기 해제'),
                                            content: const Text('즐겨찾기를 해제하시겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('아니오'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('예'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _removeFavorite(item);
                                          modalSetState(() {});
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    final markers = List<Marker>.from(_cachedMarkers);

    if (_searchLocation != null) {
      markers.add(
        Marker(
          point: _searchLocation!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.black87,
            size: 32,
          ),
        ),
      );
    }

    return markers;
  }

  void _showDetailDialog(
    String type,
    int facilityId,
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
          Row(
            children: [
              if (type != '약국')
                TextButton.icon(
                  icon: Icon(
                    _isFavorite(
                      type == '병원' ? 'hospital' : 'clinic',
                      facilityId,
                    )
                        ? Icons.star
                        : Icons.star_border,
                  ),
                  label: const Text('즐겨찾기'),
                  onPressed: () async {
                    final favType = type == '병원' ? 'hospital' : 'clinic';
                    final isFav = _isFavorite(favType, facilityId);
                    if (isFav) {
                      final fav = _findFavorite(favType, facilityId);
                      if (fav != null) {
                        await _removeFavorite(fav);
                      }
                    } else {
                      await _addFavorite(
                        type: favType,
                        facilityId: facilityId,
                      );
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
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
                    decoration: InputDecoration(
                      hintText: '장소 또는 병원명 검색 (예: 서울시청)',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _performSearch,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
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
          heroTag: 'favorite',
          mini: true,
          onPressed: () {
            _showFavoritesModal();
          },
          child: const Icon(Icons.star),
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
    Icon legendIcon;
    String legendText;

    switch (_selectedType) {
      case 'clinic':
        legendIcon = const Icon(Icons.local_hospital, color: Colors.blue, size: 18);
        legendText = '의원 (${_clinics.length})';
        break;
      case 'pharmacy':
        legendIcon = const Icon(Icons.medication, color: Colors.green, size: 18);
        legendText = '약국 (${_pharmacies.length})';
        break;
      case 'hospital':
      default:
        legendIcon = const Icon(Icons.local_hospital, color: Colors.red, size: 18);
        legendText = '병원 (${_hospitals.length})';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            legendIcon,
            const SizedBox(width: 6),
            Text(
              legendText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
