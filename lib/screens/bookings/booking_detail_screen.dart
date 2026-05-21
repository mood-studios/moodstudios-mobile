import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../gallery/gallery_screen.dart';
import '../../widgets/payment_countdown.dart';
import 'payment_checkout_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _loading = true;
  bool _paying = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final b = await context.read<BookingService>().getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = b;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _cancel() async {
    final b = _booking;
    if (b == null || !b.canCancel) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This cannot be undone. Your booking will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep booking')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await context.read<BookingService>().cancelBooking(widget.bookingId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final msg = e is DioException && e.message != null && e.message!.isNotEmpty
            ? e.message!
            : e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final session = await context.read<PaymentService>().startPayment(widget.bookingId);
      if (!mounted) return;

      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentCheckoutScreen(
            session: session,
            onComplete: () {},
          ),
        ),
      );

      if (paid == true) {
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    }
    final b = _booking!;
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Booking Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _row('Date', DateFormat.yMMMMd().format(b.bookingDate)),
                _row('Time', b.bookingTime),
                _row('Status', b.statusLabel),
                Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text('Payment', style: TextStyle(color: AppColors.muted)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(b.paymentStatus).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.paymentStatus,
                        style: TextStyle(
                          color: _statusColor(b.paymentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                _row('Total', currency.format(b.totalAmount)),
                if (b.specialRequest != null && b.specialRequest!.isNotEmpty)
                  _row('Request', b.specialRequest!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...b.services.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(s.name),
                trailing: Text(currency.format(s.price)),
              ),
            ),
          ),
          if (b.needsPaymentCountdown) ...[
            const SizedBox(height: 12),
            PaymentCountdown(
              deadline: b.paymentDeadlineAt!,
              onExpired: _load,
            ),
          ],
          const SizedBox(height: 24),
          if (!b.isPaid && b.bookingStatus != 'declined')
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _paying ? null : _pay,
                icon: _paying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment),
                label: Text(_paying ? 'Preparing checkout...' : 'Pay now'),
              ),
            ),
          if (b.canCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                label: Text(
                  _cancelling ? 'Cancelling…' : 'Cancel booking',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                b.statusLabelKey == 'payment_pending'
                    ? 'Payment pending — checkout started but not finished. You can cancel this booking.'
                    : 'Awaiting payment — complete Pay now or cancel if you no longer need this session.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (b.canViewGallery) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GalleryScreen(bookingId: b.id)),
              ),
              icon: const Icon(Icons.photo_library),
              label: const Text('View gallery'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.muted))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
