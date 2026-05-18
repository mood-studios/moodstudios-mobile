import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'gallery_screen.dart';

class GalleryHubScreen extends StatefulWidget {
  const GalleryHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GalleryHubScreen> createState() => _GalleryHubScreenState();
}

class _GalleryHubScreenState extends State<GalleryHubScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.read<BookingService>().getMyBookings();
      if (mounted) setState(() {
        _bookings = list.where((b) => b.bookingStatus == 'completed' || b.bookingStatus == 'confirmed').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_bookings.isEmpty) {
      return const Center(child: Text('No galleries yet.\nPhotos appear after your session.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (_, i) {
        final b = _bookings[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.photo_album, color: AppColors.purple),
            title: Text('Session ${b.id.substring(b.id.length - 6)}'),
            subtitle: Text(b.services.map((s) => s.name).join(', ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GalleryScreen(bookingId: b.id)),
            ),
          ),
        );
      },
    );
  }
}
