import 'package:flutter/material.dart';

class WelcomeHealthView extends StatelessWidget {
  final AnimationController animationController;

  const WelcomeHealthView({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );

    return SlideTransition(
      position: firstHalfAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 64,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 120, color: Colors.red.shade400),
            SizedBox(height: 30),
            Text(
              "당신의 건강을 더 가깝게",
              style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 64, right: 64),
              child: Text(
                "지금 바로 LiverGuard와 함께 건강을 관리해보세요.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
