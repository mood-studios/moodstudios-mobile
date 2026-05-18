import 'package:flutter/material.dart';

/// Brand palette from mood_studios-main (index.html, login, customer pages)
class AppColors {
  static const purple = Color(0xFF960FFA);
  static const purpleDark = Color(0xFF7A0DD4);
  static const purpleLight = Color(0xFFC77DFF);
  static const purplePale = Color(0xFFF3E6FE);
  static const pink = Color(0xFFDE538D);
  static const background = Color(0xFFFAF0FA);
  static const text = Color(0xFF1A1A1A);
  static const muted = Color(0xFF666666);
  static const border = Color(0x21960FFA);
  static const white = Color(0xFFFFFFFF);

  static const gradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
