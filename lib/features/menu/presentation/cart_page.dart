import '../../../core/di/injection.dart';
import '../../../core/theme/colors.dart';
import '../../layout/custom_appbar.dart';
import '../domain/entities/cart_entry.dart';
import '../domain/services/cart_service.dart';
import 'dart:convert';

import '../../qr/data/qr_repository.dart';
import '../../qr/domain/saved_qr.dart';
import '../../reserve/presentation/reservation_qr_page.dart';
import '../../challenges/data/challenges_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final CartService _cart = getIt<CartService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        needElevation: false,
        color: MyColors.bgPrimary,

        title: Text(
          'Your order',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      body: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          final entries = _cart.items;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your cart is empty',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 40),
                    _ConfirmButton(
                      onPressed: () {
                        context.go('/menu');
                      },
                      title: 'Open menu',
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: ValueKey(entry.item.id),
                      direction: DismissDirection.endToStart,
                      background: _DeleteBackground(),
                      onDismissed: (_) => _cart.removeItem(entry.item),
                      child: _CartItemTile(
                        entry: entry,
                        onIncrement: () => _cart.addItem(entry.item),
                        onDecrement: () => _cart.decrement(entry.item),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.only(bottom: 50),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 25, right: 25),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const Spacer(),
                          Text(
                            '\$${_cart.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 21, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: SizedBox(
                          height: 60,
                          child: _ConfirmButton(
                            title: 'Confitm & Generate QR',
                            onPressed: () async {
                              final orderTime = DateTime.now();
                              final payload = _cart.items
                                  .map(
                                    (e) => {
                                      'name': e.item.name,
                                      'qty': e.quantity,
                                      'price': e.item.price,
                                    },
                                  )
                                  .toList();
                              final totalItems = _cart.items.fold<int>(
                                0,
                                (sum, e) => sum + e.quantity,
                              );
                              final qrData = QrConfirmData(
                                qrData: jsonEncode({
                                  'type': 'order',
                                  'items': payload,
                                  'total': _cart.total,
                                  'createdAt': orderTime.toIso8601String(),
                                }),
                                subtitlePrimary: 'Show this QR to your server.',
                                subtitleSecondary:
                                    'They will receive your order.',
                                orderTotal: _cart.total,
                                orderItemsCount: totalItems,
                              );
                              final saved = SavedQr(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                type: SavedQrType.order,
                                created: orderTime,
                                data: qrData,
                              );
                              await QrRepository().save(saved);
                              await ChallengesRepository().evaluateOrder(
                                _cart.items,
                                orderTime,
                              );
                              if (!context.mounted) return;
                              context.push(
                                '/order/confirmation',
                                extra: qrData,
                              );
                            },
                          ),
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
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.entry,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartEntry entry;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(14, 8, 20, 8),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _CartImage(imagePath: entry.item.imagePath),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${entry.item.price.toStringAsFixed(2)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: MyColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 8,
            child: _QuantityControl(
              quantity: entry.quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyColors.bgElevated),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniButton(icon: 'assets/images/icons/min.png', onTap: onDecrement),
          const SizedBox(width: 15),
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 15),
          _MiniButton(icon: 'assets/images/icons/plus.png', onTap: onIncrement),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: SizedBox(height: 14, width: 14, child: Image.asset(icon)),
        ),
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  const _CartImage({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: MyColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.local_dining,
        color: MyColors.primaryGrey,
        size: 26,
      ),
    );

    if (imagePath.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onPressed, required this.title});
  final VoidCallback onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(250),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(250)),
            gradient: LinearGradient(
              colors: [Color(0xFF003A99), Color(0xFF006BFF), Color(0xFF00A5FF)],
              begin: Alignment.topLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: MyColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 30,
        child: Image.asset('assets/images/icons/del.png', scale: 0.1),
      ),
    );
  }
}
