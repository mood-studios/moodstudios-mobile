import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;
  String? _error;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<BookingService>().getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException && e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<bool> _confirmCancel() async {
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
    return confirmed == true;
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    if (!booking.canCancel || _cancellingId != null) return;
    if (!await _confirmCancel() || !mounted) return;

    final bookingService = context.read<BookingService>();
    setState(() => _cancellingId = booking.id);
    try {
      await bookingService.cancelBooking(booking.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  Future<void> _openDetail(BookingModel booking) async {
    final cancelled = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)),
    );
    if (cancelled == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    }
  }

  Color _statusColor(String key) {
    switch (key) {
      case 'paid':
      case 'confirmed':
        return Colors.green;
      case 'declined':
      case 'failed':
        return Colors.red;
      case 'completed':
        return AppColors.purple;
      case 'payment_pending':
        return Colors.amber.shade800;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_bookings.isEmpty) {
      return const Center(child: Text('No bookings yet.\nBook a session to get started!'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purple,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) {
          final b = _bookings[i];
          final isCancelling = _cancellingId == b.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  onTap: isCancelling ? null : () => _openDetail(b),
                  title: Text(DateFormat.yMMMd().format(b.bookingDate)),
                  subtitle: Text(
                    '${b.bookingTime} · ${b.services.map((s) => s.name).join(', ')}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(b.statusLabelKey).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor(b.statusLabelKey),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${b.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (b.canCancel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: OutlinedButton.icon(
                      onPressed: isCancelling ? null : () => _cancelBooking(b),
                      icon: isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                      label: Text(
                        isCancelling ? 'Cancelling…' : 'Cancel booking',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
