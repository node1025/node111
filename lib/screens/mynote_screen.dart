import 'package:flutter/material.dart';
import 'package:bovo/utils/favorite_utils.dart';
import 'package:bovo/utils/wrong_answer_utils.dart';

class MyNoteScreen extends StatefulWidget {
  const MyNoteScreen({Key? key}) : super(key: key);

  @override
  _MyNoteScreenState createState() => _MyNoteScreenState();
}

class _MyNoteScreenState extends State<MyNoteScreen> {
  List<String> _favoriteWords = [];
  Map<int, List<Map<String, String>>> _wrongAnswersByRound = {};
  bool _showFavorites = true;
  final WrongAnswerUtils wrongAnswerUtils = WrongAnswerUtils();

  @override
  void initState() {
    super.initState();
    _loadFavoriteWords();
    _loadWrongAnswers();
  }

  Future<void> _loadFavoriteWords() async {
    final words = await FavoriteUtils.getFavorites();
    setState(() {
      _favoriteWords = words;
    });
  }

  Future<void> _loadWrongAnswers() async {
    try {
      final wrongAnswers = await wrongAnswerUtils.getWrongAnswersByRound();
      setState(() {
        _wrongAnswersByRound = wrongAnswers;
      });
      print('로드된 오답: $_wrongAnswersByRound'); // 디버깅용 출력
    } catch (e) {
      print('오답 로드 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: 200,
          child: ToggleButtons(
            borderColor: Colors.white,
            fillColor: Colors.blue.shade700,
            borderWidth: 2,
            selectedBorderColor: Colors.white,
            selectedColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('즐겨찾기', style: TextStyle(fontSize: 14)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('오답노트', style: TextStyle(fontSize: 14)),
              ),
            ],
            onPressed: (int index) {
              setState(() {
                _showFavorites = index == 0;
              });
            },
            isSelected: [_showFavorites, !_showFavorites],
          ),
        ),
        centerTitle: true,
      ),
      body: _showFavorites ? _buildFavoritesList() : _buildWrongAnswersList(),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: _favoriteWords.length,
      itemBuilder: (context, index) {
        final word = _favoriteWords[index];
        return ListTile(
          title: Text(word),
          trailing: IconButton(
            icon: Icon(Icons.star, color: Colors.yellow),
            onPressed: () async {
              await FavoriteUtils.toggleFavorite(word);
              await _loadFavoriteWords();
            },
          ),
        );
      },
    );
  }

  Widget _buildWrongAnswersList() {
    if (_wrongAnswersByRound.isEmpty) {
      return Center(child: Text('오답이 없습니다.'));
    }

    List<int> rounds = _wrongAnswersByRound.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        int round = rounds[index];
        List<Map<String, String>> wrongAnswers = _wrongAnswersByRound[round]!;
        return ExpansionTile(
          title: Text('회차 $round'),
          children: wrongAnswers
              .map((wrongAnswer) => ListTile(
                    title: Text(wrongAnswer['word'] ?? ''),
                    subtitle: Text(wrongAnswer['definition'] ?? ''),
                  ))
              .toList(),
        );
      },
    );
  }
}
