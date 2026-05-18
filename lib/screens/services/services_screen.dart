import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/catalog_service.dart';
import '../../widgets/service_card.dart';
import '../booking/booking_checkout_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];
  String? _selectedCategory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = context.read<CatalogService>();
      final cats = await catalog.getCategories();
      final services = await catalog.getServices();
      if (mounted) {
        setState(() {
          _categories = cats;
          _services = services;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<ServiceModel> get _filtered {
    if (_selectedCategory == null) return _services;
    return _services.where((s) => s.categoryId == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Column(
      children: [
        if (_categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                    selectedColor: AppColors.purplePale,
                  ),
                ),
                ..._categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: _selectedCategory == c.id,
                      onSelected: (_) => setState(() => _selectedCategory = c.id),
                      selectedColor: AppColors.purplePale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
              : _error != null
                  ? Center(child: Text(_error!, textAlign: TextAlign.center))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final s = _filtered[i];
                          return ServiceCard(
                            service: s,
                            selected: cart.contains(s.id),
                            onToggle: () => cart.toggle(s),
                          );
                        },
                      ),
                    ),
        ),
        if (cart.count > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.purple,
                    child: Text('${cart.count}', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('₱${cart.total.toStringAsFixed(0)} total', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingCheckoutScreen()),
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
