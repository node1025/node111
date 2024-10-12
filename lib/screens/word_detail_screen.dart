import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'word_list_screen.dart';

// WordDetailScreen: 단어의 상세 정보를 표시하는 화면
class WordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> word; // 단어 정보를 담은 Map

  const WordDetailScreen({Key? key, required this.word}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(word['word'] ?? ''),
        backgroundColor: const Color(0xFF8A7FBA),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word['word'] ?? '',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: const Color(0xFF5D4777)),
              ),
              const SizedBox(height: 16),
              Text(
                '정의:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8A7FBA)),
              ),
              Text(
                word['definition'] ?? '',
                style: TextStyle(color: const Color(0xFF5D4777)),
              ),
              const SizedBox(height: 16),
              if (word['example1']?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '예문 1:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A7FBA)),
                    ),
                    Text(
                      word['example1'] ?? '',
                      style: TextStyle(color: const Color(0xFF5D4777)),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (word['example2']?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '예문 2:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A7FBA)),
                    ),
                    Text(
                      word['example2'] ?? '',
                      style: TextStyle(color: const Color(0xFF5D4777)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // 하단 네비게이션 바 구축 메서드
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF8A7FBA),
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFFD5D1EE),
      currentIndex: 1, // '단어찾기' 탭이 선택된 상태
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: '단어찾기'),
        BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '오늘단어'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: '단어목록'),
      ],
      onTap: (index) {
        Widget screen;
        // 선택된 탭에 따라 화면 전환
        switch (index) {
          case 0:
            screen = MainScreen();
            break;
          case 1:
            screen = const SearchScreen();
            break;
          case 3:
            screen = const WordListScreen();
            break;
          default:
            return;
        }
        // 새로운 화면으로 이동하고 이전 화면들을 모두 제거
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => screen),
          (Route<dynamic> route) => false,
        );
      },
    );
  }
}
