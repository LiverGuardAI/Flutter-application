class FavoritePlace {
  final int favoriteId;
  final String type; // 'hospital' or 'clinic'
  final int facilityId;
  final String name;
  final String address;
  final String? phone;
  final DateTime? createdAt;

  FavoritePlace({
    required this.favoriteId,
    required this.type,
    required this.facilityId,
    required this.name,
    required this.address,
    this.phone,
    this.createdAt,
  });

  factory FavoritePlace.fromHospitalJson(Map<String, dynamic> json) {
    final hospital = json['hospital'] as Map<String, dynamic>? ?? {};
    return FavoritePlace(
      favoriteId: json['favorite_id'],
      type: 'hospital',
      facilityId: hospital['id'],
      name: hospital['name'] ?? '',
      address: hospital['address'] ?? '',
      phone: hospital['phone'],
      createdAt: _parseDate(json['created_at']),
    );
  }

  factory FavoritePlace.fromClinicJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] as Map<String, dynamic>? ?? {};
    return FavoritePlace(
      favoriteId: json['favorite_id'],
      type: 'clinic',
      facilityId: clinic['id'],
      name: clinic['name'] ?? '',
      address: clinic['address'] ?? '',
      phone: clinic['phone'],
      createdAt: _parseDate(json['created_at']),
    );
  }

  FavoritePlace copyWith({
    int? favoriteId,
    String? type,
    int? facilityId,
    String? name,
    String? address,
    String? phone,
    DateTime? createdAt,
  }) {
    return FavoritePlace(
      favoriteId: favoriteId ?? this.favoriteId,
      type: type ?? this.type,
      facilityId: facilityId ?? this.facilityId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
