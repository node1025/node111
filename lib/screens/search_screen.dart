import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bovo/word_data.dart';
import 'main_screen.dart';
import 'word_detail_screen.dart';
import 'flash_card_start_screen.dart';
import 'word_list_screen.dart';
import 'package:bovo/utils/favorite_utils.dart';
import 'dart:developer' as developer;

// SearchScreen: 단어 검색 기능을 제공하는 화면
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allWords = [];
  List<Map<String, dynamic>> _filteredWords = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _loadWords();
    _loadRecentSearches();
    _loadFavorites(); // 즐겨찾기 목록 로드
  }

  // 모든 단어 데이터 로드
  Future<void> _loadWords() async {
    await WordData.loadWords();
    setState(() {
      _allWords = WordData.getAllWords();
    });
  }

  // 최근 검색어 로드
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  // 최근 검색어 저장 (최대 3개)
  Future<void> _saveRecentSearch(String search) async {
    if (!_recentSearches.contains(search)) {
      _recentSearches.insert(0, search);
      if (_recentSearches.length > 3) {
        _recentSearches.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentSearches', _recentSearches);
    }
  }

  // 검색어에 따라 단어 필터링
  void _filterSearchResults(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        // 검색 결과를 필터링하고 중복 제거
        var tempList = _allWords
            .where((word) =>
                word['word']!.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // 중복 제거
        _filteredWords = [];
        Set<String> uniqueWords = {};
        for (var word in tempList) {
          if (!uniqueWords.contains(word['word'])) {
            _filteredWords.add(word);
            uniqueWords.add(word['word'] as String);
          }
        }
      } else {
        _filteredWords = [];
      }
    });
  }

  // 검색 결과 위젯 생성
  Widget _buildSearchResults() {
    if (_filteredWords.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(fontSize: 16, color: Color(0xFF5D4777)),
        ),
      );
    }
    return ListView.separated(
      itemCount: _filteredWords.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFFD1C4E9),
        height: 1,
      ),
      itemBuilder: (context, index) {
        return _buildWordListItem(_filteredWords[index]);
      },
    );
  }

  // 단어 목록 아이템 빌더
  Widget _buildWordListItem(Map<String, dynamic> word) {
    String wordText = word['word'] as String;
    String definition = word['definition'] as String;
    final query = _searchController.text.toLowerCase();
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            ListTile(
              title: RichText(
                text: TextSpan(
                  style:
                      const TextStyle(color: Color(0xFF5D4777), fontSize: 16),
                  children: _buildTextSpans(wordText, query),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _favorites.contains(wordText)
                          ? Icons.star
                          : Icons.star_border,
                      color: _favorites.contains(wordText)
                          ? Colors.amber
                          : const Color(0xFF8A7FBA),
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(wordText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: const Color(0xFF8A7FBA),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  ),
                ],
              ),
              onTap: () {
                _saveRecentSearch(wordText);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordDetailScreen(word: word),
                  ),
                );
              },
            ),
            if (isExpanded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  definition,
                  style:
                      const TextStyle(color: Color(0xFF8A7FBA), fontSize: 14),
                ),
              ),
          ],
        );
      },
    );
  }

  // 검색어 하이라이트를 위한 TextSpan 생성
  List<TextSpan> _buildTextSpans(String text, String query) {
    List<TextSpan> spans = [];
    int start = 0;
    final matches = query.allMatches(text.toLowerCase());
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF8A7FBA)),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  // 최근 검색어 목록 위젯 생성
  Widget _buildRecentSearches() {
    return _recentSearches.isEmpty
        ? _buildLogoSection()
        : ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(_recentSearches[index]),
                onTap: () {
                  _searchController.text = _recentSearches[index];
                  _filterSearchResults(_recentSearches[index]);
                },
              );
            },
          );
  }

  // 로고 섹션 위젯 생성
  Widget _buildLogoSection() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BOVO',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A7FBA),
            ),
          ),
        ],
      ),
    );
  }

  // 검색어 초기화
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _filteredWords = [];
    });
  }

  // 즐겨찾기 목록 로드
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);
    });
  }

  // 즐겨찾기 토글
  Future<void> _toggleFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_favorites.contains(word)) {
        _favorites.remove(word);
      } else {
        _favorites.add(word);
      }
    });

    await prefs.setStringList('favorites', _favorites.toList());

    // 단어장에 즐겨찾기 단어 추가 또는 제거
    List<String> wordbook = prefs.getStringList('wordbook') ?? [];
    if (_favorites.contains(word)) {
      if (!wordbook.contains(word)) {
        wordbook.add(word);
      }
    } else {
      wordbook.remove(word);
    }
    await prefs.setStringList('wordbook', wordbook);

    // 디버그 출력
    print('즐겨찾기: $_favorites');
    print('단어장: $wordbook');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _clearSearch();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _clearSearch();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          title: const Text('단어 찾기', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF8A7FBA),
          elevation: 0,
        ),
        body: Container(
          color: const Color(0xFFF0F0FF),
          child: Column(
            children: [
              // 검색 입력 필드
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색어를 입력하세요',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF8A7FBA)),
                      onPressed: () {
                        _filterSearchResults(_searchController.text);
                      },
                    ),
                  ),
                  onChanged: _filterSearchResults,
                  onSubmitted: (value) {
                    _filterSearchResults(value);
                  },
                ),
              ),
              // 최근 검색어가 없을 때 메시지 표시
              if (_recentSearches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '최근 검색어가 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF5D4777),
                      fontSize: 16,
                    ),
                  ),
                ),
              // 검색 결과 또는 최근 검색어 목록 표시
              Expanded(
                child: _isSearching
                    ? _buildSearchResults()
                    : _buildRecentSearches(),
              ),
            ],
          ),
        ),
        // 하단 네비게이션 바
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF8A7FBA),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFFD5D1EE),
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '단어찾기'),
            BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '오늘단어'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: '단어목록'),
          ],
          onTap: (index) {
            if (index != 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    switch (index) {
                      case 0:
                        return MainScreen();
                      case 2:
                        return FlashCardStartScreen();
                      case 3:
                        return const WordListScreen();
                      default:
                        return const SearchScreen();
                    }
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
