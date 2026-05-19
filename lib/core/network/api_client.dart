import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/auth_storage.dart';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Mood-Client': 'mobile',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final message = _parseError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: message,
              message: message,
            ),
          );
        },
      ),
    );
  }

  final AuthStorage _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  static String _parseError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
    return 'Something went wrong. Please try again.';
  }
}
