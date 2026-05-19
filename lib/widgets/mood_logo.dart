import 'package:flutter/material.dart';

class MoodLogo extends StatelessWidget {
  const MoodLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.14),
      child: Image.asset(
        'assets/images/mood_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
