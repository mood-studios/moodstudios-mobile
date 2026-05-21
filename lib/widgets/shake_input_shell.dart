import 'dart:math';

import 'package:flutter/material.dart';

/// Red border + horizontal shake when [shakeTick] changes and [hasError] is true.
class ShakeInputShell extends StatefulWidget {
  const ShakeInputShell({
    super.key,
    required this.child,
    required this.hasError,
    this.shakeTick = 0,
  });

  final Widget child;
  final bool hasError;
  final int shakeTick;

  @override
  State<ShakeInputShell> createState() => _ShakeInputShellState();
}

class _ShakeInputShellState extends State<ShakeInputShell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(ShakeInputShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTick != oldWidget.shakeTick && widget.hasError) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final offset = sin(t * pi * 6) * 8 * (1 - t);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Container(
            decoration: widget.hasError
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade700, width: 1.5),
                  )
                : null,
            padding: widget.hasError ? const EdgeInsets.all(2) : EdgeInsets.zero,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
