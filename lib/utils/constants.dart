import 'package:flutter/material.dart';

class GameConstants {
  static const int boardCols = 8;
  static const int boardRows = 10;
  static const int maxVisibleRows = 9; // Row 9 is the danger/ceiling row, row 10 is game over

  // Boosters
  static const String boosterHammer = 'hammer';
  static const String boosterNet = 'net';
  static const String boosterMagnet = 'net'; // Alias for backwards compatibility
  static const String boosterWand = 'wand';

  // Colors
  static const Color woodBorder = Color(0xFF6B4226);
  static const Color boardBg = Color(0xFFE8DCC4);
  static const Color slotBg = Color(0xFFD3C2A3);
  static const Color dangerLine = Color(0xFFFF5252);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color primaryBlue = Color(0xFF29B6F6);
  static const Color goldYellow = Color(0xFFFFD54F);

  // Fonts
  static const String fontBrandon = 'BrandonText';
  static const String fontJanda = 'JandaManatee';
  static const String fontNoto = 'NotoSans';
}
