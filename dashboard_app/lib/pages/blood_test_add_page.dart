import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/blood_result_api.dart'; // ← API 호출 import 추가

class BloodTestAddPage extends StatefulWidget {
  @override
  _BloodTestAddPageState createState() => _BloodTestAddPageState();
}

class _BloodTestAddPageState extends State<BloodTestAddPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final afpController = TextEditingController();
  final astController = TextEditingController();
  final altController = TextEditingController();
  final ggtController = TextEditingController();
  final rGtpController = TextEditingController();
  final bilirubinController = TextEditingController();
  final albuminController = TextEditingController();
  final inrController = TextEditingController();
  final ptController = TextEditingController();
  final plateletController = TextEditingController();
  final totalProteinController = TextEditingController();

  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("혈액검사 기록 추가"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNumberField("AFP (ng/mL)", afpController),
              _buildNumberField("AST (IU/L)", astController),
              _buildNumberField("ALT (IU/L)", altController),
              _buildNumberField("GGT (IU/L)", ggtController),
              _buildNumberField("r-GTP (IU/L)", rGtpController),
              _buildNumberField("Bilirubin (mg/dL)", bilirubinController),
              _buildNumberField("Albumin (g/dL)", albuminController),
              _buildNumberField("INR", inrController),
              _buildNumberField("PT (sec)", ptController),
              _buildNumberField("Platelet (10³/µL)", plateletController),
              _buildNumberField("AFP (ng/mL)", afpController),
              _buildNumberField("Total Protein (g/dL)", totalProteinController),
              SizedBox(height: 20),

              Text(
                "검사 날짜 선택",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildDatePicker(),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSavePressed,
                  child: Text("저장하기"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 저장 버튼 눌렀을 때 실행되는 함수
  // ---------------------------------------------------------
  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("검사 날짜를 선택해주세요.")));
      return;
    }

    // Django API 호출
    bool success = await BloodResultApi.addBloodResult(
      patientId: 1,
      ast: int.parse(astController.text),
      alt: int.parse(altController.text),
      alp: int.parse(alpController.text),
      ggt: int.parse(ggtController.text),
      rGtp: _parseIntSafe(rGtpController.text),
      bilirubin: double.parse(bilirubinController.text),
      albumin: double.parse(albuminController.text),
      inr: double.parse(inrController.text),
      pt: _parseDoubleSafe(ptController.text),
      platelet: int.parse(plateletController.text),
      afp: int.parse(afpController.text),
      totalProtein: _parseDoubleSafe(totalProteinController.text),
      takenAt: selectedDate!,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("혈액검사 기록이 저장되었습니다.")));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("저장 실패")));
    }
  }

  int _parseIntSafe(String text) {
    if (text.trim().isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  double _parseDoubleSafe(String text) {
    if (text.trim().isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  // 숫자 입력 필드
  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "값을 입력해주세요.";
          }
          return null;
        },
      ),
    );
  }

  // 날짜 선택
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 1),
        );

        if (pickedDate != null) {
          setState(() {
            selectedDate = pickedDate;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          selectedDate == null
              ? "날짜를 선택하세요"
              : DateFormat("yyyy-MM-dd").format(selectedDate!),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
