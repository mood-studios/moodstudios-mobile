import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

/// Saves a downloaded image file to the device gallery (Photos).
Future<void> saveImageFileToGallery(
  BuildContext context,
  String filePath, {
  String? albumName,
}) async {
  try {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      await Gal.requestAccess();
    }
    await Gal.putImage(filePath, album: albumName ?? 'Mood Studios');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your gallery')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save to gallery: $e')),
      );
    }
    rethrow;
  }
}
