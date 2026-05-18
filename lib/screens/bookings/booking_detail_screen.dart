import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../gallery/gallery_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final b = await context.read<BookingService>().getBooking(widget.bookingId);
      if (mounted) setState(() {
        _booking = b;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final result = await context.read<BookingService>().createPayment(widget.bookingId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment initiated'),
          content: Text(
            'Use PayMongo client key in production.\n\nIntent: ${result['paymentIntentId'] ?? 'mock'}',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    }
    final b = _booking!;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row('Date', DateFormat.yMMMMd().format(b.bookingDate)),
          _row('Time', b.bookingTime),
          _row('Status', b.bookingStatus),
          _row('Payment', b.paymentStatus),
          _row('Total', '₱${b.totalAmount.toStringAsFixed(0)}'),
          if (b.specialRequest != null && b.specialRequest!.isNotEmpty) _row('Request', b.specialRequest!),
          const SizedBox(height: 16),
          const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
          ...b.services.map((s) => ListTile(title: Text(s.name), trailing: Text('₱${s.price.toStringAsFixed(0)}'))),
          const SizedBox(height: 24),
          if (!b.isPaid && b.bookingStatus != 'declined')
            ElevatedButton(
              onPressed: _paying ? null : _pay,
              child: Text(_paying ? 'Processing...' : 'Pay now'),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GalleryScreen(bookingId: b.id)),
            ),
            icon: const Icon(Icons.photo_library),
            label: const Text('View gallery'),
          ),
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
