import 'package:flutter/material.dart';
import 'package:bovo/services/favorite_words_service.dart';

class MyNoteScreen extends StatefulWidget {
  const MyNoteScreen({super.key});

  @override
  _MyNoteScreenState createState() => _MyNoteScreenState();
}

class _MyNoteScreenState extends State<MyNoteScreen> {
  final FavoriteWordsService _favoriteWordsService = FavoriteWordsService();
  List<String> _favoriteWords = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteWords();
  }

  Future<void> _loadFavoriteWords() async {
    final words = await _favoriteWordsService.getFavoriteWords();
    setState(() {
      _favoriteWords = words;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '즐겨찾기한 단어',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _favoriteWords.isEmpty
                ? const Center(
                    child: Text(
                      '즐겨찾기한 단어가 없습니다.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoriteWords.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_favoriteWords[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await _favoriteWordsService
                                .removeFavoriteWord(_favoriteWords[index]);
                            await _loadFavoriteWords();
                          },
                        ),
                        onTap: () {
                          print('${_favoriteWords[index]} 단어가 선택되었습니다.');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
