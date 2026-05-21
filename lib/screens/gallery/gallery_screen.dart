import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gallery_model.dart';
import '../../services/gallery_service.dart';
import 'gallery_photo_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryAlbum> _albums = [];
  bool _loading = true;
  String? _downloadingAlbumId;
  String? _downloadingPhotoUrl;

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

  Future<void> _downloadAlbum(GalleryAlbum album) async {
    if (album.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This album has no photos to download.')),
      );
      return;
    }
    setState(() => _downloadingAlbumId = album.id);
    try {
      final path = await context.read<GalleryService>().downloadAlbum(album.id, album.albumName);
      if (!mounted) return;
      await OpenFilex.open(path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album downloaded')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _downloadingAlbumId = null);
    }
  }

  Future<void> _downloadPhoto(GalleryPhoto photo, int index) async {
    setState(() => _downloadingPhotoUrl = photo.url);
    try {
      final path = await context.read<GalleryService>().downloadPhoto(
            photo.url,
            name: 'photo-$index',
          );
      if (!mounted) return;
      await OpenFilex.open(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo downloaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _downloadingPhotoUrl = null);
    }
  }

  void _openPhoto(GalleryAlbum album, int photoIndex) {
    if (album.photos.isEmpty) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPhotoViewerScreen(
          photos: album.photos,
          initialIndex: photoIndex,
          onDownload: _downloadPhoto,
        ),
      ),
    );
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
                    final downloading = _downloadingAlbumId == album.id;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                album.albumName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                            if (album.photos.isNotEmpty)
                              TextButton.icon(
                                onPressed: downloading ? null : () => _downloadAlbum(album),
                                icon: downloading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.download_outlined, size: 18),
                                label: Text(downloading ? 'Preparing…' : 'Download album'),
                              ),
                          ],
                        ),
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
                              return GestureDetector(
                                onTap: () => _openPhoto(album, pi),
                                onLongPress: _downloadingPhotoUrl == photo.url
                                    ? null
                                    : () => _downloadPhoto(photo, pi + 1),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: photo.url,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            Container(color: AppColors.purplePale),
                                      ),
                                      const Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.zoom_in,
                                            color: Colors.white,
                                            size: 20,
                                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
