import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/cart_provider.dart';
import '../screens/booking/booking_checkout_screen.dart';

/// Cart sidebar aligned with web: qty controls, subtotal, checkout CTA.
void showCartBottomSheet(BuildContext context) {
  final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);
            });
            return const SizedBox.shrink();
          }

          final itemLabel = cart.unitCount == 1 ? '1 item' : '${cart.unitCount} items';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your cart',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(itemLabel, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ...cart.lines.map((line) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border.withValues(alpha: 0.25)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.purplePale,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.photo_camera_outlined, color: AppColors.purple),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.service.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${line.service.duration} min',
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                    ),
                                    Text(
                                      currency.format(line.service.price),
                                      style: const TextStyle(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                    tooltip: 'Remove package',
                                    onPressed: () => cart.removeLine(line.service.id),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: line.qty > 1
                                            ? () => cart.removeOne(line.service.id)
                                            : () => cart.removeLine(line.service.id),
                                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                                      ),
                                      Text('${line.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => cart.add(line.service),
                                        icon: const Icon(Icons.add_circle_outline, size: 22, color: AppColors.purple),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.2))),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            currency.format(cart.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Date & time are chosen per package on the next screen.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingCheckoutScreen()),
                            );
                          },
                          child: const Text('Continue to checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
