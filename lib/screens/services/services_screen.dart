import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/catalog_service.dart';
import '../../widgets/service_card.dart';
import '../../widgets/cart_bottom_sheet.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];
  String? _selectedCategoryId;
  bool _loading = true;
  bool _loadingServices = false;
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
          _selectedCategoryId = null;
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

  Future<void> _selectCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId && !_loadingServices) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _loadingServices = true;
      _error = null;
    });

    try {
      final services = await context.read<CatalogService>().getServices(
            categoryId: categoryId,
          );
      if (mounted) {
        setState(() {
          _services = services;
          _loadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingServices = false;
        });
      }
    }
  }

  void _openCartSheet() {
    if (context.read<CartProvider>().isEmpty) return;
    showCartBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Column(
      children: [
        if (_categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategoryId == null,
                    onSelected: _loadingServices
                        ? null
                        : (_) => _selectCategory(null),
                    selectedColor: AppColors.purplePale,
                  ),
                ),
                ..._categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: _selectedCategoryId == c.id,
                      onSelected: _loadingServices
                          ? null
                          : (_) => _selectCategory(c.id),
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
              : _error != null && _services.isEmpty
                  ? Center(child: Text(_error!, textAlign: TextAlign.center))
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () async {
                            await _load();
                            if (_selectedCategoryId != null) {
                              await _selectCategory(_selectedCategoryId);
                            }
                          },
                          child: _services.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        'No packages in this category.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.muted),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _services.length,
                                  itemBuilder: (_, i) {
                                    final s = _services[i];
                                    return ServiceCard(
                                      service: s,
                                      selected: cart.contains(s.id),
                                      qty: cart.qtyOf(s.id),
                                      onAdd: () => cart.add(s),
                                      onRemoveOne: () => cart.removeOne(s.id),
                                    );
                                  },
                                ),
                        ),
                        if (_loadingServices)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(color: AppColors.purple, minHeight: 2),
                          ),
                      ],
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
                  InkWell(
                    onTap: _openCartSheet,
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      backgroundColor: AppColors.purple,
                      child: Text('${cart.unitCount}', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _openCartSheet,
                      child: Text('₱${cart.total.toStringAsFixed(0)} total · Tap to review', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _openCartSheet,
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
