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
      if (mounted) setState(() {
        _bookings = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'completed':
        return AppColors.purple;
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
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_bookings.isEmpty) {
      return const Center(child: Text('No bookings yet.\nBook a session to get started!'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) {
          final b = _bookings[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)),
              ),
              title: Text(DateFormat.yMMMd().format(b.bookingDate)),
              subtitle: Text('${b.bookingTime} · ${b.services.map((s) => s.name).join(', ')}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(b.bookingStatus).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      b.bookingStatus,
                      style: TextStyle(fontSize: 11, color: _statusColor(b.bookingStatus), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('₱${b.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
