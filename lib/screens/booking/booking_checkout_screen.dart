import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../services/booking_service.dart';
import '../home/home_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final _request = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final bookingService = context.read<BookingService>();
      final timeStr = _time.format(context);
      await bookingService.createBooking(
        serviceIds: cart.serviceIds,
        bookingDate: _date,
        bookingTime: timeStr,
        specialRequest: _request.text.trim(),
      );
      cart.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Complete Booking')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Selected services (${cart.count})', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...cart.items.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name),
                trailing: Text(currency.format(s.price)),
              )),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.purple),
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMMd().format(_date)),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: AppColors.purple),
            title: const Text('Time'),
            subtitle: Text(_time.format(context)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _request,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special requests (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purplePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(currency.format(cart.total), style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting...' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
