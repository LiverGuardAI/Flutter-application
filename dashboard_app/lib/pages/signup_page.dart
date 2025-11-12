import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isObscure = true;
  bool _isObscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "회원가입",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 이름
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "이름",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 이메일
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "이메일",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 비밀번호
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "비밀번호",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isObscure = !_isObscure);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 비밀번호 확인
              TextField(
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                decoration: InputDecoration(
                  labelText: "비밀번호 확인",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isObscureConfirm = !_isObscureConfirm);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 나중에 Django 연동 시 여기에 요청 작성
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("회원가입 기능은 추후 연동됩니다.")),
                    );
                  },
                  child: const Text("가입하기"),
                ),
              ),
              const SizedBox(height: 20),

              // 로그인 화면 이동
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("이미 계정이 있으신가요? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "로그인",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
