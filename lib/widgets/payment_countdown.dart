import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Live countdown until [paymentDeadlineAt] (15-minute payment window).
class PaymentCountdown extends StatefulWidget {
  const PaymentCountdown({
    super.key,
    required this.deadline,
    this.onExpired,
    this.compact = false,
  });

  final DateTime deadline;
  final VoidCallback? onExpired;
  final bool compact;

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final left = widget.deadline.difference(DateTime.now());
    final expired = left.isNegative || left == Duration.zero;
    if (expired && _remaining > Duration.zero) {
      widget.onExpired?.call();
    }
    if (mounted) {
      setState(() => _remaining = expired ? Duration.zero : left);
    }
  }

  String get _label {
    if (_remaining <= Duration.zero) {
      return 'Payment time expired';
    }
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    final time = '${m}:${s.toString().padLeft(2, '0')}';
    return widget.compact ? time : 'Complete payment within $time';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= Duration.zero;

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: expired ? Colors.red.shade50 : AppColors.purplePale,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: expired ? Colors.red.shade300 : AppColors.purple.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: expired ? Colors.red.shade800 : AppColors.purple,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: expired ? Colors.red.shade50 : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: expired ? Colors.red.shade300 : const Color(0xFFFCD34D)),
      ),
      child: Text(
        _label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: expired ? Colors.red.shade800 : const Color(0xFF92400E),
        ),
      ),
    );
  }
}
