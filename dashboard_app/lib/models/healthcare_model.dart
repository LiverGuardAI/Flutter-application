class Department {
  final int id;
  final String code;
  final String name;

  Department({required this.id, required this.code, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'], code: json['code'], name: json['name']);
  }
}

class Hospital {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final String? businessType;
  final double? coordinateX;
  final double? coordinateY;
  final List<Department>? departments;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.businessType,
    this.coordinateX,
    this.coordinateY,
    this.departments,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      businessType: json['business_type'],
      coordinateX: _toDouble(json['coordinate_x']),
      coordinateY: _toDouble(json['coordinate_y']),
      departments: json['departments'] != null
          ? (json['departments'] as List)
                .map((d) => Department.fromJson(d))
                .toList()
          : null,
    );
  }
}

class Clinic {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final String? businessType;
  final double? coordinateX;
  final double? coordinateY;
  final List<Department>? departments;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.businessType,
    this.coordinateX,
    this.coordinateY,
    this.departments,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      businessType: json['business_type'],
      coordinateX: _toDouble(json['coordinate_x']),
      coordinateY: _toDouble(json['coordinate_y']),
      departments: json['departments'] != null
          ? (json['departments'] as List)
                .map((d) => Department.fromJson(d))
                .toList()
          : null,
    );
  }
}

class Pharmacy {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final double? coordinateX;
  final double? coordinateY;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.coordinateX,
    this.coordinateY,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      coordinateX: _toDouble(json['coordinate_x']),
      coordinateY: _toDouble(json['coordinate_y']),
    );
  }
}

class HealthcareSearchResult {
  final List<Hospital> hospitals;
  final List<Clinic> clinics;
  final List<Pharmacy> pharmacies;

  HealthcareSearchResult({
    required this.hospitals,
    required this.clinics,
    required this.pharmacies,
  });

  factory HealthcareSearchResult.fromJson(Map<String, dynamic> json) {
    return HealthcareSearchResult(
      hospitals: (json['hospitals'] as List? ?? [])
          .map((h) => Hospital.fromJson(h))
          .toList(),
      clinics: (json['clinics'] as List? ?? [])
          .map((c) => Clinic.fromJson(c))
          .toList(),
      pharmacies: (json['pharmacies'] as List? ?? [])
          .map((p) => Pharmacy.fromJson(p))
          .toList(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
