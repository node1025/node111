import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WrongAnswerUtils {
  static const String _key = 'wrong_answers';

  Future<void> addWrongAnswer(Map<String, String> word, int round) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> wrongAnswers = await _getWrongAnswersMap(prefs);

    String roundKey = 'round_$round';
    if (!wrongAnswers.containsKey(roundKey)) {
      wrongAnswers[roundKey] = [];
    }
    wrongAnswers[roundKey]!.add(json.encode(word));

    String encodedData = json.encode(wrongAnswers);
    print('저장할 데이터: $encodedData'); // 디버깅용 출력
    await prefs.setString(_key, encodedData);
  }

  Future<Map<int, List<Map<String, String>>>> getWrongAnswersByRound() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> wrongAnswers = await _getWrongAnswersMap(prefs);

    Map<int, List<Map<String, String>>> result = {};
    wrongAnswers.forEach((key, value) {
      int round = int.parse(key.split('_')[1]);
      result[round] =
          value.map((e) => Map<String, String>.from(json.decode(e))).toList();
    });

    return result;
  }

  Future<Map<String, List<String>>> _getWrongAnswersMap(
      SharedPreferences prefs) async {
    String? wrongAnswersString = prefs.getString(_key);
    print('저장된 데이터: $wrongAnswersString'); // 디버깅용 출력
    print('저장된 데이터 타입: ${wrongAnswersString.runtimeType}');

    if (wrongAnswersString != null) {
      Map<String, dynamic> decodedMap = jsonDecode(wrongAnswersString);
      print(
          '디코딩된 맵의 값 타입: ${decodedMap.values.map((v) => v.runtimeType).toSet()}');
    } else {
      print('wrongAnswersString이 null입니다.');
    }

    if (wrongAnswersString != null && wrongAnswersString.isNotEmpty) {
      try {
        Map<String, dynamic> decodedMap = json.decode(wrongAnswersString);
        print('디코딩된 맵: $decodedMap'); // 디버깅용 출력

        Map<String, List<String>> result = {};
        decodedMap.forEach((key, value) {
          print('키: $key, 값: $value'); // 디버깅용 출력
          if (value is List) {
            result[key] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            result[key] = [value];
          } else {
            result[key] = [];
          }
        });

        return result;
      } catch (e) {
        print('오류 발생: $e'); // 디버깅용 출력
        return {};
      }
    }
    return {};
  }

  Future<void> clearWrongAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
