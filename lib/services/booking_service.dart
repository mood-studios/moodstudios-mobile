import '../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/time_slot.dart';

class BookingService {
  BookingService(this._client);

  final ApiClient _client;

  Future<Set<String>> getBlockedDayKeys() async {
    final res = await _client.dio.get('/public/blocked-days');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => e.toString()).toSet();
  }

  Future<List<int>> getClosedWeekdays() async {
    final res = await _client.dio.get('/public/schedule');
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final raw = data['closedWeekdays'] as List? ?? [];
    return raw.map((e) => (e as num).toInt()).toList();
  }

  Future<List<TimeSlot>> getAvailability({
    required DateTime date,
    required int durationMinutes,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _client.dio.get('/bookings/availability', queryParameters: {
      'date': dateStr,
      'durationMinutes': durationMinutes,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final slots = data['slots'] as List;
    return slots.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

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
    final res = await _client.dio.get(
      '/bookings/my',
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
    );
    final list = res.data['data'] as List;
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> getBooking(String id) async {
    final res = await _client.dio.get(
      '/bookings/$id',
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
    );
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<BookingModel> cancelBooking(String id) async {
    final res = await _client.dio.delete('/bookings/$id');
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    return getBooking(id);
  }

  Future<Map<String, dynamic>> createPayment(String bookingId) async {
    final res = await _client.dio.post('/payments', data: {'bookingId': bookingId});
    return res.data['data'] as Map<String, dynamic>;
  }
}
