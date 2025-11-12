import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_textfield.dart';
import '../api/auth_api.dart';
import '../utils/secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "LiverGuard Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                CustomTextField(controller: idController, hintText: "ID"),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: "로그인",
                  onPressed: () async {
                    final id = idController.text.trim();
                    final pw = passwordController.text.trim();

                    if (id.isEmpty || pw.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("아이디와 비밀번호를 입력하세요.")),
                      );
                      return;
                    }

                    final result = await AuthApi.login(id, pw);

                    if (result["success"] == true) {
                      Navigator.pushReplacementNamed(context, "/main");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result["message"])),
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/signup");
                  },
                  child: const Text("회원가입", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
