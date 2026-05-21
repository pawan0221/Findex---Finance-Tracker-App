import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get darkTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F1628),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B6AFF),
      secondary: Color(0xFF64B5F6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1628),
      elevation: 0,
      centerTitle: true,
    ),
  );

  ThemeData get lightTheme => ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B6AFF),
      secondary: Color(0xFF64B5F6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F6FA),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF0F1628)),
      titleTextStyle: TextStyle(color: Color(0xFF0F1628), fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
}