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
  final alpController = TextEditingController();
  final totalProteinController = TextEditingController();
  final ptController = TextEditingController();
  final plateletController = TextEditingController();

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
              _buildNumberField("R-GTP (IU/L)", rGtpController),
              _buildNumberField("Bilirubin (mg/dL)", bilirubinController),
              _buildNumberField("Albumin (g/dL)", albuminController),
              _buildNumberField("ALP (IU/L)", alpController),
              _buildNumberField("Total Protein (g/dL)", totalProteinController),
              _buildNumberField("PT (sec)", ptController),
              _buildNumberField("Platelet (10³/µL)", plateletController),
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
  // 🔥 저장 버튼 눌렀을 때 실행되는 함수
  // ---------------------------------------------------------
  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("검사 날짜를 선택해주세요.")));
      return;
    }

    // 🔥 Django API 호출
    bool success = await BloodResultApi.addBloodResult(
      afp: double.parse(afpController.text),
      ast: double.parse(astController.text),
      alt: double.parse(altController.text),
      ggt: double.parse(ggtController.text),
      rGtp: double.parse(rGtpController.text),
      bilirubin: double.parse(bilirubinController.text),
      albumin: double.parse(albuminController.text),
      alp: double.parse(alpController.text),
      totalProtein: double.parse(totalProteinController.text),
      pt: double.parse(ptController.text),
      platelet: double.parse(plateletController.text),
      takenAt: selectedDate!,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("혈액검사 기록이 저장되었습니다.")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("저장 실패")));
    }
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
