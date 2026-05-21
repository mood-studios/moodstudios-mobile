class BookingModel {
  final String id;
  final String userId;
  final List<BookingServiceItem> services;
  final DateTime bookingDate;
  final String bookingTime;
  final String? specialRequest;
  final double totalAmount;
  final String paymentStatus;
  final String bookingStatus;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.services,
    required this.bookingDate,
    required this.bookingTime,
    this.specialRequest,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List?) ?? [];
    return BookingModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId'] is Map
          ? json['userId']['_id']?.toString() ?? ''
          : json['userId']?.toString() ?? '',
      services: servicesList
          .map((s) => BookingServiceItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      bookingDate: DateTime.tryParse(json['bookingDate']?.toString() ?? '') ?? DateTime.now(),
      bookingTime: json['bookingTime']?.toString() ?? '',
      specialRequest: json['specialRequest']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      bookingStatus: json['bookingStatus']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isPaid => paymentStatus == 'paid';

  /// Unpaid bookings still awaiting studio/payment can be cancelled.
  /// - Awaiting payment: no checkout started yet (paymentStatus unpaid).
  /// - Payment pending: checkout started, payment not finished (paymentStatus pending).
  bool get canCancel =>
      bookingStatus == 'pending' && !isPaid && bookingStatus != 'declined';

  /// Photos only after payment and studio confirmation — never while still pending.
  bool get canViewGallery =>
      isPaid &&
      bookingStatus != 'pending' &&
      bookingStatus != 'declined' &&
      (bookingStatus == 'confirmed' || bookingStatus == 'completed');

  /// Customer-facing status for list badges (payment + session).
  String get statusLabel {
    if (bookingStatus == 'declined') return 'Declined';
    if (bookingStatus == 'completed') return 'Completed';
    if (paymentStatus == 'paid') {
      return bookingStatus == 'confirmed' ? 'Confirmed' : 'Paid';
    }
    if (paymentStatus == 'pending') return 'Payment pending';
    if (paymentStatus == 'failed') return 'Payment failed';
    return 'Awaiting payment';
  }

  String get statusLabelKey {
    if (bookingStatus == 'declined') return 'declined';
    if (bookingStatus == 'completed') return 'completed';
    if (paymentStatus == 'paid') return 'paid';
    if (paymentStatus == 'pending') return 'payment_pending';
    if (paymentStatus == 'failed') return 'failed';
    return 'awaiting_payment';
  }
}

class BookingServiceItem {
  final String id;
  final String name;
  final double price;

  const BookingServiceItem({required this.id, required this.name, required this.price});

  factory BookingServiceItem.fromJson(Map<String, dynamic> json) {
    return BookingServiceItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Service',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
