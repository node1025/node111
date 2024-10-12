import 'package:flutter/material.dart';

// ResultScreen: 선택된 카테고리의 용어를 표시하는 화면
class ResultScreen extends StatelessWidget {
  final String category;

  // 생성자: 선택된 카테고리를 매개변수로 받음
  const ResultScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱 바: 선택된 카테고리 이름을 제목으로 표시
      appBar: AppBar(
        title: Text('$category 용어'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 선택된 카테고리 이름 표시
            Text('선택된 카테고리: $category'),
            const SizedBox(height: 20),
            // 메인 화면으로 돌아가는 버튼
            ElevatedButton(
              onPressed: () {
                // 네비게이션 스택에서 루트 경로('/')까지 모든 화면을 제거하고 메인 화면으로 이동
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: const Text('메인 화면으로'),
            ),
          ],
        ),
      ),
    );
  }
}
