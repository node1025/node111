import 'package:flutter/material.dart';
import '../word_data.dart';
import '../utils/wrong_answer_utils.dart'; // 오답 노트 유틸리티 추가
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// 선택된 카테고리의 단어를 플래시 카드 형식으로 학습하는 화면
class FlashCardScreen extends StatefulWidget {
  final String category;

  const FlashCardScreen({super.key, required this.category});

  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  List<Map<String, dynamic>> categoryWords = [];
  List<Map<String, dynamic>> quizWords = [];
  List<Map<String, dynamic>> originalQuizWords = []; // 원래 선택된 10개 단어 저장
  bool isLoading = true;
  int currentIndex = 0;
  bool showDefinition = false;
  bool isQuizMode = false;
  bool isAnswered = false;
  bool isCorrect = false;
  bool isShuffled = false;
  List<Map<String, dynamic>> correctAnswers = [];
  List<Map<String, dynamic>> incorrectAnswers = [];
  int score = 0;
  String displayedWord = '';
  String displayedMeaning = '';
  List<Map<String, dynamic>> currentWordSet = []; // 현재 학습 중인 단어 세트

  final Color primaryColor = const Color(0xFF9575CD);
  final Color accentColor = const Color(0xFFD1C4E9);

  final WrongAnswerUtils wrongAnswerUtils = WrongAnswerUtils();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  // 단어 데이터 로드 및 초기화
  Future<void> _loadWords() async {
    setState(() {
      isLoading = true;
    });

    await WordData.loadWords();
    categoryWords = WordData.getWordsByCategory(widget.category);
    quizWords = _getRandomWords();
    originalQuizWords = List.from(quizWords);
    currentWordSet = _getRandomWords();

    setState(() {
      isLoading = false;
    });
  }

  // 랜덤으로 10개의 단어 선택
  List<Map<String, dynamic>> _getRandomWords() {
    final random = Random();
    final tempList = List<Map<String, dynamic>>.from(categoryWords);
    tempList.shuffle(random);
    return tempList.take(10).toList();
  }

  // 다음 카드로 이동
  void _nextCard() {
    setState(() {
      if (currentIndex < quizWords.length - 1) {
        currentIndex++;
        showDefinition = false;
        if (isQuizMode) {
          isAnswered = false;
          _shuffleWordAndMeaning();
        }
      } else {
        if (isQuizMode) {
          _showQuizResult();
        } else {
          _showCompletionScreen();
        }
      }
    });
  }

