import 'package:flutter/material.dart';
import '../fitness_app_theme.dart';
import '../../api/auth_service.dart';
import '../../api/blood_result_service.dart';
import '../../models/patient.dart';
import '../../models/blood_result.dart';
import '../../utils/storage_helper.dart';

class MyDiaryScreen extends StatefulWidget {
  const MyDiaryScreen({Key? key, this.animationController}) : super(key: key);

  final AnimationController? animationController;

  @override
  _MyDiaryScreenState createState() => _MyDiaryScreenState();
}

class _MyDiaryScreenState extends State<MyDiaryScreen>
    with TickerProviderStateMixin {
  Patient? userInfo;
  List<BloodResult> bloodResults = [];
  bool isLoading = true;
  String? selectedOrgan;

  final List<OrganInfo> organs = [
    OrganInfo(
      id: 'liver',
      label: '간',
      x: 0.58,
      y: 0.42,
      color: const Color(0xFF1ECBE1), // Cyan
      tests: ['AST', 'ALT', 'ALP', 'GGT', 'Bilirubin', 'Albumin', 'ALBI'],
    ),
    OrganInfo(
      id: 'blood',
      label: '혈액/응고',
      x: 0.43,
      y: 0.38,
      color: const Color(0xFFEC4899), // Pink
      tests: ['INR', 'Platelet'],
    ),
    OrganInfo(
      id: 'tumor',
      label: '종양표지자',
      x: 0.52,
      y: 0.45,
      color: const Color(0xFF8B5CF6), // Purple
      tests: ['AFP'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      // 사용자 정보 가져오기
      final user = await AuthService.getUserInfo();

      // 환자 ID 가져오기
      final patientId = await StorageHelper.getPatientId();

      if (user != null && patientId != null) {
        // 혈액검사 결과 가져오기
        final results =
            await BloodResultService.getPatientBloodResults(patientId);

        setState(() {
          userInfo = user;
          bloodResults = results;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('데이터 로딩 실패: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FitnessAppTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 16),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildBodyDiagramSection(),
                      const SizedBox(height: 24),
                      _buildBloodResults(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '신체 부위별 검사 결과',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: FitnessAppTheme.nearlyBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '장기를 클릭하여 관련 혈액검사 결과를 확인하세요',
            style: TextStyle(
              fontSize: 14,
              color: FitnessAppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyDiagramSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Body Diagram
          Container(
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
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/body-diagram.png',
                    fit: BoxFit.contain,
                  ),
                  ...organs.map((organ) => _buildOrganHotspot(organ)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Patient Profile Card
          if (userInfo != null) _buildPatientInfo(),
        ],
      ),
    );
  }

  Widget _buildOrganHotspot(OrganInfo organ) {
    final isActive = selectedOrgan == organ.id;

    return Positioned(
      left: MediaQuery.of(context).size.width * organ.x * 0.85 - 25,
      top: MediaQuery.of(context).size.width * organ.y * 0.85 - 25,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedOrgan = selectedOrgan == organ.id ? null : organ.id;
          });

          // Scroll to organ section
          if (selectedOrgan != null) {
            Future.delayed(const Duration(milliseconds: 300), () {
              // Scrolling logic can be added here
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: organ.color.withOpacity(isActive ? 0.9 : 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: organ.color.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  bottom: -35,
                  left: -15,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: organ.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      organ.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${userInfo!.name} 님의 건강 프로필',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FitnessAppTheme.nearlyBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('나이', '${userInfo!.age}세'),
              ),
              Expanded(
                child: _buildInfoItem('성별', userInfo!.sexDisplay),
              ),
            ],
          ),
          if (userInfo!.height != null && userInfo!.weight != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildInfoItem(
                '신장/체중',
                '${userInfo!.height}cm / ${userInfo!.weight}kg',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: FitnessAppTheme.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FitnessAppTheme.nearlyBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodResults() {
    if (bloodResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
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
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.article_outlined,
                  size: 48, color: FitnessAppTheme.grey),
              SizedBox(height: 16),
              Text(
                '혈액검사 결과가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: FitnessAppTheme.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '검사 결과를 추가해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: FitnessAppTheme.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 가장 최근 검사 결과
    final latestResult = bloodResults.first;

    return Column(
      children: organs.map((organ) {
        if (selectedOrgan != null && selectedOrgan != organ.id) {
          return const SizedBox();
        }

        return _buildOrganSection(organ, latestResult);
      }).toList(),
    );
  }

  Widget _buildOrganSection(OrganInfo organ, BloodResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: organ.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  color: organ.color,
                ),
                const SizedBox(width: 12),
                Text(
                  '${organ.label} 관련 검사',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: organ.color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: organ.tests.map((testName) {
                return _buildTestCard(testName, result);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(String testName, BloodResult result) {
    // 테스트 값 가져오기
    double? value;
    String unit = '';
    List<double> normalRange = [];

    switch (testName) {
      case 'AST':
        value = result.ast;
        unit = 'U/L';
        normalRange = [0, 40];
        break;
      case 'ALT':
        value = result.alt;
        unit = 'U/L';
        normalRange = [0, 41];
        break;
      case 'ALP':
        value = result.alp;
        unit = 'U/L';
        normalRange = [30, 120];
        break;
      case 'GGT':
        value = result.ggt;
        unit = 'U/L';
        normalRange = [0, 51];
        break;
      case 'Bilirubin':
        value = result.bilirubin;
        unit = 'mg/dL';
        normalRange = [0.2, 1.2];
        break;
      case 'Albumin':
        value = result.albumin;
        unit = 'g/dL';
        normalRange = [3.5, 5.5];
        break;
      case 'INR':
        value = result.inr;
        unit = '';
        normalRange = [0.8, 1.2];
        break;
      case 'Platelet':
        value = result.platelet;
        unit = '×10³/μL';
        normalRange = [150, 400];
        break;
      case 'AFP':
        value = result.afp;
        unit = 'ng/mL';
        normalRange = [0, 10];
        break;
      case 'ALBI':
        value = result.albi;
        unit = '';
        normalRange = [-2.6, -1.4];
        break;
    }

    if (value == null) return const SizedBox();

    final status = result.getStatus(testName);
    final Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FitnessAppTheme.nearlyWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FitnessAppTheme.nearlyBlack,
                    ),
                  ),
                  Text(
                    '정상: ${normalRange[0]} - ${normalRange[1]} $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FitnessAppTheme.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / normalRange[1]).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          if (status != 'normal')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    status == 'high' ? '정상 범위보다 높습니다' : '정상 범위보다 낮습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'low':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }
}

class OrganInfo {
  final String id;
  final String label;
  final double x;
  final double y;
  final Color color;
  final List<String> tests;

  OrganInfo({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.color,
    required this.tests,
  });
}
