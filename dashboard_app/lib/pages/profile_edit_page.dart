import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/auth_api.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileEditPage({super.key, required this.userData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController birthController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController addressController;
  late TextEditingController phoneController;

  String? selectedSex;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData["name"]);
    birthController = TextEditingController(
      text: widget.userData["birth_date"],
    );
    heightController = TextEditingController(
      text: widget.userData["height"]?.toString() ?? "",
    );
    weightController = TextEditingController(
      text: widget.userData["weight"]?.toString() ?? "",
    );
    addressController = TextEditingController(
      text: widget.userData["address"] ?? "",
    );
    phoneController = TextEditingController(
      text: widget.userData["phone"] ?? "",
    );
    selectedSex = widget.userData["sex"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("프로필 수정")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("이름", nameController),
              const SizedBox(height: 20),

              _buildBirthDatePicker(),
              const SizedBox(height: 20),

              _buildSexSelector(),
              const SizedBox(height: 20),

              _buildField("키 (cm)", heightController, isNumber: true),
              const SizedBox(height: 20),

              _buildField("몸무게 (kg)", weightController, isNumber: true),
              const SizedBox(height: 20),

              _buildField("주소", addressController),
              const SizedBox(height: 20),

              _buildField("핸드폰 번호", phoneController),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("저장하기"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "값을 입력하세요." : null,
    );
  }

  // 🔹 생년월일 picker
  Widget _buildBirthDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateFormat("yyyy-MM-dd").parse(birthController.text),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          birthController.text = DateFormat("yyyy-MM-dd").format(picked);
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 10),
            Text(birthController.text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 🔹 성별 선택
  Widget _buildSexSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("성별", style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Radio<String>(
              value: "male",
              groupValue: selectedSex,
              onChanged: (v) => setState(() => selectedSex = v),
            ),
            const Text("남성"),

            Radio<String>(
              value: "female",
              groupValue: selectedSex,
              onChanged: (v) => setState(() => selectedSex = v),
            ),
            const Text("여성"),
          ],
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final height = double.tryParse(heightController.text) ?? 0;
    final weight = double.tryParse(weightController.text) ?? 0;

    final result = await AuthApi.updateProfile(
      name: nameController.text.trim(),
      birthDate: birthController.text.trim(),
      sex: selectedSex!,
      height: height,
      weight: weight,
      address: addressController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("프로필이 수정되었습니다.")));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("수정 실패: ${result["message"]}")));
    }
  }
}
