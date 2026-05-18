import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/service_model.dart';
import '../screens/services/service_detail_screen.dart';

/// Service row card — tap body for package details, + to add to cart.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onToggle,
  });

  final ServiceModel service;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.purple : const Color(0xFFEEEEEE),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.purplePale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_camera_outlined, color: AppColors.purple, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ServiceDetailScreen.open(context, service),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (service.categoryName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            service.categoryName!,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${currency.format(service.price)} · ${service.duration} min',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                selected ? Icons.check_circle : Icons.add_circle_outline,
                color: selected ? AppColors.purple : const Color(0xFF9CA3AF),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
