import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart'; // MainScreen 위젯이 있는 파일을 import 해야 합니다.
import '../word_data.dart'; // WordData import 추가

// SplashScreen: 앱 시작 시 표시되는 로딩 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  // 데이터 로딩 및 메인 화면으로 이동하는 메서드
  Future<void> _loadDataAndNavigate() async {
    await WordData.loadWords(); // 단어 데이터 로딩
    await Future.delayed(const Duration(seconds: 2)); // 최소 2초 대기

    // 메인 화면으로 이동 (이전 화면 스택에서 제거)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 배경 그라데이션 설정
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8A7FBA), Color(0xFFD5D1EE)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 컨테이너
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'BOVO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A7FBA),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 앱 설명 텍스트
              const Text(
                '사회초년생을 위한 보험용어사전',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              // 로딩 인디케이터
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
