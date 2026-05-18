import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MoodLogo extends StatelessWidget {
  const MoodLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(size * 0.14),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}
