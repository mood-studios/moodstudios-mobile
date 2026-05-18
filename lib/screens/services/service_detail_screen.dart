import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/service_model.dart';
import '../../providers/cart_provider.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    super.key,
    required this.service,
  });

  final ServiceModel service;

  static Future<void> open(BuildContext context, ServiceModel service) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final cart = context.watch<CartProvider>();
    final inCart = cart.contains(service.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(service.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.purplePale,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.photo_camera, color: AppColors.purple, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              if (service.categoryName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  service.categoryName!,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                '${currency.format(service.price)} · ${service.duration} min',
                                style: const TextStyle(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Package includes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _PackageDescription(text: service.description ?? 'No description available.'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!inCart) cart.toggle(service);
                    Navigator.pop(context);
                  },
                  child: Text(inCart ? 'Added to booking ✓' : 'Add to booking'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageDescription extends StatelessWidget {
  const _PackageDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return const Text('No description available.', style: TextStyle(color: AppColors.muted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        final bulletText = trimmed.startsWith('•')
            ? trimmed.substring(1).trim()
            : trimmed.startsWith('-')
                ? trimmed.substring(1).trim()
                : trimmed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, size: 18, color: AppColors.purple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bulletText,
                  style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.text),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
