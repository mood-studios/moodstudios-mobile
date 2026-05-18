import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/service_model.dart';

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
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: service.image != null && service.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.image!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (service.categoryName != null)
                      Text(service.categoryName!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(service.price)} · ${service.duration} min',
                      style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.add_circle_outline,
                color: selected ? AppColors.purple : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        color: AppColors.purplePale,
        child: const Icon(Icons.photo_camera, color: AppColors.purple),
      );
}
