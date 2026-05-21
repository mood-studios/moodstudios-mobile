import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/api_client.dart';
import '../models/gallery_model.dart';

String _safeFileName(String name) {
  final safe = name.replaceAll(RegExp(r'[^\w\-]+'), '_');
  return safe.isEmpty ? 'photo' : safe;
}

class GalleryService {
  GalleryService(this._client);

  final ApiClient _client;

  Future<List<GalleryAlbum>> getByBooking(String bookingId) async {
    final res = await _client.dio.get('/gallery/booking/$bookingId');
    final list = res.data['data'] as List;
    return list.map((e) => GalleryAlbum.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> downloadAlbum(String albumId, String albumName) async {
    final dir = await getTemporaryDirectory();
    final safe = albumName.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final path = '${dir.path}/$safe.zip';
    await _client.dio.download(
      '/gallery/$albumId/download',
      path,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return path;
  }

  Future<String> downloadPhoto(String url, {String name = 'photo'}) async {
    final dir = await getTemporaryDirectory();
    final ext = url.contains('.png') ? 'png' : 'jpg';
    final path = '${dir.path}/${_safeFileName(name)}.$ext';
    final dio = Dio();
    await dio.download(url, path);
    return path;
  }
}
