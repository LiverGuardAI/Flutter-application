import 'package:flutter/material.dart';

class TopBackSkipView extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onBackClick;
  final VoidCallback onSkipClick;

  const TopBackSkipView({
    super.key,
    required this.animationController,
    required this.onBackClick,
    required this.onSkipClick,
  });

  @override
  Widget build(BuildContext context) {
    final animation =
        Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.0, 0.2, curve: Curves.fastOutSlowIn),
      ),
    );

    final skipAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(2, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: animation,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: onBackClick,
            ),
            SlideTransition(
              position: skipAnimation,
              child: IconButton(
                icon: Text(
                  "건너뛰기",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: onSkipClick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
