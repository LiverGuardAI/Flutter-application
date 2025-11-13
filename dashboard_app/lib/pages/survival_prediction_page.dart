import 'package:flutter/material.dart';
import '../services/survival_service.dart';
import '../themes/fitness_app/fitness_app_theme.dart';

class SurvivalPredictionPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic> bloodTestData;

  const SurvivalPredictionPage({
    Key? key,
    required this.userProfile,
    required this.bloodTestData,
  }) : super(key: key);

  @override
  State<SurvivalPredictionPage> createState() => _SurvivalPredictionPageState();
}

class _SurvivalPredictionPageState extends State<SurvivalPredictionPage> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? predictionResult;

  @override
  void initState() {
    super.initState();
    _predictSurvival();
  }

  Future<void> _predictSurvival() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 🔍 디버깅: 전체 프로필 데이터 확인
      print('🔍 ===== 프로필 데이터 디버깅 =====');
      print('📦 전체 userProfile: ${widget.userProfile}');
      print('📦 전체 bloodTestData: ${widget.bloodTestData}');

      // 프로필에서 데이터 추출
      final sex = widget.userProfile['sex'] ?? 'male';
      final birthDate = widget.userProfile['birth_date'] ?? '';
      final height = (widget.userProfile['height'] ?? 0).toDouble();
      final weight = (widget.userProfile['weight'] ?? 0).toDouble();

      print('📊 추출된 프로필 데이터:');
      print('  - sex: $sex (원본: ${widget.userProfile['sex']})');
      print('  - birthDate: $birthDate (원본: ${widget.userProfile['birth_date']})');
      print('  - height: $height (원본: ${widget.userProfile['height']})');
      print('  - weight: $weight (원본: ${widget.userProfile['weight']})');

      // 나이 계산
      int age = 0;
      if (birthDate.isNotEmpty) {
        try {
          final birth = DateTime.parse(birthDate);
          age = DateTime.now().year - birth.year;
        } catch (e) {
          age = 0;
        }
      }

      // BMI 계산
      final bmi = SurvivalService.calculateBMI(height, weight);

      // 혈액검사 데이터 추출
      final afp = _parseToDouble(widget.bloodTestData['afp']) ?? 0.0;
      final albumin = _parseToDouble(widget.bloodTestData['albumin']) ?? 0.0;
      final pt = _parseToDouble(widget.bloodTestData['pt']) ?? 0.0;

      print('📤 전송 데이터:');
      print('  sex: $sex');
      print('  age: $age');
      print('  height: $height');
      print('  weight: $weight');
      print('  bmi: $bmi');
      print('  AFP: $afp');
      print('  albumin: $albumin');
      print('  PT: $pt');

      // API 호출
      final result = await SurvivalService.predictSurvival(
        sex: sex,
        ageAtIndex: age,
        height: height,
        weight: weight,
        bmi: bmi,
        afp: afp,
        albumin: albumin,
        pt: pt,
      );

      setState(() {
        predictionResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생존확률 예측'),
        backgroundColor: FitnessAppTheme.nearlyDarkBlue,
      ),
      body: Container(
        color: FitnessAppTheme.background,
        child: isLoading
            ? _buildLoadingView()
            : errorMessage != null
                ? _buildErrorView()
                : _buildResultView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '생존확률을 예측하고 있습니다...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('예측 실패', style: FitnessAppTheme.title),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: FitnessAppTheme.body2.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _predictSurvival,
              style: ElevatedButton.styleFrom(
                backgroundColor: FitnessAppTheme.nearlyDarkBlue,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (predictionResult == null) return const SizedBox();

    // API 응답 구조에 따라 수정 필요
    final survivalProbability = predictionResult!['survival_probability'] ?? 0.0;
    final riskLevel = predictionResult!['risk_level'] ?? 'Unknown';
    final confidenceScore = predictionResult!['confidence_score'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSurvivalCard(survivalProbability),
          const SizedBox(height: 16),
          _buildRiskLevelCard(riskLevel),
          const SizedBox(height: 16),
          _buildConfidenceCard(confidenceScore),
          const SizedBox(height: 16),
          _buildInputDataCard(),
          const SizedBox(height: 16),
          _buildDisclaimerCard(),
        ],
      ),
    );
  }

  Widget _buildSurvivalCard(double probability) {
    final percentage = (probability * 100).toStringAsFixed(1);
    Color progressColor = Colors.green;
    if (probability < 0.3) {
      progressColor = Colors.red;
    } else if (probability < 0.6) {
      progressColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2E3B55), const Color(0xFF1E2940)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '생존 확률',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: probability,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '생존 가능성',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelCard(String riskLevel) {
    IconData icon = Icons.check_circle;
    Color color = Colors.green;
    String description = '정상 범위';

    if (riskLevel.toLowerCase().contains('high')) {
      icon = Icons.warning;
      color = Colors.red;
      description = '고위험군';
    } else if (riskLevel.toLowerCase().contains('medium')) {
      icon = Icons.info;
      color = Colors.orange;
      description = '중위험군';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FitnessAppTheme.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('위험도', style: FitnessAppTheme.body2.copyWith(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(description, style: FitnessAppTheme.title.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FitnessAppTheme.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('신뢰도', style: FitnessAppTheme.subtitle),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text('$percentage%', style: FitnessAppTheme.body2),
        ],
      ),
    );
  }

  Widget _buildInputDataCard() {
    final sex = widget.userProfile['sex'] == 'male' ? '남성' : '여성';
    final birthDate = widget.userProfile['birth_date'] ?? '';
    int age = 0;
    if (birthDate.isNotEmpty) {
      try {
        final birth = DateTime.parse(birthDate);
        age = DateTime.now().year - birth.year;
      } catch (e) {
        age = 0;
      }
    }
    final height = widget.userProfile['height'] ?? 0;
    final weight = widget.userProfile['weight'] ?? 0;
    final bmi = SurvivalService.calculateBMI(
      height.toDouble(),
      weight.toDouble(),
    ).toStringAsFixed(1);

    final afp = _parseToDouble(widget.bloodTestData['afp'])?.toStringAsFixed(1) ?? '-';
    final albumin = _parseToDouble(widget.bloodTestData['albumin'])?.toStringAsFixed(1) ?? '-';
    final pt = _parseToDouble(widget.bloodTestData['pt'])?.toStringAsFixed(1) ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FitnessAppTheme.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('입력 데이터', style: FitnessAppTheme.title),
          const Divider(height: 24),
          _buildDataRow('성별', sex),
          _buildDataRow('나이', '${age}세'),
          _buildDataRow('신장', '${height}cm'),
          _buildDataRow('체중', '${weight}kg'),
          _buildDataRow('BMI', bmi),
          const Divider(height: 24),
          _buildDataRow('AFP', '$afp ng/mL'),
          _buildDataRow('Albumin', '$albumin g/dL'),
          _buildDataRow('PT', '$pt sec'),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FitnessAppTheme.body2.copyWith(color: Colors.grey)),
          Text(value, style: FitnessAppTheme.body2.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 예측 결과는 참고용이며, 실제 의료 진단을 대체할 수 없습니다. '
              '정확한 진단과 치료를 위해서는 반드시 전문의와 상담하시기 바랍니다.',
              style: FitnessAppTheme.caption.copyWith(color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }
}
