import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/auth_api.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedSex; // "남성" or "여성"
  bool _isLoading = false;

  // 📅 날짜 선택 위젯
  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  // 🚀 회원가입 처리
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("생년월일을 선택해주세요.")));
      return;
    }
    if (_selectedSex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("성별을 선택해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();
    final password2 = _password2Controller.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final birthDate = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);
    final sex = _selectedSex == "남성" ? "male" : "female";

    try {
      final response = await AuthApi.register(
        userId: userId,
        password: password,
        password2: password2,
        name: name,
        birthDate: birthDate,
        sex: sex,
        phone: phone,
      );

      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "회원가입 성공")),
        );
        Navigator.pop(context); // 로그인 페이지로 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "회원가입 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: "아이디"),
                validator: (v) => v!.isEmpty ? "아이디를 입력하세요" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
                validator: (v) => v!.length < 6 ? "비밀번호는 6자 이상이어야 합니다" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password2Controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호 확인"),
                validator: (v) =>
                    v != _passwordController.text ? "비밀번호가 일치하지 않습니다" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "이름"),
                validator: (v) => v!.isEmpty ? "이름을 입력하세요" : null,
              ),
              const SizedBox(height: 16),
              // 📅 생년월일 선택
              InkWell(
                onTap: () => _pickBirthDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "생년월일"),
                  child: Text(
                    _selectedBirthDate == null
                        ? "날짜 선택"
                        : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 🚻 성별 선택
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: const InputDecoration(labelText: "성별"),
                items: const [
                  DropdownMenuItem(value: "남성", child: Text("남성")),
                  DropdownMenuItem(value: "여성", child: Text("여성")),
                ],
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (v) => v == null ? "성별을 선택하세요" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "전화번호"),
                validator: (v) => v!.isEmpty ? "전화번호를 입력하세요" : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("회원가입"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
