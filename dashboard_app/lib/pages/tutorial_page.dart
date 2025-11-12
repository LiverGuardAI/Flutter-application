import 'package:flutter/material.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _titles = [
    "정확한 간 진단을 위해",
    "혈액검사 결과를 한 눈에",
    "약물 상호작용을 안전하게",
    "당신의 건강을 더 가깝게",
  ];

  final List<String> _descriptions = [
    "CT, MRI, 초음파 데이터를 기반으로 더 나은 조기 진단을 제공합니다.",
    "간 수치 변화를 쉽게 확인하고 의사결정에 도움을 줍니다.",
    "약물 부작용을 미리 예측하고 안전한 처방을 도와줍니다.",
    "지금 바로 LiverGuard와 함께 건강을 관리해보세요.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PageView (슬라이드 4개)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 4,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildSlide(index);
                },
              ),
            ),

            const SizedBox(height: 20),

            // 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => _indicator(index == _currentPage),
              ),
            ),

            const SizedBox(height: 30),

            // 마지막 슬라이드에만 “시작하기”
            _currentPage == 3
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/main');
                        },
                        child: const Text("시작하기"),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: TextButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text("다음 →"),
                    ),
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ 각 슬라이드 구성
  Widget _buildSlide(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ 이미지 자리(나중에 실제 이미지 넣을 수 있음)
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.health_and_safety,
              size: 100,
              color: Colors.blue.shade400,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            _titles[index],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Text(
            _descriptions[index],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ✅ 인디케이터
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
