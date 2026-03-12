import '../../../../core/theme/colors.dart';
import '../../domain/entities/cart_entry.dart';
import '../../domain/entities/menu_item.dart';
import 'package:flutter/material.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({
    super.key,
    required this.entries,
    required this.total,
    required this.onIncrement,
    required this.onDecrement,
  });

  final List<CartEntry> entries;
  final double total;
  final void Function(MenuItem item) onIncrement;
  final void Function(MenuItem item) onDecrement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _CartItemTile(
                    entry: entry,
                    onIncrement: () => onIncrement(entry.item),
                    onDecrement: () => onDecrement(entry.item),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total:', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ConfirmButton(onPressed: () {}),
            const SizedBox(height: 8),
          ],
        ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MyColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _CartImage(imagePath: entry.item.imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${entry.item.price.toStringAsFixed(2)}',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: MyColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          _QuantityControl(
            quantity: entry.quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyColors.bgElevated),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniButton(icon: Icons.remove, onTap: onDecrement),
          const SizedBox(width: 10),
          Text('$quantity', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 10),
          _MiniButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 22,
        width: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
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
      height: 64,
      width: 64,
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
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(22)),
            gradient: LinearGradient(
              colors: [Color(0xFF003A99), Color(0xFF5F3AFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              'Confirm & Generate QR',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
