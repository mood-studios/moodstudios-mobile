import '../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';

class CatalogService {
  CatalogService(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> getCategories() async {
    final res = await _client.dio.get('/categories');
    final list = res.data['data'] as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> getServices({String? categoryId}) async {
    final res = await _client.dio.get('/services', queryParameters: {
      if (categoryId != null) 'category': categoryId,
      'visibleOnly': 'true',
    });
    final list = res.data['data'] as List;
    return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
