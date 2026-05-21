import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../models/time_slot.dart';

class CartSchedule {
  DateTime? date;
  TimeSlot? slot;
}

class CartLineItem {
  CartLineItem({required this.service}) : schedules = [CartSchedule()];

  final ServiceModel service;
  int qty = 1;
  List<CartSchedule> schedules;

  void addUnit() {
    qty += 1;
    schedules.add(CartSchedule());
  }

  void removeLastUnit() {
    if (qty <= 1) return;
    qty -= 1;
    schedules.removeLast();
  }
}

/// Cart aligned with web: each package can have qty > 1, each unit gets its own date/time.
class CartProvider extends ChangeNotifier {
  final List<CartLineItem> _lines = [];

  List<CartLineItem> get lines => List.unmodifiable(_lines);
  int get count => unitCount;
  int get unitCount => _lines.fold<int>(0, (sum, line) => sum + line.qty);
  bool get isEmpty => _lines.isEmpty;
  double get total =>
      _lines.fold<double>(0, (sum, line) => sum + line.service.price * line.qty);

  int qtyOf(String serviceId) {
    for (final line in _lines) {
      if (line.service.id == serviceId) return line.qty;
    }
    return 0;
  }

  bool contains(String id) => qtyOf(id) > 0;

  /// Add one unit (same as web addToCart increment).
  void add(ServiceModel service) {
    final index = _lines.indexWhere((l) => l.service.id == service.id);
    if (index >= 0) {
      _lines[index].addUnit();
    } else {
      _lines.add(CartLineItem(service: service));
    }
    notifyListeners();
  }

  /// Remove one unit; drops the line when qty reaches 0.
  void removeOne(String serviceId) {
    final index = _lines.indexWhere((l) => l.service.id == serviceId);
    if (index < 0) return;
    if (_lines[index].qty > 1) {
      _lines[index].removeLastUnit();
    } else {
      _lines.removeAt(index);
    }
    notifyListeners();
  }

  void removeLine(String serviceId) {
    _lines.removeWhere((l) => l.service.id == serviceId);
    notifyListeners();
  }

  void setSchedule(String serviceId, int unitIndex, {DateTime? date, TimeSlot? slot}) {
    CartLineItem? line;
    for (final l in _lines) {
      if (l.service.id == serviceId) {
        line = l;
        break;
      }
    }
    if (line == null || unitIndex < 0 || unitIndex >= line.schedules.length) return;
    if (date != null) {
      line.schedules[unitIndex].date = date;
      line.schedules[unitIndex].slot = null;
    }
    if (slot != null) {
      line.schedules[unitIndex].slot = slot;
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// @deprecated Use [lines] — kept for gradual migration.
  List<ServiceModel> get items {
    final out = <ServiceModel>[];
    for (final line in _lines) {
      for (var i = 0; i < line.qty; i++) {
        out.add(line.service);
      }
    }
    return out;
  }

  List<String> get serviceIds =>
      _lines.expand((line) => List.filled(line.qty, line.service.id)).toList();
}
