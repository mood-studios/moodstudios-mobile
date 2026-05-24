import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../models/service_model.dart';
import '../models/time_slot.dart';
import '../providers/cart_provider.dart';

class BookingDraftContactForm {
  const BookingDraftContactForm({this.notes = ''});

  final String notes;

  Map<String, dynamic> toJson() => {'notes': notes};

  factory BookingDraftContactForm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingDraftContactForm();
    return BookingDraftContactForm(notes: json['notes']?.toString() ?? '');
  }
}

class BookingDraftCheckoutPayment {
  const BookingDraftCheckoutPayment({
    this.bookingIds = const [],
    this.totalAmount = 0,
  });

  final List<String> bookingIds;
  final double totalAmount;

  bool get hasBookings => bookingIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'bookingIds': bookingIds,
        'totalAmount': totalAmount,
      };

  factory BookingDraftCheckoutPayment.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingDraftCheckoutPayment();
    final ids = json['bookingIds'];
    return BookingDraftCheckoutPayment(
      bookingIds: ids is List ? ids.map((e) => e.toString()).toList() : const [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BookingDraftPaymentSession {
  const BookingDraftPaymentSession({
    this.paymentId = '',
    this.checkoutUrl,
    this.amount = 0,
    this.isTestMode = false,
    this.linkError,
    this.paymentDeadlineAt,
    this.paymentHoldMinutes = 15,
    this.bookingIds = const [],
  });

  final String paymentId;
  final String? checkoutUrl;
  final double amount;
  final bool isTestMode;
  final String? linkError;
  final DateTime? paymentDeadlineAt;
  final int paymentHoldMinutes;
  final List<String> bookingIds;

  bool get isValid => paymentId.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'checkoutUrl': checkoutUrl,
        'amount': amount,
        'isTestMode': isTestMode,
        'linkError': linkError,
        'paymentDeadlineAt': paymentDeadlineAt?.toIso8601String(),
        'paymentHoldMinutes': paymentHoldMinutes,
        'bookingIds': bookingIds,
      };

  factory BookingDraftPaymentSession.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingDraftPaymentSession();
    final ids = json['bookingIds'];
    return BookingDraftPaymentSession(
      paymentId: json['paymentId']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      isTestMode: json['isTestMode'] == true,
      linkError: json['linkError']?.toString(),
      paymentDeadlineAt: DateTime.tryParse(json['paymentDeadlineAt']?.toString() ?? ''),
      paymentHoldMinutes: (json['paymentHoldMinutes'] as num?)?.toInt() ?? 15,
      bookingIds: ids is List ? ids.map((e) => e.toString()).toList() : const [],
    );
  }
}

class BookingDraftSnapshot {
  const BookingDraftSnapshot({
    this.cart = const [],
    this.contactForm = const BookingDraftContactForm(),
    this.checkoutPayment = const BookingDraftCheckoutPayment(),
    this.paymentSession = const BookingDraftPaymentSession(),
    this.updatedAt,
  });

  final List<Map<String, dynamic>> cart;
  final BookingDraftContactForm contactForm;
  final BookingDraftCheckoutPayment checkoutPayment;
  final BookingDraftPaymentSession paymentSession;
  final DateTime? updatedAt;

  bool get hasContent =>
      cart.isNotEmpty ||
      checkoutPayment.hasBookings ||
      paymentSession.isValid;

  Map<String, dynamic> toJson() => {
        'cart': cart,
        'selectedIndices': List.generate(cart.length, (i) => i),
        'contactForm': contactForm.toJson(),
        'checkoutPayment': checkoutPayment.toJson(),
        'paymentSession': paymentSession.isValid ? paymentSession.toJson() : null,
      };

  factory BookingDraftSnapshot.fromApi(Map<String, dynamic>? json) {
    if (json == null) return const BookingDraftSnapshot();
    final cartRaw = json['cart'];
    final updated = json['updatedAt']?.toString();
    return BookingDraftSnapshot(
      cart: cartRaw is List
          ? cartRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : const [],
      contactForm: BookingDraftContactForm.fromJson(
        json['contactForm'] as Map<String, dynamic>?,
      ),
      checkoutPayment: BookingDraftCheckoutPayment.fromJson(
        json['checkoutPayment'] as Map<String, dynamic>?,
      ),
      paymentSession: BookingDraftPaymentSession.fromJson(
        json['paymentSession'] as Map<String, dynamic>?,
      ),
      updatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }
}

class BookingDraftResumeInfo {
  const BookingDraftResumeInfo({
    required this.cartCount,
    required this.scheduledCount,
    required this.pendingPaymentCount,
    this.checkoutPayment = const BookingDraftCheckoutPayment(),
    this.paymentSession = const BookingDraftPaymentSession(),
  });

  final int cartCount;
  final int scheduledCount;
  final int pendingPaymentCount;
  final BookingDraftCheckoutPayment checkoutPayment;
  final BookingDraftPaymentSession paymentSession;

  bool get showBanner => cartCount > 0 || pendingPaymentCount > 0;

