import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LiverHealthStatusCard extends StatelessWidget {
  final Map<String, dynamic>? latestTest;
  final String gender;

  const LiverHealthStatusCard({
    Key? key,
    required this.latestTest,
    this.gender = 'male',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (latestTest == null) {
      return _buildEmptyCard();
    }

    final riskData = _calculateRiskScores();
    final overallRisk = _calculateOverallRisk(riskData);

    return Container(
      padding: const EdgeInsets.all(10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 원형 차트
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                sections: _buildPieChartSections(riskData),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 종합 상태
          _buildOverallStatus(overallRisk),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('검사 기록이 없습니다', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // 위험도 점수 계산 (0-100)
  Map<String, double> _calculateRiskScores() {
    final afp = _parseDouble(latestTest!['afp']);
    final ast = _parseDouble(latestTest!['ast']);
    final alt = _parseDouble(latestTest!['alt']);
    final ggt = _parseDouble(latestTest!['ggt']);
    final albiGrade = _parseAlbiGrade(latestTest!['albi_grade']);

    return {
      'AFP': _calculateAfpRisk(afp),
      'AST/ALT': _calculateAstAltRisk(ast, alt),
      'ALBI': _calculateAlbiRisk(albiGrade),
      'GGT': _calculateGgtRisk(ggt),
    };
  }

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

  double _calculateOverallRisk(Map<String, double> riskData) {
    final values = riskData.values.where((v) => v > 0).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> riskData,
  ) {
    final colors = {
      'AFP': const Color(0xFF2196F3),
      'AST/ALT': const Color(0xFF9C27B0),
      'ALBI': const Color(0xFFFF9800),
      'GGT': const Color(0xFF4CAF50),
    };

    return riskData.entries.map((entry) {
      final risk = entry.value;
      final color = colors[entry.key]!;

      return PieChartSectionData(
        value: risk > 0 ? risk : 25,
        title: '${entry.key}\n${risk.toInt()}%',
        color: color,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getRiskColor(double risk, Color baseColor) {
    if (risk <= 30) return Colors.green;
    if (risk <= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildOverallStatus(double overallRisk) {
    String status;
    Color statusColor;
    IconData icon;

    if (overallRisk <= 30) {
      status = '양호';
      statusColor = Colors.green;
      icon = Icons.check_circle;
    } else if (overallRisk <= 60) {
      status = '주의 필요';
      statusColor = Colors.orange;
      icon = Icons.warning;
    } else {
      status = '위험';
      statusColor = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            '종합 상태 : $status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

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
