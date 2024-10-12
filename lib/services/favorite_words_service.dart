import 'package:shared_preferences/shared_preferences.dart';

class FavoriteWordsService {
  static const String _key = 'favorite_words';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<String>> getFavoriteWords() async {
    if (_prefs == null) await init();
    try {
      return _prefs?.getStringList(_key) ?? [];
    } catch (e) {
      print('즐겨찾기 단어 가져오기 오류: $e');
      return [];
    }
  }

  Future<void> addFavoriteWord(String word) async {
    if (_prefs == null) await init();
    try {
      final favorites = await getFavoriteWords();
      if (!favorites.contains(word)) {
        favorites.add(word);
        await _prefs?.setStringList(_key, favorites);
      }
    } catch (e) {
      print('즐겨찾기 단어 추가 오류: $e');
    }
  }

  Future<void> removeFavoriteWord(String word) async {
    if (_prefs == null) await init();
    try {
      final favorites = await getFavoriteWords();
      favorites.remove(word);
      await _prefs?.setStringList(_key, favorites);
    } catch (e) {
      print('즐겨찾기 단어 제거 오류: $e');
    }
  }

  Future<void> saveFavoriteWords(List<String> words) async {
    if (_prefs == null) await init();
    try {
      await _prefs?.setStringList(_key, words);
    } catch (e) {
      print('즐겨찾기 단어 저장 오류: $e');
    }
  }
}
