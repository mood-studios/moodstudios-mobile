import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/time_slot.dart';
import '../../providers/booking_draft_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../bookings/payment_checkout_screen.dart';
import '../home/home_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final _request = TextEditingController();
  bool _submitting = false;
  final Map<String, List<TimeSlot>> _slotsCache = {};
  final Map<String, bool> _slotsLoading = {};
  Set<String> _blockedDateKeys = {};
  List<int> _closedWeekdays = [];

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingDraftProvider>();
    draft.bindCart(context.read<CartProvider>());
    if (draft.notes.isNotEmpty) {
      _request.text = draft.notes;
    }
    _request.addListener(_onNotesChanged);
    _loadScheduleRules();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadSlots());
  }

  void _onNotesChanged() {
    context.read<BookingDraftProvider>().setNotes(_request.text);
  }

  @override
  void dispose() {
    _request.removeListener(_onNotesChanged);
    context.read<BookingDraftProvider>().syncNow();
    _request.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleRules() async {
    final booking = context.read<BookingService>();
    try {
      final blocked = await booking.getBlockedDayKeys();
      final closed = await booking.getClosedWeekdays();
      if (!mounted) return;
      setState(() {
        _blockedDateKeys = blocked;
        _closedWeekdays = closed;
      });
    } catch (_) {
      /* availability API still enforces rules */
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isDateSelectable(DateTime day) {
    if (_blockedDateKeys.contains(_dateKey(day))) return false;
    if (_closedWeekdays.contains(day.weekday % 7)) return false;
    return true;
  }

  String? _dateUnavailableMessage(DateTime day) {
    if (_blockedDateKeys.contains(_dateKey(day))) {
      return 'This date is not available (studio closed).';
    }
    if (_closedWeekdays.contains(day.weekday % 7)) {
      return 'The studio is closed on this day.';
    }
    return null;
  }

  void _preloadSlots() {
    final cart = context.read<CartProvider>();
    for (final line in cart.lines) {
      for (var u = 0; u < line.qty; u++) {
        if (line.schedules[u].date != null) {
          _loadSlots(line, u);
        }
      }
    }
  }

  String _slotKey(String serviceId, int unitIndex) => '$serviceId-$unitIndex';

  Future<void> _loadSlots(CartLineItem line, int unitIndex) async {
    final schedule = line.schedules[unitIndex];
    final date = schedule.date;
    if (date == null) return;

    final key = _slotKey(line.service.id, unitIndex);
    setState(() => _slotsLoading[key] = true);

    try {
      final slots = await context.read<BookingService>().getAvailability(
            date: date,
            durationMinutes: line.service.duration > 0 ? line.service.duration : 60,
          );
      if (!mounted) return;
      TimeSlot? firstAvailable;
      for (final s in slots) {
        if (s.available) {
          firstAvailable = s;
          break;
        }
      }
      if (schedule.slot == null && firstAvailable != null) {
        context.read<CartProvider>().setSchedule(
              line.service.id,
              unitIndex,
              slot: firstAvailable,
            );
      }
      if (!mounted) return;
      setState(() {
        _slotsCache[key] = slots;
        _slotsLoading[key] = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _slotsLoading[key] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _pickDate(CartLineItem line, int unitIndex) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: line.schedules[unitIndex].date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Date — ${line.service.name}',
      selectableDayPredicate: _isDateSelectable,
    );
    if (picked == null || !mounted) return;
    final blockedMsg = _dateUnavailableMessage(picked);
    if (blockedMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blockedMsg)));
      return;
    }
    final cart = context.read<CartProvider>();
    cart.setSchedule(line.service.id, unitIndex, date: picked);
    await _loadSlots(line, unitIndex);
  }

  bool _validateCart(CartProvider cart) {
    for (final line in cart.lines) {
      for (var u = 0; u < line.qty; u++) {
        final s = line.schedules[u];
        if (s.date == null || s.slot == null) return false;
      }
    }
    return true;
  }

  bool _hasDuplicateSlot(CartProvider cart) {
    final seen = <String>{};
    for (final line in cart.lines) {
      for (var u = 0; u < line.qty; u++) {
        final s = line.schedules[u];
        if (s.date == null || s.slot == null) continue;
        final dateStr = DateFormat('yyyy-MM-dd').format(s.date!);
        final key = '$dateStr|${s.slot!.value}';
        if (seen.contains(key)) return true;
        seen.add(key);
      }
    }
    return false;
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;

    if (!_validateCart(cart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time for every session.')),
      );
      return;
    }

    if (_hasDuplicateSlot(cart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each session needs a unique date and time.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final bookingService = context.read<BookingService>();
      final notes = _request.text.trim();
      final bookingIds = <String>[];

      for (final line in cart.lines) {
        for (var u = 0; u < line.qty; u++) {
          final sched = line.schedules[u];
          final booking = await bookingService.createBooking(
            serviceIds: [line.service.id],
            bookingDate: sched.date!,
            bookingTime: sched.slot!.time,
            specialRequest: notes.isEmpty ? null : notes,
          );
          bookingIds.add(booking.id);
        }
      }

      if (!mounted) return;

      final PaymentSession session;
      if (bookingIds.length == 1) {
        session = await context.read<PaymentService>().startPayment(bookingIds.first);
      } else {
        session = await context.read<PaymentService>().startCombinedPayment(bookingIds);
      }

      if (!mounted) return;

      final draft = context.read<BookingDraftProvider>();
      await draft.saveCheckoutProgress(
        bookingIds: bookingIds,
        totalAmount: cart.total,
        session: session,
      );

      final paid = await Navigator.push<bool>(
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

      if (!mounted) return;

      if (paid == true) {
        cart.clear();
        await draft.clearDraft();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed! Thank you.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookings saved. Complete payment from My Bookings.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _scheduleBlock(CartLineItem line, int unitIndex) {
    final schedule = line.schedules[unitIndex];
    final key = _slotKey(line.service.id, unitIndex);
    final slots = _slotsCache[key] ?? [];
    final loading = _slotsLoading[key] == true;
    final label = line.qty > 1
        ? '${line.service.name} — Session ${unitIndex + 1}'
        : line.service.name;

    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              if (line.qty > 1)
                TextButton.icon(
                  onPressed: () {
                    cart.removeUnit(line.service.id, unitIndex);
                    setState(() {
                      _slotsCache.remove(key);
                      _slotsLoading.remove(key);
                    });
                    if (cart.isEmpty && mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Remove session'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.calendar_today, color: AppColors.purple, size: 20),
              title: Text(
                schedule.date != null
                    ? DateFormat.yMMMEd().format(schedule.date!)
                    : 'Pick date',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickDate(line, unitIndex),
            ),
          ),
          if (schedule.date != null) ...[
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                  ),
                ),
              )
            else if (slots.isEmpty)
              const Text('No times available — try another date.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.where((slot) => slot.available).map((slot) {
                  final selected = schedule.slot?.value == slot.value;
                  return FilterChip(
                    label: Text(slot.time),
                    selected: selected,
                    onSelected: slot.available
                        ? (v) {
                            if (v) {
                              context.read<CartProvider>().setSchedule(
                                    line.service.id,
                                    unitIndex,
                                    slot: slot,
                                  );
                              setState(() {});
                            }
                          }
                        : null,
                    selectedColor: AppColors.purplePale,
                    checkmarkColor: AppColors.purple,
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your packages (${cart.unitCount})',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'Each package and session needs its own date and time.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          ...cart.lines.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.service.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${line.service.duration} min · ${currency.format(line.service.price)}'
                                '${line.qty > 1 ? ' × ${line.qty}' : ''}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () {
                            cart.removeLine(line.service.id);
                            if (cart.isEmpty) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    for (var u = 0; u < line.qty; u++) _scheduleBlock(line, u),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
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
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Processing…' : 'Confirm booking'),
            ),
          ),
        ],
      ),
    );
  }
}