  String get message {
    if (pendingPaymentCount > 0) {
      final n = pendingPaymentCount;
      return 'You have $n unpaid booking${n == 1 ? '' : 's'} waiting for payment.';
    }
    if (scheduledCount > 0) {
      return 'Pick up where you left off — $scheduledCount of $cartCount session${cartCount == 1 ? '' : 's'} have dates and times picked.';
    }
    return 'Pick up where you left off — $cartCount item${cartCount == 1 ? '' : 's'} in your cart.';
  }
}

class BookingDraftService {
  BookingDraftService(this._client);

  final ApiClient _client;

  static String _localKey(String userId) => 'mood_draft_$userId';
  static String _localTsKey(String userId) => 'mood_draft_ts_$userId';

  Future<BookingDraftSnapshot?> fetchRemote() async {
    final res = await _client.dio.get('/booking-drafts/me');
    final data = res.data['data'];
    if (data == null) return null;
    return BookingDraftSnapshot.fromApi(data as Map<String, dynamic>);
  }

  Future<BookingDraftSnapshot> saveRemote(BookingDraftSnapshot snapshot) async {
    final res = await _client.dio.put('/booking-drafts/me', data: snapshot.toJson());
    return BookingDraftSnapshot.fromApi(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> clearRemote() async {
    await _client.dio.delete('/booking-drafts/me');
  }

  Future<void> saveLocal(String userId, BookingDraftSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(userId), jsonEncode(snapshot.toJson()));
    await prefs.setInt(_localTsKey(userId), DateTime.now().millisecondsSinceEpoch);
  }

  Future<BookingDraftSnapshot?> loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey(userId));
    if (raw == null) return null;
    try {
      return BookingDraftSnapshot.fromApi(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int> localTimestamp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localTsKey(userId)) ?? 0;
  }

  Future<void> clearLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey(userId));
    await prefs.remove(_localTsKey(userId));
  }

  static List<Map<String, dynamic>> cartToJson(CartProvider cart) {
    return cart.lines.map((line) {
      return {
        'serviceId': line.service.id,
        'name': line.service.name,
        'price': line.service.price,
        'duration': line.service.duration,
        'image': line.service.image,
        'description': line.service.description,
        'qty': line.qty,
        'schedules': line.schedules.map((s) {
          return {
            'date': s.date != null
                ? '${s.date!.year}-${s.date!.month.toString().padLeft(2, '0')}-${s.date!.day.toString().padLeft(2, '0')}'
                : '',
            'time': s.slot?.time ?? '',
            'value': s.slot?.value ?? '',
          };
        }).toList(),
      };
    }).toList();
  }

  static List<CartLineItem> cartFromJson(List<Map<String, dynamic>> raw) {
    final lines = <CartLineItem>[];
    for (final item in raw) {
      final service = ServiceModel(
        id: item['serviceId']?.toString() ?? '',
        name: item['name']?.toString() ?? 'Session',
        description: item['description']?.toString(),
        price: (item['price'] as num?)?.toDouble() ?? 0,
        duration: (item['duration'] as num?)?.toInt() ?? 60,
        image: item['image']?.toString(),
      );
      final line = CartLineItem(service: service);
      line.qty = (item['qty'] as num?)?.toInt() ?? 1;
      final schedules = item['schedules'];
      line.schedules = [];
      if (schedules is List && schedules.isNotEmpty) {
        for (final sched in schedules) {
          if (sched is! Map) continue;
          final dateStr = sched['date']?.toString() ?? '';
          DateTime? date;
          if (dateStr.length >= 10) {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              date = DateTime.tryParse('${parts[0]}-${parts[1]}-${parts[2]}T12:00:00');
            }
          }
          TimeSlot? slot;
          final time = sched['time']?.toString() ?? '';
          final value = sched['value']?.toString() ?? '';
          if (time.isNotEmpty && value.isNotEmpty) {
            slot = TimeSlot(time: time, value: value, available: true);
          }
          line.schedules.add(CartSchedule()..date = date..slot = slot);
        }
      }
      while (line.schedules.length < line.qty) {
        line.schedules.add(CartSchedule());
      }
      if (line.schedules.length > line.qty) {
        line.schedules = line.schedules.sublist(0, line.qty);
      }
      lines.add(line);
    }
    return lines;
  }

  static BookingDraftResumeInfo resumeInfoFrom(BookingDraftSnapshot snapshot) {
    var cartCount = 0;
    var scheduledCount = 0;
    for (final item in snapshot.cart) {
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      cartCount += qty;
      final schedules = item['schedules'];
      if (schedules is List) {
        for (final sched in schedules) {
          if (sched is Map &&
              (sched['date']?.toString().isNotEmpty ?? false) &&
              (sched['value']?.toString().isNotEmpty ?? false)) {
            scheduledCount += 1;
          }
        }
      }
    }
    final pending = snapshot.checkoutPayment.bookingIds.length;
    return BookingDraftResumeInfo(
      cartCount: cartCount,
      scheduledCount: scheduledCount,
      pendingPaymentCount: pending,
      checkoutPayment: snapshot.checkoutPayment,
      paymentSession: snapshot.paymentSession,
    );
  }
}
