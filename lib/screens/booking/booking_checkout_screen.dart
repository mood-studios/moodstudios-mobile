import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/time_slot.dart';
import '../../providers/cart_provider.dart';
import '../../services/booking_service.dart';
import '../home/home_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  List<TimeSlot> _slots = [];
  bool _loadingSlots = true;
  final _request = TextEditingController();
  bool _submitting = false;

  int get _durationMinutes {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return 60;
    final total = cart.items.fold<int>(0, (sum, s) => sum + s.duration);
    return total > 0 ? total : 60;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
  }

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });
    try {
      final slots = await context.read<BookingService>().getAvailability(
            date: _date,
            durationMinutes: _durationMinutes,
          );
      if (!mounted) return;
      TimeSlot? firstAvailable;
      for (final s in slots) {
        if (s.available) {
          firstAvailable = s;
          break;
        }
      }
      setState(() {
        _slots = slots;
        _selectedSlot = firstAvailable;
        _loadingSlots = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select session date',
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _loadSlots();
    }
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<BookingService>().createBooking(
            serviceIds: cart.serviceIds,
            bookingDate: _date,
            bookingTime: _selectedSlot!.time,
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
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (msg.contains('no longer available')) {
          await _loadSlots();
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final availableCount = _slots.where((s) => s.available).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Complete Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Selected services (${cart.count})', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...cart.items.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.name),
              subtitle: Text('${s.duration} min'),
              trailing: Text(currency.format(s.price)),
            ),
          ),
          const Divider(height: 32),
          const Text('Date & time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.purple),
              title: const Text('Session date'),
              subtitle: Text(DateFormat.yMMMEd().format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Session time ($_durationMinutes min block)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            availableCount == 0
                ? 'No times available this day — try another date.'
                : 'Tap an available time. Grey slots are already booked.',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
            )
          else if (_slots.isEmpty)
            const Text('No time slots configured for this day.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final selected = _selectedSlot?.value == slot.value;
                return FilterChip(
                  label: Text(slot.time),
                  selected: selected,
                  onSelected: slot.available
                      ? (selected) {
                          setState(() => _selectedSlot = slot);
                        }
                      : null,
                  selectedColor: AppColors.purplePale,
                  checkmarkColor: AppColors.purple,
                  backgroundColor: slot.available ? AppColors.white : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: slot.available
                        ? (selected ? AppColors.purple : AppColors.text)
                        : Colors.grey.shade500,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.purple : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _request,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special requests (optional)',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.white,
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
                Text(
                  currency.format(cart.total),
                  style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_submitting || _selectedSlot == null) ? null : _submit,
              child: Text(_submitting ? 'Submitting...' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
