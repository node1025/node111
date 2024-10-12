import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'main_screen.dart';
import 'search_screen.dart';
import 'flash_card_start_screen.dart';
import 'package:bovo/services/favorite_words_service.dart';
import 'package:bovo/utils/favorite_utils.dart';

// WordListScreen 위젯: 단어 목록을 표시하는 화면
class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  _WordListScreenState createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAlphabetList = false;
  String? _pressedLetter;
  Timer? _hideTimer;

  // 초성별로 그룹화된 단어 목록
  Map<String, List<Map<String, String>>> groupedWords = {};
  // 한글 초성 목록
  final List<String> _alphabet = [
    'ㄱ',
    'ㄴ',
    'ㄷ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅅ',
    'ㅇ',
    'ㅈ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ'
  ];

  // 각 그룹의 시작 위치를 저장하는 맵
  final Map<String, double> _letterPositions = {};

  final Map<String, GlobalKey> _letterKeys = {};

  final Map<String, double> _letterOffsets = {};

  final Set<String> _favorites = <String>{};

  final FavoriteWordsService _favoriteWordsService = FavoriteWordsService();
  List<String> _favoriteWords = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadWords();
    for (var letter in _alphabet) {
      _letterKeys[letter] = GlobalKey();
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _calculateLetterOffsets());
    _loadFavoriteWords();
  }

  Future<void> _loadFavoriteWords() async {
    final words = await FavoriteUtils.getFavorites();
    setState(() {
      _favoriteWords = words;
    });
  }

  // JSON 파일에서 단어 데이터를 로드하는 메서드
  Future<void> _loadWords() async {
    try {
      String jsonString = await rootBundle.loadString('assets/words.json');
      Map<String, dynamic> jsonResponse = json.decode(jsonString);
      List<Map<String, String>> allWords = [];

      // JSON 데이터에서 단어와 정의를 추출
      jsonResponse['categories'].forEach((category) {
        category['words'].forEach((word) {
          allWords.add({
            'word': word['word'],
            'definition': word['definition'],
          });
        });
      });

      // 단어를 알파벳 순으로 정렬
      allWords.sort((a, b) => a['word']!.compareTo(b['word']!));

      setState(() {
        // 초성별로 단어 그룹화
        groupedWords = _groupWordsByInitial(allWords);
      });
      print('단어 로드 완료: ${groupedWords.length} 그룹, ${allWords.length} 단어');
    } catch (e) {
      print('단어 로드 중 오류 발생: $e');
    }
  }

  // 단어를 초성별로 그룹화하는 메서드
  Map<String, List<Map<String, String>>> _groupWordsByInitial(
      List<Map<String, String>> words) {
    Map<String, List<Map<String, String>>> grouped = {};
    for (var word in words) {
      String initial = _getInitialConsonant(word['word']!);
      if (!grouped.containsKey(initial)) {
        grouped[initial] = [];
      }
      grouped[initial]!.add(word);
    }
    return grouped;
  }

  // 단어의 초성을 반환하는 메서드
  String _getInitialConsonant(String word) {
    final initialConsonants = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ'
    ];
    if (word.isEmpty) return 'ㄱ';
    int code = word.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      int index = ((code - 0xAC00) ~/ 28 ~/ 21);
      return initialConsonants[index];
    } else {
      return 'ㄱ';
    }
  }

  // 스크롤 이벤트 리스너
  void _scrollListener() {
    setState(() {
      _showAlphabetList = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAlphabetList = false;
        });
      }
    });
  }

  // 특정 초성으로 스크롤하는 메서드
  void _scrollToLetter(String letter) {
    if (_letterOffsets.containsKey(letter)) {
      double offset = _letterOffsets[letter]! -
          MediaQuery.of(context).padding.top -
          kToolbarHeight;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      _showAlphabetList = true;
      _pressedLetter = letter;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAlphabetList = false;
          _pressedLetter = null;
        });
      }
    });
  }

  // 각 그룹의 시작 위치를 계산하는 메서드
  void _calculateLetterPositions() {
    double currentPosition = 0;
    for (String letter in groupedWords.keys) {
      _letterPositions[letter] = currentPosition;
      // 그룹 헤더의 높이 (예: 40)와 각 단어 항목의 높이 (예: 60)를 고려하여 계산
      currentPosition += 40 + (groupedWords[letter]?.length ?? 0) * 60;
    }
  }

  void _calculateLetterOffsets() {
    for (String letter in _alphabet) {
      final RenderObject? renderObject =
          _letterKeys[letter]?.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        final position = renderObject.localToGlobal(Offset.zero);
        _letterOffsets[letter] = position.dy;
      }
    }
  }

  void _toggleFavorite(String word) {
    setState(() {
      if (_favorites.contains(word)) {
        _favorites.remove(word);
      } else {
        _favorites.add(word);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 목록', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8A7FBA),
        elevation: 0,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            _calculateLetterOffsets();
          }
          return true;
        },
        child: Container(
          color: const Color(0xFFF0F0FF),
          child: Stack(
            children: [
              // 단어 목록을 표시하는 ListView
              ListView.builder(
                controller: _scrollController,
                itemCount: _alphabet.length,
                itemBuilder: (context, index) {
                  final letter = _alphabet[index];
                  final words = groupedWords[letter] ?? [];
                  return Column(
                    key: _letterKeys[letter],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 초성 헤더 (항상 표시)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        color: const Color(0xFFD5D1EE),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF5D4777),
                          ),
                        ),
                      ),
                      // 단어 목록 (단어가 있는 경우에만 표시)
                      if (words.isNotEmpty)
                        ...words.map((word) => ExpansionTile(
                              title: Text(word['word']!),
                              trailing: IconButton(
                                icon: Icon(
                                  _favoriteWords.contains(word['word'])
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: _favoriteWords.contains(word['word'])
                                      ? Colors.yellow
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  await FavoriteUtils.toggleFavorite(
                                      word['word']!);
                                  await _loadFavoriteWords();
                                },
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    word['definition']!,
                                    style: const TextStyle(
                                        color: Color(0xFF6A5495)),
                                  ),
                                ),
                              ],
                            )),
                    ],
                  );
                },
              ),
              // 초성 빠른 이동 리스트
              if (_showAlphabetList)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3ADE0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView(
                      children: _alphabet
                          .map((letter) => GestureDetector(
                                onTap: () => _scrollToLetter(letter),
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _pressedLetter == letter
                                        ? const Color(0xFF8A7FBA)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color: _pressedLetter == letter
                                          ? Colors.white
                                          : Color(0xFF6A5495),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        backgroundColor: const Color(0xFF8A7FBA),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFD5D1EE),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '단어찾기'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '오늘단어'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '단어목록'),
        ],
        onTap: (index) {
          if (index != 3) {
            Widget screen;
            switch (index) {
              case 0:
                screen = MainScreen();
                break;
              case 1:
                screen = const SearchScreen();
                break;
              case 2:
                screen = FlashCardStartScreen();
                break;
              default:
                return;
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => screen),
              (Route<dynamic> route) => false,
            );
          }
        },
      ),
    );
  }
}

// CustomExpansionTile 위젯: 확장 가능한 단어 타일
class CustomExpansionTile extends StatelessWidget {
  final String word;
  final String definition;
  final bool isExpanded;
  final bool isFavorite;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onFavoriteChanged;

  const CustomExpansionTile({
    super.key,
    required this.word,
    required this.definition,
    required this.isExpanded,
    required this.isFavorite,
    required this.onExpansionChanged,
    required this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              word,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4777),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: onFavoriteChanged,
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF8A7FBA),
                ),
              ],
            ),
            onTap: () => onExpansionChanged(!isExpanded),
          ),
          if (isExpanded)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                definition,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6A5495)),
              ),
            ),
        ],
      ),
    );
  }
}
