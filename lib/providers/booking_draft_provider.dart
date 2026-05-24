import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/cart_provider.dart';
import '../services/booking_draft_service.dart';
import '../services/payment_service.dart';

class BookingDraftProvider extends ChangeNotifier {
  BookingDraftProvider(this._service);

  final BookingDraftService _service;

  CartProvider? _cart;
  String? _userId;
  bool _sessionRestored = false;
  Timer? _debounce;
  bool _syncing = false;

  String _notes = '';
  BookingDraftCheckoutPayment _checkoutPayment = const BookingDraftCheckoutPayment();
  BookingDraftPaymentSession _paymentSession = const BookingDraftPaymentSession();
  BookingDraftResumeInfo? _resumeInfo;

  BookingDraftResumeInfo? get resumeInfo => _resumeInfo;
  String get notes => _notes;

  void bindCart(CartProvider cart) {
    if (_cart == cart) return;
    _cart?.removeListener(_onCartChanged);
    _cart = cart;
    _cart?.addListener(_onCartChanged);
  }

  void setNotes(String value) {
    if (_notes == value) return;
    _notes = value;
    scheduleSync(immediate: true);
  }

  void _onCartChanged() {
    _refreshResumeFromCart();
    scheduleSync();
  }

  void _refreshResumeFromCart() {
    if (_cart == null) return;
    final snapshot = _buildSnapshot();
    _resumeInfo = BookingDraftService.resumeInfoFrom(snapshot);
    notifyListeners();
  }

  BookingDraftSnapshot _buildSnapshot() {
    final cart = _cart;
    return BookingDraftSnapshot(
      cart: cart == null ? const [] : BookingDraftService.cartToJson(cart),
      contactForm: BookingDraftContactForm(notes: _notes),
      checkoutPayment: _checkoutPayment,
      paymentSession: _paymentSession,
    );
  }

  void scheduleSync({bool immediate = false}) {
    if (_userId == null) return;
    _debounce?.cancel();
    final snapshot = _buildSnapshot();
    final isEmpty = !snapshot.hasContent;
    _debounce = Timer(Duration(milliseconds: isEmpty ? 0 : 500), () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    if (_userId == null || _syncing) return;
    _syncing = true;
    try {
      final userId = _userId!;
      final snapshot = _buildSnapshot();
      if (!snapshot.hasContent) {
        await _service.clearRemote();
        await _service.clearLocal(userId);
        _checkoutPayment = const BookingDraftCheckoutPayment();
        _paymentSession = const BookingDraftPaymentSession();
        _resumeInfo = null;
      } else {
        final saved = await _service.saveRemote(snapshot);
        await _service.saveLocal(userId, saved);
        _resumeInfo = BookingDraftService.resumeInfoFrom(saved);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[BookingDraft] sync failed: $e');
      final userId = _userId;
      if (userId != null) {
        try {
          await _service.saveLocal(userId, _buildSnapshot());
        } catch (_) {}
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> restoreForUser(String userId) async {
    if (_sessionRestored && _userId == userId) {
      _refreshResumeFromCart();
      return;
    }
    _userId = userId;

    BookingDraftSnapshot? remote;
    try {
      remote = await _service.fetchRemote();
    } catch (e) {
      if (kDebugMode) debugPrint('[BookingDraft] fetch failed: $e');
    }

    final local = await _service.loadLocal(userId);
    final localTs = await _service.localTimestamp(userId);
    final remoteTs = remote?.updatedAt?.millisecondsSinceEpoch ?? 0;
    final localSnapshot = _buildSnapshot();
    final localHasContent = localSnapshot.hasContent;

    BookingDraftSnapshot? chosen;

    if (remote != null && remote.hasContent) {
      if (!localHasContent && localTs >= remoteTs) {
        await clearDraft();
        _sessionRestored = true;
        return;
      }
      if (remoteTs >= localTs || !localHasContent) {
        chosen = remote;
      } else if (local != null && local.hasContent) {
        chosen = local;
      }
    } else if (local != null && local.hasContent) {
      chosen = local;
    }

    if (chosen != null && chosen.hasContent) {
      _applySnapshot(chosen);
      if (remoteTs < localTs && localHasContent) {
        await syncNow();
      }
    } else if (localHasContent) {
      await syncNow();
    } else {
      _resumeInfo = null;
    }

    _sessionRestored = true;
    notifyListeners();
  }

  void _applySnapshot(BookingDraftSnapshot snapshot) {
    final cart = _cart;
    if (cart != null && snapshot.cart.isNotEmpty) {
      cart.importLines(BookingDraftService.cartFromJson(snapshot.cart));
    }
    _notes = snapshot.contactForm.notes;
    _checkoutPayment = snapshot.checkoutPayment;
    _paymentSession = snapshot.paymentSession;
    _resumeInfo = BookingDraftService.resumeInfoFrom(snapshot);
  }

  Future<void> saveCheckoutProgress({
    required List<String> bookingIds,
    required double totalAmount,
    PaymentSession? session,
  }) async {
    _checkoutPayment = BookingDraftCheckoutPayment(
      bookingIds: bookingIds,
      totalAmount: totalAmount,
    );
    if (session != null) {
      _paymentSession = BookingDraftPaymentSession(
        paymentId: session.paymentId,
        checkoutUrl: session.checkoutUrl,
        amount: session.amount,
        isTestMode: session.isTestMode,
        linkError: session.linkError,
        paymentDeadlineAt: session.paymentDeadlineAt,
        paymentHoldMinutes: session.paymentHoldMinutes,
        bookingIds: bookingIds,
      );
    }
    _resumeInfo = BookingDraftService.resumeInfoFrom(_buildSnapshot());
    await syncNow();
  }

  PaymentSession? paymentSessionFromDraft() {
    if (!_paymentSession.isValid) return null;
    return PaymentSession(
      paymentId: _paymentSession.paymentId,
      amount: _paymentSession.amount,
      checkoutUrl: _paymentSession.checkoutUrl,
      isTestMode: _paymentSession.isTestMode,
      linkError: _paymentSession.linkError,
      paymentDeadlineAt: _paymentSession.paymentDeadlineAt,
      paymentHoldMinutes: _paymentSession.paymentHoldMinutes,
    );
  }

  Future<void> clearDraft() async {
    _debounce?.cancel();
    final userId = _userId;
    _checkoutPayment = const BookingDraftCheckoutPayment();
    _paymentSession = const BookingDraftPaymentSession();
    _notes = '';
    _resumeInfo = null;
    if (userId != null) {
      try {
        await _service.clearRemote();
      } catch (_) {}
      await _service.clearLocal(userId);
    }
    notifyListeners();
  }

  void onLogout() {
    _debounce?.cancel();
    _userId = null;
    _sessionRestored = false;
    _notes = '';
    _checkoutPayment = const BookingDraftCheckoutPayment();
    _paymentSession = const BookingDraftPaymentSession();
    _resumeInfo = null;
    notifyListeners();
  }

  void refreshResumeInfo() {
    _refreshResumeFromCart();
  }
}
