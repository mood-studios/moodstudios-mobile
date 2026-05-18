class GalleryAlbum {
  final String id;
  final String bookingId;
  final String albumName;
  final List<GalleryPhoto> photos;

  const GalleryAlbum({
    required this.id,
    required this.bookingId,
    required this.albumName,
    required this.photos,
  });

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    final photosList = (json['photos'] as List?) ?? [];
    return GalleryAlbum(
      id: json['_id']?.toString() ?? '',
      bookingId: json['bookingId'] is Map
          ? json['bookingId']['_id']?.toString() ?? ''
          : json['bookingId']?.toString() ?? '',
      albumName: json['albumName']?.toString() ?? 'Album',
      photos: photosList
          .map((p) => GalleryPhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GalleryPhoto {
  final String url;
  final String? caption;

  const GalleryPhoto({required this.url, this.caption});

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString(),
    );
  }
}
