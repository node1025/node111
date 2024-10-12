import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'word_list_screen.dart';
import 'flash_card_start_screen.dart';
import 'mynote_screen.dart'; // MyNoteScreen을 import

// MainScreen: 앱의 메인 화면을 구성하는 위젯
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱 바: 앱 제목 표시
      appBar: AppBar(
        title: const Text('BOVO', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8A7FBA),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF0F0FF), // 배경색 설정
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // '단어 찾기' 버튼
                _buildLargeButton(
                  context,
                  icon: Icons.search,
                  label: '단어 찾기',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                // '오늘 단어' 버튼
                _buildLargeButton(
                  context,
                  icon: Icons.flash_on,
                  label: '오늘 단어',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FlashCardStartScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                // '단어 목록' 버튼
                _buildLargeButton(
                  context,
                  icon: Icons.book,
                  label: '단어 목록',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WordListScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                // '단어장' 버튼
                _buildLargeButton(
                  context,
                  icon: Icons.favorite,
                  label: '단어장',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyNoteScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 큰 버튼을 생성하는 헬퍼 메서드
  Widget _buildLargeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 30, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8A7FBA), // 버튼 배경색 설정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게 설정
          ),
          elevation: 5, // 버튼에 그림자 효과 추가
        ),
      ),
    );
  }
}
