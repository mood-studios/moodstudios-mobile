import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gallery_model.dart';

/// Full-screen photo viewer with pinch-zoom and download.
class GalleryPhotoViewerScreen extends StatefulWidget {
  const GalleryPhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.onDownload,
  });

  final List<GalleryPhoto> photos;
  final int initialIndex;
  final Future<void> Function(GalleryPhoto photo, int index) onDownload;

  @override
  State<GalleryPhotoViewerScreen> createState() => _GalleryPhotoViewerScreenState();
}

class _GalleryPhotoViewerScreenState extends State<GalleryPhotoViewerScreen> {
  late final PageController _pageController;
  late int _index;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await widget.onDownload(widget.photos[_index], _index + 1);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            onPressed: _downloading ? null : _downloadCurrent,
            icon: _downloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: 'Download photo',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.photos[i].url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(color: AppColors.purple),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: photo.caption != null && photo.caption!.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  photo.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : null,
    );
  }
}
