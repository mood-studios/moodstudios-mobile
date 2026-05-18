import '../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingService {
  BookingService(this._client);

  final ApiClient _client;

  Future<BookingModel> createBooking({
    required List<String> serviceIds,
    required DateTime bookingDate,
    required String bookingTime,
    String? specialRequest,
  }) async {
    final res = await _client.dio.post('/bookings', data: {
      'services': serviceIds,
      'bookingDate': bookingDate.toIso8601String(),
      'bookingTime': bookingTime,
      if (specialRequest != null && specialRequest.isNotEmpty)
        'specialRequest': specialRequest,
    });
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> getMyBookings() async {
    final res = await _client.dio.get('/bookings/my');
    final list = res.data['data'] as List;
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> getBooking(String id) async {
    final res = await _client.dio.get('/bookings/$id');
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createPayment(String bookingId) async {
    final res = await _client.dio.post('/payments', data: {'bookingId': bookingId});
    return res.data['data'] as Map<String, dynamic>;
  }
}
