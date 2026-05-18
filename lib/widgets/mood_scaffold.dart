import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'mood_logo.dart';

class MoodScaffold extends StatelessWidget {
  const MoodScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBack = false,
    this.actions,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: showBack
            ? IconButton(
                icon: const MoodLogo(size: 40),
                onPressed: () => Navigator.maybePop(context),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 12),
                child: MoodLogo(size: 40),
              ),
        leadingWidth: 56,
        title: Text(
          title ?? 'Mood Studios',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
