import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../themes/fitness_app/fitness_app_theme.dart';
import '../widgets/blood_test_line_chart.dart';
import 'survival_prediction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> bloodTestList = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadAllData();
  }

  // 🔧 헬퍼 함수: 안전한 double 변환
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      // 1. 프로필 로드
      final profile = await DashboardService.fetchUserProfile();

      // 2. 검사 기록 리스트 로드
      final allTests = await DashboardService.fetchAllBloodTests();

      // 현재 사용자 ID로 필터링
      final currentPatientId = profile['patient_id'].toString();
      final filteredTests = allTests.where((test) {
        final testPatientId =
            test['patient_id']?.toString() ?? test['patient']?.toString() ?? '';
        return testPatientId == currentPatientId;
      }).toList();

      // 날짜순 정렬 (최신순)
      filteredTests.sort((a, b) {
        final dateA = DateTime.tryParse(a['taken_at'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['taken_at'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      setState(() {
        userProfile = profile;
        bloodTestList = filteredTests;
        isLoading = false;
      });

      // 애니메이션 시작
      animationController?.forward();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FitnessAppTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _buildErrorView()
            : RefreshIndicator(
                onRefresh: _loadAllData,
                child: _buildScrollableContent(),
              ),
        // 중앙 하단 FloatingActionButton
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddBloodTestDialog,
          backgroundColor: FitnessAppTheme.nearlyDarkBlue,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('오류가 발생했습니다', style: FitnessAppTheme.title),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: FitnessAppTheme.body2.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: FitnessAppTheme.nearlyDarkBlue,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 100,
      ),
      children: [
        _buildTopSection(),
        const SizedBox(height: 24),
        _buildBloodTestListSection(),
        const SizedBox(height: 24),
        _buildTimeSeriesGraphsSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ========================================
  // 1️⃣ 상단 섹션: 인체 이미지 + 프로필
  // ========================================
  Widget _buildTopSection() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: animationController!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animationController!.value),
              0.0,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildBodyDiagram()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildProfileCard()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          AspectRatio(
            aspectRatio: 0.8,
            child: Stack(
              children: [
                Image.asset('assets/images/body.png', fit: BoxFit.contain),
                Positioned(
                  left: 100,
                  top: 120,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    if (userProfile == null) return const SizedBox();

    final name = userProfile!['name'] ?? '사용자';
    final birthDate = userProfile!['birth_date'] ?? '';
    final sex = userProfile!['sex'] == 'male' ? '남성' : '여성';
    final heightValue = userProfile!['height'];
    final height = heightValue != null ? heightValue.toInt().toString() : '-';
    final weightValue = userProfile!['weight'];
    final weight = weightValue != null ? weightValue.toStringAsFixed(1) : '-';

    int age = 0;
    if (birthDate.isNotEmpty) {
      try {
        final birth = DateTime.parse(birthDate);
        age = DateTime.now().year - birth.year;
      } catch (e) {
        age = 0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text('$name님', style: FitnessAppTheme.title),
          const Divider(height: 24),
          _buildProfileItem(Icons.cake, '나이', '${age}세'),
          _buildProfileItem(Icons.wc, '성별', sex),
          _buildProfileItem(Icons.height, '신장/체중', '${height}cm / ${weight}kg'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FitnessAppTheme.nearlyDarkBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: FitnessAppTheme.body2.copyWith(color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: FitnessAppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 2️⃣ 중간 섹션: 검사 기록 리스트
  // ========================================
  Widget _buildBloodTestListSection() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animationController!,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('검사 기록', style: FitnessAppTheme.title),
                  Text(
                    '총 ${bloodTestList.length}건',
                    style: FitnessAppTheme.body2.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            bloodTestList.isEmpty ? _buildEmptyState() : _buildTestList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '검사 기록이 없습니다',
              style: FitnessAppTheme.body2.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bloodTestList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildBloodTestListItem(bloodTestList[index]);
      },
    );
  }

  Widget _buildBloodTestListItem(Map<String, dynamic> test) {
    final takenAt = test['taken_at'] ?? '';
    final afp = _parseToDouble(test['afp']);
    final ast = _parseToDouble(test['ast']);
    final alt = _parseToDouble(test['alt']);

    Color statusColor = Colors.green;
    if (afp != null) {
      if (afp > 200) {
        statusColor = Colors.red;
      } else if (afp > 20) {
        statusColor = Colors.orange;
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.calendar_today, color: statusColor, size: 24),
      ),
      title: Text(takenAt, style: FitnessAppTheme.subtitle),
      subtitle: Text(
        'AFP: ${afp?.toStringAsFixed(1) ?? '-'} | AST: ${ast?.toStringAsFixed(0) ?? '-'} | ALT: ${alt?.toStringAsFixed(0) ?? '-'}',
        style: FitnessAppTheme.caption,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: FitnessAppTheme.nearlyDarkBlue,
            onPressed: () => _showEditBloodTestDialog(test),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _deleteBloodTest(test['blood_result_id']),
          ),
        ],
      ),
      onTap: () => _showDetailDialog(test),
    );
  }

  // ========================================
  // 3️⃣ 하단 섹션: 시계열 그래프
  // ========================================
  Widget _buildTimeSeriesGraphsSection() {
    if (bloodTestList.isEmpty) return const SizedBox();

    final dates = <DateTime>[];
    final afpValues = <double>[];
    final astValues = <double>[];
    final altValues = <double>[];
    final bilirubinValues = <double>[];
    final albuminValues = <double>[];
    final albiGradeValues = <double>[];

    for (var test in bloodTestList.reversed) {
      final date = DateTime.tryParse(test['taken_at'] ?? '');
      if (date == null) continue;

      dates.add(date);
      afpValues.add(_parseToDouble(test['afp']) ?? 0);
      astValues.add(_parseToDouble(test['ast']) ?? 0);
      altValues.add(_parseToDouble(test['alt']) ?? 0);
      bilirubinValues.add(_parseToDouble(test['bilirubin']) ?? 0);
      albuminValues.add(_parseToDouble(test['albumin']) ?? 0);

      final albiGrade = test['albi_grade'];
      double? gradeValue;
      if (albiGrade != null) {
        if (albiGrade is num) {
          gradeValue = albiGrade.toDouble();
        } else if (albiGrade is String) {
          gradeValue = double.tryParse(albiGrade);
        }
      }
      albiGradeValues.add(gradeValue ?? 0);
    }

    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animationController!,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('중요 지표 추이', style: FitnessAppTheme.title),
          ),
          const SizedBox(height: 16),

          if (afpValues.isNotEmpty && dates.length == afpValues.length)
            _buildSingleLineGraphCard(
              title: 'AFP (종양 표지자)',
              dates: dates,
              label: 'AFP',
              values: afpValues,
              lineColor: const Color(0xFFFF5287),
              normalMax: 20,
            ),

          if (astValues.isNotEmpty && altValues.isNotEmpty)
            _buildMultiLineGraphCard(
              title: '간 효소 (AST/ALT)',
              dates: dates,
              dataLines: {'AST': astValues, 'ALT': altValues},
              lineColors: {
                'AST': const Color(0xFF5C5EDD),
                'ALT': const Color(0xFF00B6F0),
              },
              normalMax: 40,
            ),

          if (bilirubinValues.isNotEmpty &&
              albuminValues.isNotEmpty &&
              albiGradeValues.isNotEmpty)
            _buildMultiLineGraphCard(
              title: 'ALBI 관련 지표',
              dates: dates,
              dataLines: {
                'Bilirubin': bilirubinValues,
                'Albumin': albuminValues,
                'ALBI Grade': albiGradeValues,
              },
              lineColors: {
                'Bilirubin': const Color(0xFF00D9C0),
                'Albumin': const Color(0xFF9C27B0),
                'ALBI Grade': const Color(0xFFFF9800),
              },
              isAlbiGrade: true, // 👈 ALBI Grade 표시용
            ),
        ],
      ),
    );
  }

  Widget _buildSingleLineGraphCard({
    required String title,
    required List<DateTime> dates,
    required String label,
    required List<double> values,
    required Color lineColor,
    double? normalMax,
  }) {
    final latestValue = values.last;
    String warningText = '정상';
    Color warningColor = Colors.green;

    if (normalMax != null) {
      if (latestValue > normalMax * 2) {
        warningText = '⚠️ 위험';
        warningColor = Colors.red;
      } else if (latestValue > normalMax) {
        warningText = '⚠️ 주의';
        warningColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningColor, width: 1),
                ),
                child: Text(
                  warningText,
                  style: TextStyle(
                    color: warningColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StylishBloodTestChart(
            dates: dates,
            dataLines: {label: values},
            title: title,
            lineColors: {label: lineColor},
            normalMax: normalMax,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLineGraphCard({
    required String title,
    required List<DateTime> dates,
    required Map<String, List<double>> dataLines,
    required Map<String, Color> lineColors,
    double? normalMax,
    bool isAlbiGrade = false, // 👈 ALBI Grade 여부
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StylishBloodTestChart(
            dates: dates,
            dataLines: dataLines,
            title: title,
            lineColors: lineColors,
            normalMax: normalMax,
            isAlbiGrade: isAlbiGrade, // 👈 전달
          ),
        ],
      ),
    );
  }

  // ========================================
  // CRUD 다이얼로그
  // ========================================
  void _showAddBloodTestDialog() {
    _showBloodTestDialog(isEdit: false, initialData: null);
  }

  void _showEditBloodTestDialog(Map<String, dynamic> test) {
    _showBloodTestDialog(isEdit: true, initialData: test);
  }

  void _showBloodTestDialog({
    required bool isEdit,
    required Map<String, dynamic>? initialData,
  }) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = isEdit && initialData != null
        ? DateTime.parse(initialData['taken_at'])
        : DateTime.now();

    final dateController = TextEditingController(
      text:
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
    );

    final controllers = {
      'afp': TextEditingController(text: initialData?['afp']?.toString() ?? ''),
      'ast': TextEditingController(text: initialData?['ast']?.toString() ?? ''),
      'alt': TextEditingController(text: initialData?['alt']?.toString() ?? ''),
      'ggt': TextEditingController(text: initialData?['ggt']?.toString() ?? ''),
      'r_gtp': TextEditingController(
        text: initialData?['r_gtp']?.toString() ?? '',
      ),
      'bilirubin': TextEditingController(
        text: initialData?['bilirubin']?.toString() ?? '',
      ),
      'albumin': TextEditingController(
        text: initialData?['albumin']?.toString() ?? '',
      ),
      'alp': TextEditingController(text: initialData?['alp']?.toString() ?? ''),
      'total_protein': TextEditingController(
        text: initialData?['total_protein']?.toString() ?? '',
      ),
      'pt': TextEditingController(text: initialData?['pt']?.toString() ?? ''),
      'platelet': TextEditingController(
        text: initialData?['platelet']?.toString() ?? '',
      ),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '검사 수정' : '검사 추가', style: FitnessAppTheme.title),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dateController.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: '검사일',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...controllers.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: e.value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: e.key.toUpperCase(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final data = <String, dynamic>{
                    'taken_at': dateController.text,
                  };

                  // 🔧 빈 값은 null, 값이 있으면 숫자로
                  for (var entry in controllers.entries) {
                    final text = entry.value.text.trim();
                    data[entry.key] = text.isEmpty
                        ? null
                        : double.tryParse(text);
                  }

                  print('📤 전송 데이터: $data');

                  if (isEdit) {
                    print('✏️ 수정 ID: ${initialData!['blood_result_id']}');
                    await DashboardService.updateBloodTest(
                      initialData!['blood_result_id'],
                      data,
                    );
                  } else {
                    print('➕ 추가 모드');
                    await DashboardService.createBloodTest(data);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
                  _loadAllData();
                } catch (e) {
                  print('❌ 에러: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('저장 실패: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitnessAppTheme.nearlyDarkBlue,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('검사일: ${test['taken_at']}', style: FitnessAppTheme.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('AFP', test['afp'], 'ng/mL'),
              _buildDetailItem('AST', test['ast'], 'U/L'),
              _buildDetailItem('ALT', test['alt'], 'U/L'),
              _buildDetailItem('GGT', test['ggt'], 'U/L'),
              _buildDetailItem('r-GTP', test['r_gtp'], 'U/L'),
              _buildDetailItem('Bilirubin', test['bilirubin'], 'mg/dL'),
              _buildDetailItem('Albumin', test['albumin'], 'g/dL'),
              _buildDetailItem('ALP', test['alp'], 'U/L'),
              _buildDetailItem('Total Protein', test['total_protein'], 'g/dL'),
              _buildDetailItem('PT', test['pt'], 'sec'),
              _buildDetailItem('Platelet', test['platelet'], '×10³/μL'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSurvivalPrediction(test);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitnessAppTheme.nearlyDarkBlue,
            ),
            icon: const Icon(Icons.analytics, color: Colors.white),
            label: const Text('생존확률 예측', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value, String unit) {
    final parsedValue = _parseToDouble(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FitnessAppTheme.body2.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${parsedValue?.toStringAsFixed(1) ?? '-'} $unit',
            style: FitnessAppTheme.body2,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBloodTest(int bloodResultId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인', style: FitnessAppTheme.title),
        content: const Text('이 검사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DashboardService.deleteBloodTest(bloodResultId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  // ========================================
  // 생존확률 예측 페이지로 이동
  // ========================================
  void _navigateToSurvivalPrediction(Map<String, dynamic> test) {
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보를 불러올 수 없습니다')),
      );
      return;
    }

    // 필수 데이터 검증
    final afp = _parseToDouble(test['afp']);
    final albumin = _parseToDouble(test['albumin']);
    final pt = _parseToDouble(test['pt']);

    if (afp == null || albumin == null || pt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 혈액검사 데이터(AFP, Albumin, PT)가 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurvivalPredictionPage(
          userProfile: userProfile!,
          bloodTestData: test,
        ),
      ),
    );
  }
}
