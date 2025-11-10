import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/ddi_page.dart';
import 'pages/calendar_page.dart';
import 'pages/hospital_map_page.dart';

void main() {
  runApp(const LiverGuardApp());
}

class LiverGuardApp extends StatelessWidget {
  const LiverGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LiverGuard",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    DDIPage(),
    CalendarPage(),
    HospitalMapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "DDI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "Hospital",
          ),
        ],

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
