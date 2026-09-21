import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/level_data.dart';

class LevelLoader {
  static Future<LevelData?> loadLevel(String category, int levelNumber) async {
    try {
      String fileName;
      if (category.toLowerCase() == 'easy') {
        fileName = 'Easy_Level_$levelNumber.json';
        if (levelNumber == 30) {
          // Check for lowercase 'level' in 30
          fileName = 'Easy_level_30.json';
        }
      } else if (category.toLowerCase() == 'medium') {
        fileName = 'Medium_Level_$levelNumber.json';
      } else if (category.toLowerCase() == 'hard') {
        fileName = 'Hard_Level_$levelNumber.json';
      } else {
        fileName = 'Level_$levelNumber.json';
      }

      final path = 'assets/data/levels/$fileName';
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

      return LevelData.fromJson(
        '${category}_$levelNumber',
        'Level $levelNumber ($category)',
        jsonMap,
      );
    } catch (e) {
      return null;
    }
  }

  static int getMaxLevels(String category) {
    switch (category.toLowerCase()) {
      case 'easy':
        return 30;
      case 'medium':
        return 30;
      case 'hard':
        return 40;
      default:
        return 50;
    }
  }
}
