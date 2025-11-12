import 'package:flutter/material.dart';

class DrugInteractionView extends StatelessWidget {
  final AnimationController animationController;

  const DrugInteractionView({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.4, 0.6, curve: Curves.fastOutSlowIn),
          ),
        );
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );
    final textAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(-2, 0))
        .animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );
    final imageAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-4, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    final titleAnimation =
        Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.4, 0.6, curve: Curves.fastOutSlowIn),
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
                  "나에게 맞는 약물을 안전하게",
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
                    "처방 중이신 약물에 따라, 부작용을 미리 예측하고 안전한 처방을 도와줍니다.",
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
                    Icons.medication,
                    size: 150,
                    color: Colors.orange.shade400,
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
