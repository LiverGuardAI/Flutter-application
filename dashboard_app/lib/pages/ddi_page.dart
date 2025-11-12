import 'package:flutter/material.dart';
// ! (패키지 설치 필요: flutter pub add flutter_typeahead)
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart'; // 방금 수정한 서비스

// DDI 페이지 메인 위젯
class DDIPage extends StatefulWidget {
  const DDIPage({super.key});

  @override
  State<DDIPage> createState() => _DDIPageState();
}

class _DDIPageState extends State<DDIPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _typeAheadController = TextEditingController();

  // React의 State와 동일
  List<Map<String, String>> _selectedDrugs =
      []; // {value: 'warfarin', label: '와파린 (warfarin)'}
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _apiResponse; // 통합 검사 결과

  // 통합 검사 실행 (React의 handlePredict)
  void _handlePredict() async {
    if (_selectedDrugs.length < 2) {
      setState(() {
        _error = '최소 2개 이상의 약물을 선택하세요.';
        _apiResponse = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _apiResponse = null;
    });

    try {
      final drugValues = _selectedDrugs.map((d) => d['value']!).toList();
      final response = await _apiService.checkAllDDI(drugValues);
      setState(() {
        _apiResponse = response;
      });
    } catch (e) {
      setState(() {
        _error = '백엔드 서버(api_v2.py) 연결에 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 초기화 핸들러
  void _handleResetAll() {
    setState(() {
      _selectedDrugs = [];
      _apiResponse = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // [신규] 위험 약물 목록 추출 (React와 동일)
    final problematicDrugsMap =
        _apiResponse?['problematic_drugs'] as Map<String, dynamic>?;
    final bool showAlternativeSection =
        problematicDrugsMap != null && problematicDrugsMap.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('약물 상호작용 (DDI) 예측')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('환자의 현재 처방 약물을 모두 선택하세요 (한글명/영문명 검색 가능):'),
            const SizedBox(height: 10),

            // --- 1. 비동기 검색창 (AsyncSelect 대체) ---
            TypeAheadField<Map<String, String>>(
              controller: _typeAheadController,
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: '약물 이름 검색...',
                  border: OutlineInputBorder(),
                ),
                // The suffixIcon property is part of InputDecoration,
                // so it should be inside the InputDecoration constructor.
                // It was already there, so no change needed.
                // suffixIcon: const Icon(Icons.search),
              ),

              suggestionsCallback: (pattern) async {
                // 타이핑 시 서버 API 호출
                return await _apiService.searchDrugs(pattern);
              },
              itemBuilder: (context, Map<String, String> suggestion) {
                return ListTile(title: Text(suggestion['label'] ?? ''));
              },
              // [수정] onSuggestionSelected -> onSelected
              onSelected: (Map<String, String> suggestion) {
                // 선택 시 _selectedDrugs 리스트에 추가
                if (!_selectedDrugs.any(
                  (d) => d['value'] == suggestion['value'],
                )) {
                  setState(() {
                    _selectedDrugs.add(suggestion);
                  });
                }
                _typeAheadController.clear();
              },
              // [수정] noItemsFoundBuilder -> emptyBuilder
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('검색 결과가 없습니다.'),
              ),
            ),
            const SizedBox(height: 10),

            // --- 2. 선택된 약물 목록 (Chip) ---
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedDrugs.map((drug) {
                return Chip(
                  label: Text(drug['label'] ?? 'Unknown'),
                  onDeleted: () {
                    setState(() {
                      _selectedDrugs.removeWhere(
                        (d) => d['value'] == drug['value'],
                      );
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // --- 3. 통합 검사 버튼 ---
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePredict,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(_isLoading ? '통합 검사 중...' : '통합 검사 실행'),
            ),
            const SizedBox(height: 20),

            // --- 4. 결과 표시 영역 ---
            if (_error != null)
              Container(
                color: Colors.red[100],
                padding: const EdgeInsets.all(12),
                child: Text(
                  '오류: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_apiResponse != null) RenderResults(apiResponse: _apiResponse!),

            // --- 5. 대체 약물 추천 섹션 ---
            if (showAlternativeSection)
              AlternativeDrugs(
                originalDrugs: _selectedDrugs,
                problematicDrugsMap: problematicDrugsMap,
                onReset: _handleResetAll,
                apiService: _apiService,
              ),
          ],
        ),
      ),
    );
  }
}

// --- 결과 표시 위젯들 (React의 RenderResults) ---

// (React의 SectionWrapper)
class SectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      padding: const EdgeInsets.only(top: 10.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.blue, width: 2.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// (React의 ResultItem)
class ResultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String level; // 'high' or 'medium'

  const ResultItem({
    Key? key,
    required this.title,
    required this.subtitle,
    this.description = "",
    this.level = 'high',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = level == 'high'
        ? Colors.red[700]!
        : Colors.orange[700]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.red[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🚨 $title',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(fontSize: 13.0, color: Colors.grey[800]),
            ),
          ],
        ],
      ),
    );
  }
}

// (React의 AiResultPair)
class AiResultPair extends StatelessWidget {
  final Map<String, dynamic> pair;
  const AiResultPair({Key? key, required this.pair}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String pairName = (pair['pair_name'] ?? '').replaceAll("'", "");
    final List highRisk = pair['high_risk'] ?? [];
    final List mediumRisk = pair['medium_risk'] ?? [];
    final List lowRisk = pair['low_risk'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '💊 조합: $pairName',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          if (highRisk.isNotEmpty)
            _buildRiskSection(
              '🔴 고위험 (발생 확률 > 50%)',
              highRisk,
              Colors.red[700]!,
            ),
          if (mediumRisk.isNotEmpty)
            _buildRiskSection(
              '🟡 중위험 (20~50%)',
              mediumRisk,
              Colors.orange[700]!,
            ),
          if (lowRisk.isNotEmpty)
            ExpansionTile(
              title: Text(
                '🟢 저위험 (< 20%) 항목 ${lowRisk.length}건 상세 보기...',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                _buildRiskSection(
                  '',
                  lowRisk,
                  Colors.green[700]!,
                  showHeader: false,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRiskSection(
    String title,
    List risks,
    Color color, {
    bool showHeader = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ...risks.map((risk) {
          return Container(
            margin: const EdgeInsets.only(top: 10.0),
            padding: const EdgeInsets.only(left: 10.0),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${risk['event']} (${risk['probability']}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '기전: ${risk['description']}',
                  style: TextStyle(fontSize: 13.0, color: Colors.grey[800]),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

// (React의 RenderResults)
class RenderResults extends StatelessWidget {
  final Map<String, dynamic> apiResponse;
  const RenderResults({Key? key, required this.apiResponse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aiPredictions = (apiResponse['ai_predictions'] as List?) ?? [];
    final drugbankChecks = (apiResponse['drugbank_checks'] as List?) ?? [];
    final kfdaChecks = (apiResponse['kfda_checks'] as List?) ?? [];

    if (aiPredictions.isEmpty && drugbankChecks.isEmpty && kfdaChecks.isEmpty) {
      return Container(
        color: Colors.green[50],
        padding: const EdgeInsets.all(10),
        child: const Text(
          '✅ [통합 검사] 선택된 약물 조합에서 AI, DrugBank, KFDA 상호작용이 발견되지 않았습니다.',
          style: TextStyle(color: Colors.green),
        ),
      );
    }

    return Column(
      children: [
        // 1. DrugBank
        SectionWrapper(
          title: '1. DrugBank DB 병용금기 (1차 검사)',
          child: drugbankChecks.isEmpty
              ? const Text('✅ [DrugBank] 선택된 약물 간 상호작용이 없습니다.')
              : Column(
                  children: drugbankChecks.map((item) {
                    return ResultItem(
                      title: "금기 조합: '${item['drug_a']}' + '${item['drug_b']}'",
                      subtitle:
                          "상호작용 (ID: ${item['ddi_id']}): ${item['event']}",
                      description: "기전: ${item['description']}",
                      level: 'high',
                    );
                  }).toList(),
                ),
        ),
        // 2. KFDA
        SectionWrapper(
          title: '2. KFDA 고시 병용금기 (2차 검사)',
          child: kfdaChecks.isEmpty
              ? const Text('✅ [KFDA] 선택된 약물 간 병용금기 사항이 없습니다.')
              : Column(
                  children: kfdaChecks.map((item) {
                    return ResultItem(
                      title: "금기 조합: '${item['drug_a']}' + '${item['drug_b']}'",
                      subtitle: "금기 사유: ${item['reason']}",
                      level: 'high',
                    );
                  }).toList(),
                ),
        ),
        // 3. AI 예측
        SectionWrapper(
          title: '3. AI 기반 잠재적 상호작용 (3차 검사)',
          child: aiPredictions.isEmpty
              ? const Text('✅ [AI 예측] 선택된 약물 조합에서 특이 상호작용이 발견되지 않았습니다.')
              : Column(
                  children: aiPredictions.map((pair) {
                    return AiResultPair(pair: pair as Map<String, dynamic>);
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// --- [신규] 5. 대체 약물 추천 위젯 ---
class AlternativeDrugs extends StatefulWidget {
  final List<Map<String, String>> originalDrugs;
  final Map<String, dynamic> problematicDrugsMap;
  final VoidCallback onReset;
  final ApiService apiService;

  const AlternativeDrugs({
    Key? key,
    required this.originalDrugs,
    required this.problematicDrugsMap,
    required this.onReset,
    required this.apiService,
  }) : super(key: key);

  @override
  State<AlternativeDrugs> createState() => _AlternativeDrugsState();
}

class _AlternativeDrugsState extends State<AlternativeDrugs> {
  String? _targetDrugValue; // 교체 대상 (영문명 value)
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _alternatives; // { safe_alternatives: [], ... }

  void _handleFetchAlternatives() async {
    if (_targetDrugValue == null) {
      setState(() {
        _error = "교체할 약물을 먼저 선택하세요.";
      });
      return;
    }

    // 나머지 약물 목록 (영문명)
    final opponentDrugs = widget.originalDrugs
        .map((opt) => opt['value']!)
        .where((engName) => engName != _targetDrugValue)
        .toList();

    setState(() {
      _isLoading = true;
      _error = null;
      _alternatives = null;
    });

    try {
      final response = await widget.apiService.getAlternatives(
        _targetDrugValue!,
        opponentDrugs,
      );
      // --- [수정] 끊겼던 부분 ---
      setState(() {
        _alternatives = response;
      });
    } catch (e) {
      setState(() {
        _error = '대체 약물 검증 중 서버 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    // --- [수정] 끊겼던 부분 끝 ---
  }

  @override
  Widget build(BuildContext context) {
    // 1. 교체할 약물 선택 (Dropdown 옵션)
    final problematicOptions = widget.problematicDrugsMap.entries.map((entry) {
      // entry.key = 'warfarin' (value), entry.value = '와파린 (warfarin)' (label)
      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
    }).toList();

    return SectionWrapper(
      title: '5. 대체 약물 추천 (DDI 기반)',
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange[700]!),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.yellow[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🚨 상호작용 위험 약물이 감지되었습니다. 대체 약물 검증이 필요합니다.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 교체할 약물 선택 Dropdown
            DropdownButtonFormField<String>(
              value: _targetDrugValue,
              hint: const Text('교체할 약물 선택...'),
              items: problematicOptions,
              onChanged: (value) {
                setState(() {
                  _targetDrugValue = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            // 버튼들 (검증, 초기화)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleFetchAlternatives,
                    child: Text(_isLoading ? '검증 중...' : '안전한 대체 약물 찾기'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: widget.onReset,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                  ),
                  child: const Text('초기화'),
                ),
              ],
            ),

            // --- 대체 약물 검증 결과 ---
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  '오류: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_alternatives != null)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. 안전한 후보
                    Text(
                      '🟢 안전한 대체 후보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    AlternativeTable(
                      items:
                          (_alternatives!['safe_alternatives'] as List?) ?? [],
                      isSafe: true,
                    ),
                    const SizedBox(height: 15),

                    // 2. 위험한 후보 (Expander)
                    if (((_alternatives!['risky_alternatives'] as List?) ?? [])
                        .isNotEmpty)
                      ExpansionTile(
                        title: Text(
                          '🟡 위험이 감지된 후보 ${((_alternatives!['risky_alternatives'] as List?) ?? []).length}건 상세 보기...',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          AlternativeTable(
                            items:
                                (_alternatives!['risky_alternatives']
                                    as List?) ??
                                [],
                            isSafe: false,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- [신규] 대체 약물 표시용 테이블 ---
class AlternativeTable extends StatelessWidget {
  final List items;
  final bool isSafe;

  const AlternativeTable({Key? key, required this.items, required this.isSafe})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          isSafe ? '이 계열 내에서 안전한 대체 약물을 찾지 못했습니다.' : '',
          style: const TextStyle(fontSize: 13.0),
        ),
      );
    }

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey[300]!, width: 1.0),
        bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
      ),
      columnWidths: const {0: FlexColumnWidth(1.0), 1: FlexColumnWidth(1.5)},
      children: [
        // 헤더
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '대체약물',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                isSafe ? '계열' : '충돌 사유',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        // 본문
        ...items.map((item) {
          final itemMap = item as Map<String, dynamic>;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(itemMap['name'] ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  isSafe
                      ? (itemMap['category'] ?? '')
                      : (itemMap['reason'] ?? ''),
                  style: const TextStyle(fontSize: 13.0),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
