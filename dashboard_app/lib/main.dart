import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/main_page.dart';
import 'pages/profile_page.dart';
import 'api/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.initialize();
  await initializeDateFormatting('ko_KR', null);

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

      initialRoute: "/tutorial",

      routes: {
        "/login": (context) => const LoginPage(),
        "/tutorial": (context) => const TutorialPage(),
        "/main": (context) => const MainPage(),
        "/signup": (context) => const SignupPage(),
        "/profile": (context) => const ProfilePage(),
      },
    );
  }
}
