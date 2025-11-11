import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/main_page.dart';

void main() {
  runApp(const LiverGuardApp());
}

class LiverGuardApp extends StatelessWidget {
  const LiverGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "LiverGuard",
      theme: ThemeData(primarySwatch: Colors.blue),

      initialRoute: "/login",

      routes: {
        "/login": (context) => const LoginPage(),
        "/tutorial": (context) => const TutorialPage(),
        "/main": (context) => const MainPage(),
        "/signup": (context) => const SignupPage(),
      },
    );
  }
}
