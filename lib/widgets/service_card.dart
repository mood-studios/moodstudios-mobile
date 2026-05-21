import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/service_model.dart';
import '../screens/services/service_detail_screen.dart';

/// Service row — tap for full package details; + add / − remove from cart.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onAdd,
    this.onRemoveOne,
    this.qty = 0,
  });

  final ServiceModel service;
  final bool selected;
  final VoidCallback onAdd;
  final VoidCallback? onRemoveOne;
  final int qty;

  String? get _previewDescription {
    final d = service.description?.trim();
    if (d == null || d.isEmpty) return null;
    final firstLine = d.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => d);
    return firstLine.trim();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final preview = _previewDescription;

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (preview != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Tap for full package details',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.purple.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (qty > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.purple,
                      child: Text(
                        '$qty',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onAdd,
                  tooltip: 'Add to cart',
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9CA3AF), size: 28),
                ),
                if (qty > 0 && onRemoveOne != null)
                  IconButton(
                    onPressed: onRemoveOne,
                    tooltip: 'Remove one',
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 24),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
