import 'package:shared_preferences/shared_preferences.dart';

class FavoriteUtils {
  static const String _key = 'favorites';

  static Future<void> toggleFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    if (favorites.contains(word)) {
      favorites.remove(word);
    } else {
      favorites.add(word);
    }

    await prefs.setStringList(_key, favorites);
    print('즐겨찾기 목록: $favorites');
  }

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
