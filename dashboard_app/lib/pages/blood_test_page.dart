import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';
import '../widgets/graph_card.dart';

class BloodTestPage extends StatefulWidget {
  final String? initialTab; // 🔥 이거!
  const BloodTestPage({Key? key, this.initialTab}) : super(key: key);

  @override
  _BloodTestPageState createState() => _BloodTestPageState();
}

class _BloodTestPageState extends State<BloodTestPage> {
  DashboardGraphs? graphs;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGraphs();
  }

  Future<void> _loadGraphs() async {
    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = '로그인이 필요합니다';
          isLoading = false;
        });
        return;
      }

      final data = await ApiService().fetchDashboardGraphs(token);

      setState(() {
        graphs = data;
        isLoading = false;
      });
    } catch (e) {
      print('BloodTest: Graph load error: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('혈액검사 결과'), backgroundColor: Colors.red[400]),
      body: RefreshIndicator(onRefresh: _loadGraphs, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('혈액검사 결과를 불러오는 중...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('오류가 발생했습니다'),
            Text(errorMessage!, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadGraphs, child: Text('다시 시도')),
          ],
        ),
      );
    }

    if (graphs == null) {
      return Center(child: Text('데이터를 찾을 수 없습니다'));
    }

    return ListView(
      children: [
        // 환자 정보
        _buildPatientInfo(),

        // 핵심 지표
        _buildPrimaryGraphs(),

        SizedBox(height: 20),

        // 부가 지표
        _buildSecondaryGraphs(),
      ],
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${graphs!.patientName}님의 검사 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '검사일: ${graphs!.testDate}',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryGraphs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                '핵심 간 검사 지표',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        GraphCard(
          title: 'AFP',
          imageBase64: graphs!.primary.afp,
          importance: 'critical',
          status: graphs!.summary.afp?.status,
        ),

        GraphCard(
          title: 'AST',
          imageBase64: graphs!.primary.ast,
          importance: 'high',
          status: graphs!.summary.ast?.status,
        ),

        GraphCard(
          title: 'ALT',
          imageBase64: graphs!.primary.alt,
          importance: 'high',
          status: graphs!.summary.alt?.status,
        ),

        GraphCard(
          title: 'ALBI Grade (간 기능 종합)',
          imageBase64: graphs!.primary.albiGrade,
          importance: 'high',
        ),
      ],
    );
  }

  Widget _buildSecondaryGraphs() {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.bar_chart, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            '📊 부가 지표',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      children: [
        if (graphs!.secondary.ggt != null)
          GraphCard(title: 'GGT', imageBase64: graphs!.secondary.ggt),

        if (graphs!.secondary.rGtp != null)
          GraphCard(title: 'r-GTP', imageBase64: graphs!.secondary.rGtp),

        if (graphs!.secondary.bilirubin != null)
          GraphCard(
            title: 'Bilirubin',
            imageBase64: graphs!.secondary.bilirubin,
          ),

        if (graphs!.secondary.albumin != null)
          GraphCard(title: 'Albumin', imageBase64: graphs!.secondary.albumin),
      ],
    );
  }
}
