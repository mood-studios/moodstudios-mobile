import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gallery_model.dart';
import '../../services/gallery_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryAlbum> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final albums = await context.read<GalleryService>().getByBooking(widget.bookingId);
      if (mounted) setState(() {
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Gallery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _albums.isEmpty
              ? const Center(child: Text('No photos uploaded yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _albums.length,
                  itemBuilder: (_, i) {
                    final album = _albums[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(album.albumName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (album.photos.isEmpty)
                          const Text('No photos in this album', style: TextStyle(color: AppColors.muted))
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: album.photos.length,
                            itemBuilder: (_, pi) {
                              final photo = album.photos[pi];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: photo.url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.purplePale),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
    );
  }
}
