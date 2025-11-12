import 'package:flutter/material.dart';

class DiagnosisView extends StatelessWidget {
  final AnimationController animationController;

  const DiagnosisView({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.0, 0.2, curve: Curves.fastOutSlowIn),
          ),
        );
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
          ),
        );
    final textAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(-2, 0))
        .animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
          ),
        );
    final imageAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-4, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
          ),
        );

    final titleAnimation =
        Tween<Offset>(begin: Offset(0, -2), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.0, 0.2, curve: Curves.fastOutSlowIn),
          ),
        );

    return SlideTransition(
      position: firstHalfAnimation,
      child: SlideTransition(
        position: secondHalfAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: titleAnimation,
                child: Text(
                  "꾸준한 건강 관리를 위해",
                  style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
                ),
              ),
              SlideTransition(
                position: textAnimation,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 64,
                    right: 64,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    "병원 관련 일정 관리 캘린더와 사용자의 진단 기록을 분석한 대시보드를 제공합니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              SlideTransition(
                position: imageAnimation,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 350, maxHeight: 250),
                  child: Icon(
                    Icons.medical_services,
                    size: 150,
                    color: Colors.blue.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
