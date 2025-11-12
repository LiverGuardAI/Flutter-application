// 🔥 혈액검사 결과 모델
class DashboardGraphs {
  final String patientName;
  final String testDate;
  final String gender;
  final PrimaryGraphs primary;
  final SecondaryGraphs secondary;
  final GraphSummary summary;

  DashboardGraphs({
    required this.patientName,
    required this.testDate,
    required this.gender,
    required this.primary,
    required this.secondary,
    required this.summary,
  });

  factory DashboardGraphs.fromJson(Map<String, dynamic> json) {
    return DashboardGraphs(
      patientName: json['patient_name'] ?? '',
      testDate: json['test_date'] ?? '',
      gender: json['gender'] ?? 'male',
      primary: PrimaryGraphs.fromJson(json['graphs']['primary'] ?? {}),
      secondary: SecondaryGraphs.fromJson(json['graphs']['secondary'] ?? {}),
      summary: GraphSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

// 핵심 지표
class PrimaryGraphs {
  final String? afp;
  final String? ast;
  final String? alt;
  final String? albiGrade;

  PrimaryGraphs({this.afp, this.ast, this.alt, this.albiGrade});

  factory PrimaryGraphs.fromJson(Map<String, dynamic> json) {
    return PrimaryGraphs(
      afp: json['afp'],
      ast: json['ast'],
      alt: json['alt'],
      albiGrade: json['albi_grade'],
    );
  }
}

// 부가 지표
class SecondaryGraphs {
  final String? ggt;
  final String? rGtp;
  final String? bilirubin;
  final String? albumin;

  SecondaryGraphs({this.ggt, this.rGtp, this.bilirubin, this.albumin});

  factory SecondaryGraphs.fromJson(Map<String, dynamic> json) {
    return SecondaryGraphs(
      ggt: json['ggt'],
      rGtp: json['r_gtp'],
      bilirubin: json['bilirubin'],
      albumin: json['albumin'],
    );
  }
}

// 요약 정보
class GraphSummary {
  final TestValue? afp;
  final TestValue? ast;
  final TestValue? alt;

  GraphSummary({this.afp, this.ast, this.alt});

  factory GraphSummary.fromJson(Map<String, dynamic> json) {
    return GraphSummary(
      afp: json['afp'] != null ? TestValue.fromJson(json['afp']) : null,
      ast: json['ast'] != null ? TestValue.fromJson(json['ast']) : null,
      alt: json['alt'] != null ? TestValue.fromJson(json['alt']) : null,
    );
  }
}

class TestValue {
  final double? value;
  final String? status;
  final String? importance;

  TestValue({this.value, this.status, this.importance});

  factory TestValue.fromJson(Map<String, dynamic> json) {
    return TestValue(
      value: json['value']?.toDouble(),
      status: json['status'],
      importance: json['importance'],
    );
  }
}
