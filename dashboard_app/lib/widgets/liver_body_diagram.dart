import 'package:flutter/material.dart';

class LiverBodyDiagram extends StatelessWidget {
  final Map<String, dynamic>? latestTest;
  final String gender;

  const LiverBodyDiagram({
    Key? key,
    required this.latestTest,
    this.gender = 'male',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 간 건강 위험도 계산
    final liverStatus = _calculateLiverStatus();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.7,
            child: Stack(
              children: [
                // 인체 이미지
                Image.asset('assets/images/body.png', fit: BoxFit.contain),

                // 동적 간 위치 표시 (위험도에 따라 색상 변경)
                Positioned(
                  left: 65,
                  top: 80,
                  child: _buildLiverIndicator(liverStatus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 상태 텍스트
        ],
      ),
    );
  }

  // 간 위험도 계산
  Map<String, dynamic> _calculateLiverStatus() {
    if (latestTest == null) {
      return {
        'risk': 0.0,
        'color': Colors.grey,
        'status': '데이터 없음',
        'icon': Icons.help_outline,
      };
    }

    // 각 지표별 위험도 계산
    final afpRisk = _calculateAfpRisk(_parseDouble(latestTest!['afp']));
    final astAltRisk = _calculateAstAltRisk(
      _parseDouble(latestTest!['ast']),
      _parseDouble(latestTest!['alt']),
    );
    final albiRisk = _calculateAlbiRisk(
      _parseAlbiGrade(latestTest!['albi_grade']),
    );
    final ggtRisk = _calculateGgtRisk(_parseDouble(latestTest!['ggt']));

    // 평균 위험도
    final risks = [
      afpRisk,
      astAltRisk,
      albiRisk,
      ggtRisk,
    ].where((r) => r > 0).toList();

    final averageRisk = risks.isEmpty
        ? 0.0
        : risks.reduce((a, b) => a + b) / risks.length;

    // 색상 및 상태 결정
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (averageRisk <= 30) {
      statusColor = Colors.green;
      statusText = '정상';
      statusIcon = Icons.check_circle;
    } else if (averageRisk <= 60) {
      statusColor = Colors.orange;
      statusText = '주의';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = '위험';
      statusIcon = Icons.error;
    }

    return {
      'risk': averageRisk,
      'color': statusColor,
      'status': statusText,
      'icon': statusIcon,
    };
  }

  // 간 위치 표시 위젯 (애니메이션 포함)
  Widget _buildLiverIndicator(Map<String, dynamic> status) {
    final color = status['color'] as Color;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 20,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3 + (0.3 * value)), // 페이드 인
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8 * value, // 글로우 효과
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
    );
  }

  // === 위험도 계산 함수들 ===

  double _calculateAfpRisk(double? afp) {
    if (afp == null) return 0;
    if (afp <= 10) return 10;
    if (afp <= 20) return 25;
    if (afp <= 100) return 50;
    if (afp <= 200) return 75;
    return 95;
  }

  double _calculateAstAltRisk(double? ast, double? alt) {
    if (ast == null && alt == null) return 0;

    final threshold = gender == 'male' ? 40.0 : 35.0;
    final astVal = ast ?? 0;
    final altVal = alt ?? 0;
    final maxVal = astVal > altVal ? astVal : altVal;

    if (maxVal <= threshold) return 10;
    if (maxVal <= threshold + 10) return 30;
    if (maxVal <= threshold + 30) return 60;
    return 90;
  }

  double _calculateAlbiRisk(int? grade) {
    if (grade == null) return 0;
    if (grade == 1) return 10;
    if (grade == 2) return 40;
    return 80;
  }

  double _calculateGgtRisk(double? ggt) {
    if (ggt == null) return 0;
    final threshold = gender == 'male' ? 71.0 : 42.0;

    if (ggt <= threshold) return 10;
    if (ggt <= threshold + 30) return 35;
    if (ggt <= threshold + 60) return 70;
    return 95;
  }

  // === 헬퍼 함수들 ===

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseAlbiGrade(dynamic grade) {
    if (grade == null) return null;
    if (grade is num) return grade.toInt();
    if (grade is String) {
      final cleanGrade = grade.toLowerCase().replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanGrade);
    }
    return null;
  }
}
