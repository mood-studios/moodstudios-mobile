import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/booking_draft_provider.dart';
import '../screens/booking/booking_checkout_screen.dart';
import '../screens/bookings/payment_checkout_screen.dart';

class ResumeDraftBanner extends StatelessWidget {
  const ResumeDraftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.watch<BookingDraftProvider>().resumeInfo;
    if (info == null || !info.showBanner) return const SizedBox.shrink();

    final isPayment = info.pendingPaymentCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: AppColors.purplePale.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _continue(context, isPayment),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue where you left off',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.message,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _continue(context, isPayment),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(isPayment ? 'Pay now' : 'Checkout', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continue(BuildContext context, bool isPayment) {
    final draft = context.read<BookingDraftProvider>();
    if (isPayment) {
      final session = draft.paymentSessionFromDraft();
      if (session == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentCheckoutScreen(
            session: session,
            onComplete: () async {
              await draft.clearDraft();
            },
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingCheckoutScreen()),
    );
  }
}
