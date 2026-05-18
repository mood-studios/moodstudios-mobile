import 'package:flutter/foundation.dart';
import '../models/service_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, ServiceModel> _items = {};

  List<ServiceModel> get items => _items.values.toList();
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  double get total => items.fold(0, (sum, s) => sum + s.price);

  bool contains(String id) => _items.containsKey(id);

  void toggle(ServiceModel service) {
    if (_items.containsKey(service.id)) {
      _items.remove(service.id);
    } else {
      _items[service.id] = service;
    }
    notifyListeners();
  }

  void remove(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<String> get serviceIds => _items.keys.toList();
}
