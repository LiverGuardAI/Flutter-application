import 'package:flutter/material.dart';

class LiverGuardSplash extends StatefulWidget {
  final AnimationController animationController;

  const LiverGuardSplash({Key? key, required this.animationController})
      : super(key: key);

  @override
  _LiverGuardSplashState createState() => _LiverGuardSplashState();
}

class _LiverGuardSplashState extends State<LiverGuardSplash> {
  @override
  Widget build(BuildContext context) {
    final _introductionanimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(0.0, -1.0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.0, 0.2, curve: Curves.fastOutSlowIn),
      ),
    );
    return SlideTransition(
      position: _introductionanimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Icon(
                  Icons.health_and_safety,
                  size: 150,
                  color: Colors.blue.shade400,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                "LiverGuard",
                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 64, right: 64),
              child: Text(
                "간암 환자를 위한 예후 관리 시스템\n스스로 자신의 몸을 관리할 수 있도록 도와드립니다",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            SizedBox(height: 48),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: InkWell(
                onTap: () {
                  widget.animationController.animateTo(0.2);
                },
                child: Container(
                  height: 58,
                  padding: EdgeInsets.only(
                    left: 56.0,
                    right: 56.0,
                    top: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38.0),
                    color: Colors.blue,
                  ),
                  child: Text(
                    "내 몸 관리 시작하기",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
