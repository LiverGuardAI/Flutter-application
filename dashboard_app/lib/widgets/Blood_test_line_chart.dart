import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 🎨 멋진 혈액 검사 시계열 그래프 (GitHub 샘플 스타일)
class StylishBloodTestChart extends StatelessWidget {
  final List<DateTime> dates;
  final Map<String, List<double>> dataLines;
  final String title;
  final Map<String, Color> lineColors;
  final double? normalMin;
  final double? normalMax;
  final bool isAlbiGrade; // 👈 ALBI Grade 여부

  const StylishBloodTestChart({
    Key? key,
    required this.dates,
    required this.dataLines,
    required this.title,
    required this.lineColors,
    this.normalMin,
    this.normalMax,
    this.isAlbiGrade = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty || dataLines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('데이터가 없습니다', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 범례
          _buildLegend(),
          const SizedBox(height: 16),

          // 그래프
          SizedBox(
            height: 250,
            child: LineChart(
              _createLineChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  // 범례 생성
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: dataLines.entries.map((entry) {
        final label = entry.key;
        final color = lineColors[label] ?? Colors.blue;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  LineChartData _createLineChartData() {
    final allValues = dataLines.values.expand((list) => list).toList();
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxValue - minValue) / 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1);
        },
      ),

      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= dates.length) return const Text('');

              // 🔧 월.일 형식으로 표시
              if (index % (dates.length > 5 ? 2 : 1) == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM.dd').format(dates[index]), // 👈 변경
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxValue - minValue) / 5,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              );
            },
          ),
        ),
      ),

      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),

      minX: 0,
      maxX: (dates.length - 1).toDouble(),
      minY: (minValue - padding).clamp(0, double.infinity),
      maxY: maxValue + padding,

      extraLinesData: ExtraLinesData(horizontalLines: _buildNormalRangeLines()),

      lineBarsData: _buildLineBarsData(),

      // 🔧 툴팁 개선
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => const Color(0xFF37474F),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final date = dates[spot.x.toInt()];
              final lineName = dataLines.keys.elementAt(spot.barIndex);
              final value = spot.y;

              // 🎯 ALBI Grade는 "Grade 1" 형식으로 표시
              String valueText;
              if (isAlbiGrade && lineName == 'ALBI Grade') {
                final gradeNum = value.round();
                valueText = 'Grade $gradeNum';
              } else {
                valueText = value.toStringAsFixed(1);
              }

              return LineTooltipItem(
                '$lineName\n${DateFormat('yyyy-MM-dd').format(date)}\n$valueText',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    return dataLines.entries.map((entry) {
      final label = entry.key;
      final values = entry.value;
      final color = lineColors[label] ?? Colors.blue;

      final spots = <FlSpot>[];
      for (int i = 0; i < values.length; i++) {
        spots.add(FlSpot(i.toDouble(), values[i]));
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        shadow: Shadow(
          color: color.withOpacity(0.4),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      );
    }).toList();
  }

  List<HorizontalLine> _buildNormalRangeLines() {
    final lines = <HorizontalLine>[];

    if (normalMin != null) {
      lines.add(
        HorizontalLine(
          y: normalMin!,
          color: Colors.green.withOpacity(0.5),
          strokeWidth: 2,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            style: TextStyle(
              color: Colors.green[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            labelResolver: (line) => 'Min',
          ),
        ),
      );
    }

    if (normalMax != null) {
      lines.add(
        HorizontalLine(
          y: normalMax!,
          color: Colors.green.withOpacity(0.5),
          strokeWidth: 2,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            style: TextStyle(
              color: Colors.green[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            labelResolver: (line) => 'Max',
          ),
        ),
      );
    }

    return lines;
  }
}