  // 이전 카드로 이동
  void _previousCard() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      } else {
        currentIndex = 0;
      }
      showDefinition = false;
    });
  }

  // 단어 정의 표시/숨김 토글
  void _toggleDefinition() {
    setState(() {
      showDefinition = !showDefinition;
    });
  }

  // 학습 완료 화면 표시
  void _showCompletionScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('수고하셨습니다!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetToFirstWord();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                child: Text('다시 학습하기'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startQuiz();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                child: Text('퀴즈 시작하기'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 첫 번째 단어로 리셋
  void _resetToFirstWord() {
    setState(() {
      currentIndex = 0;
      showDefinition = false;
      isQuizMode = false;
    });
  }

  // 퀴즈 모드 시작
  void _startQuiz() {
    setState(() {
      isQuizMode = true;
      currentIndex = 0;
      score = 0;
      isAnswered = false;
      _shuffleWordAndMeaning();
    });
  }

  // 퀴즈 모드에서 단어와 뜻을 섞음
  void _shuffleWordAndMeaning() {
    final wordPair = quizWords[currentIndex];
    final random = Random();

    List<String> incorrectMeanings = quizWords
        .where((w) => (w['word'] as String) != (wordPair['word'] as String))
        .map((w) => w['definition'] as String)
        .toList();
    displayedWord = wordPair['word'] as String;

    if (random.nextBool()) {
      // 올바른 의미 표시
      displayedMeaning = wordPair['definition'] as String;
      isShuffled = false;
    } else {
      // 잘못된 의미 표시
      displayedMeaning =
          incorrectMeanings[random.nextInt(incorrectMeanings.length)];
      isShuffled = true;
    }
  }

  // 퀴즈 답변 확인
  Future<void> _checkAnswer(bool userAnswer) async {
    setState(() {
      isAnswered = true;
      isCorrect = (userAnswer == isShuffled);
      if (isCorrect) {
        score += 10;
        correctAnswers.add(quizWords[currentIndex]);
      } else {
        print('오답 추가 전: ${quizWords[currentIndex]}');
        incorrectAnswers.add({
          'word': quizWords[currentIndex]['word'].toString(),
          'definition': quizWords[currentIndex]['definition'].toString()
        });
        print('오답 추가 후: ${incorrectAnswers.last}');
        _saveWrongAnswer(incorrectAnswers.last);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), _nextCard);
  }

  // 오답을 오답 노트에 저장
  Future<void> _saveWrongAnswer(Map<String, dynamic> word) async {
    try {
      print('오답 저장 시도: $word');
      String wordString = word['word'] is List ? word['word'][0] : word['word'];
      String definitionString = word['definition'] is List
          ? word['definition'][0]
          : word['definition'];
      await wrongAnswerUtils.addWrongAnswer(
        {'word': wordString, 'definition': definitionString},
        DateTime.now().millisecondsSinceEpoch,
      );
      print('오답 저장 성공');
    } catch (e) {
      print('오답 저장 중 오류 발생: $e');
    }
  }

  // 퀴즈 결과 화면 표시
  Future<void> _showQuizResult() async {
    // 오답 저장을 기다립니다.
    await _saveToWrongAnswerNote();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('퀴즈 결과', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('정답: ${correctAnswers.length}'),
                Text('오답: ${incorrectAnswers.length}'),
                SizedBox(height: 10),
                Text('틀린 단어들이 오답 노트에 저장되었습니다.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
                // ... 기타 결과 표시 ...
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetToLearningMode();
              },
            ),
          ],
        );
      },
    );
  }

  // 오답 노트에 저장
  Future<void> _saveToWrongAnswerNote() async {
    print('오답 노트 저장 시작');
    final WrongAnswerUtils wrongAnswerUtils = WrongAnswerUtils();
    for (var word in incorrectAnswers) {
      try {
        print('단어 저장 시도: $word');
        print('word 타입: ${word.runtimeType}');
        print('word["word"] 타입: ${word["word"].runtimeType}');
        print('word["definition"] 타입: ${word["definition"].runtimeType}');

        String wordString = word['word'].toString();
        String definitionString = word['definition'].toString();

        print('변환된 wordString: $wordString');
        print('변환된 definitionString: $definitionString');

        await wrongAnswerUtils.addWrongAnswer(
          {'word': wordString, 'definition': definitionString},
          DateTime.now().millisecondsSinceEpoch,
        );
        print('단어 저장 성공');
      } catch (e) {
        print('단어 저장 중 오류 발생: $e');
        print('오류 발생 시 word: $word');
      }
    }
    print('오답 노트 저장 완료');
  }

  // 오답 노트에 저장 완료 다이얼로그
  void _showSavedToWrongAnswerNoteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('저장 완료'),
          content: Text('틀린 단어들이 오답 노트에 저장되었습니다.'),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetToLearningMode();
              },
            ),
          ],
        );
      },
    );
  }

  // 학습 모드로 리셋
  void _resetToLearningMode() {
    setState(() {
      currentIndex = 0;
      showDefinition = false;
      isQuizMode = false;
      isAnswered = false;
      isCorrect = false;
      isShuffled = false;
      score = 0;
    });
  }

  Future<String?> _getWrongAnswersString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _loadWords();
        return true;
      },
      child: Scaffold(
        backgroundColor: accentColor,
        appBar: AppBar(
          title: Text('#${widget.category}'),
          backgroundColor: primaryColor,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${currentIndex + 1} / ${quizWords.length}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : quizWords.isEmpty
                    ? Center(child: Text('단어를 불러오는 중 오류가 발생했습니다.'))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 학습 모드 UI
                          if (!isQuizMode) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: _toggleDefinition,
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentIndex < quizWords.length
                                                ? quizWords[currentIndex]
                                                        ['word'] ??
                                                    '단어 없음'
                                                : '단어 없음',
                                            style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          if (showDefinition)
                                            Text(
                                              currentIndex < quizWords.length
                                                  ? quizWords[currentIndex]
                                                          ['definition'] ??
                                                      '정의 없음'
                                                  : '정의 없음',
                                              style:
                                                  const TextStyle(fontSize: 24),
                                              textAlign: TextAlign.center,
                                            )
                                          else
                                            const Text(
                                              '터치하여 뜻 보기',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]
                          // 퀴즈 모드 UI (답변 전)
                          else if (!isAnswered) ...[
                            Text(
                              displayedWord,
                              style: const TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                displayedMeaning,
                                style: const TextStyle(fontSize: 24),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _checkAnswer(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(24),
                                  ),
                                  child:
                                      Text('O', style: TextStyle(fontSize: 36)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _checkAnswer(false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(24),
                                  ),
                                  child:
                                      Text('X', style: TextStyle(fontSize: 36)),
                                ),
                              ],
                            ),
                          ]
                          // 퀴즈 모드 UI (답변 후)
                          else ...[
                            Text(
                              isCorrect ? '정답입니다!' : '오답입니다!',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (!isQuizMode)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentIndex = 0;
                                      showDefinition = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: Icon(Icons.arrow_back),
                                ),
                                ElevatedButton(
                                  onPressed: _nextCard,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: Icon(Icons.arrow_forward),
                                ),
                              ],
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
