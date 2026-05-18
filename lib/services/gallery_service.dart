import '../core/network/api_client.dart';
import '../models/gallery_model.dart';

class GalleryService {
  GalleryService(this._client);

  final ApiClient _client;

  Future<List<GalleryAlbum>> getByBooking(String bookingId) async {
    final res = await _client.dio.get('/gallery/booking/$bookingId');
    final list = res.data['data'] as List;
    return list.map((e) => GalleryAlbum.fromJson(e as Map<String, dynamic>)).toList();
  }
}
