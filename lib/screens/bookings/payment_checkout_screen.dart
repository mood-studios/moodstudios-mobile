import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../services/payment_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.session,
    required this.onComplete,
  });

  final PaymentSession session;
  final VoidCallback onComplete;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  bool _confirming = false;
  bool _openedCheckout = false;

  Future<void> _openCheckout() async {
    final url = Uri.parse(widget.session.checkoutUrl!);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open payment page')),
      );
      return;
    }
    setState(() => _openedCheckout = true);
  }

  Future<void> _confirmPaid({bool testConfirm = false}) async {
    setState(() => _confirming = true);
    try {
      await context.read<PaymentService>().confirmPayment(
            widget.session.paymentId,
            testConfirm: testConfirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed! Thank you.')),
      );
      widget.onComplete();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('not completed')) {
      return 'PayMongo has not marked this as paid yet. Use "Continue to PayMongo" first, pay with a test card, then tap "I\'ve completed payment".';
    }
    return raw.replaceAll('Exception: ', '').replaceAll('DioException [bad response]: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final hasUrl = widget.session.hasCheckoutUrl;
    final canTestSkip = widget.session.isTestMode || !hasUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Complete payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.purplePale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined, size: 40, color: AppColors.purple),
                  ),
                  const SizedBox(height: 16),
                  const Text('Amount to pay', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(widget.session.amount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.purple),
                  ),
                ],
              ),
            ),
            if (widget.session.isTestMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'PayMongo TEST mode — use test cards only. No real money is charged.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ],
            if (widget.session.linkError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Checkout link unavailable: ${widget.session.linkError}',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ],
            const SizedBox(height: 20),
            if (hasUrl) ...[
              const Text(
                '1. Open PayMongo and pay (GCash, Maya, card)\n2. Return here and confirm',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openCheckout,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Continue to PayMongo'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _confirming ? null : () => _confirmPaid(),
                  child: Text(_confirming ? 'Confirming...' : "I've completed payment"),
                ),
              ),
            ],
            if (canTestSkip) ...[
              if (hasUrl) const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _confirming ? null : () => _confirmPaid(testConfirm: true),
                  child: Text(_confirming ? 'Please wait...' : 'Skip — mark as paid (test only)'),
                ),
              ),
            ],
            const Spacer(),
            ExpansionTile(
              title: const Text('Test card numbers', style: TextStyle(fontSize: 13)),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: SelectableText(
                    'Visa (success): 4343 4343 4343 4345\n'
                    'Expiry: any future date\n'
                    'CVC: any 3 digits\n\n'
                    'See: developers.paymongo.com/docs/testing',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
