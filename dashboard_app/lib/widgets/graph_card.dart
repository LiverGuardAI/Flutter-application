import 'package:flutter/material.dart';
import 'dart:convert';

class GraphCard extends StatelessWidget {
  final String title;
  final String? imageBase64;
  final String? importance;
  final String? status;

  const GraphCard({
    Key? key,
    required this.title,
    this.imageBase64,
    this.importance,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageBase64 == null) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: importance == 'critical'
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 + 중요도 아이콘
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (importance == 'critical')
                  Icon(Icons.warning, color: Colors.red, size: 24),
              ],
            ),
            SizedBox(height: 12),

            // 그래프 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(imageBase64!.split(',')[1]),
                fit: BoxFit.contain,
              ),
            ),

            // 상태 칩
            if (status != null) ...[
              SizedBox(height: 12),
              _buildStatusChip(status!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'safe':
        color = Colors.green;
        text = '안정';
        break;
      case 'warning':
        color = Colors.orange;
        text = '경계';
        break;
      case 'danger':
        color = Colors.red;
        text = '위험';
        break;
      case 'critical':
        color = Colors.red[900]!;
        text = '매우 위험';
        break;
      default:
        color = Colors.grey;
        text = '알 수 없음';
    }

    return Chip(
      label: Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
