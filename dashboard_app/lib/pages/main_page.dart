import 'package:flutter/material.dart';
import 'home_page.dart';
import 'ddi_page.dart';
import 'calendar_page.dart';
import 'hospital_map_page.dart';
import 'blood_test_add_page.dart';
import 'drug_add_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
      appBar: AppBar(
        title: const Text("LiverGuard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, "/profile");
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],

      // 중앙 + 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, size: 32),
      ),

      // + 버튼을 하단바 중앙에 배치
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.bloodtype, color: Colors.red),
                title: Text("혈액검사 기록 추가"),
                onTap: () {
                  Navigator.pop(context); // BottomSheet 닫기
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BloodTestAddPage()),
                  );
                },
              ),

              Divider(),

              ListTile(
                leading: Icon(Icons.medication, color: Colors.blue),
                title: Text("복용약물 추가"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DrugAddPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
