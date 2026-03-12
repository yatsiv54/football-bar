import '../../../../core/theme/colors.dart';
import '../../domain/entities/menu_item.dart';
import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item, this.onTap, this.onAdd});

  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImage(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: textTheme.headlineLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onAdd != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: _AddButton(onPressed: onAdd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final placeholder = Container(
      height: 144,
      width: double.infinity,
      color: MyColors.bgElevated,
      child: const Icon(
        Icons.local_dining,
        size: 32,
        color: MyColors.primaryGrey,
      ),
    );

    if (item.imagePath.isEmpty) return placeholder;

    return Image.asset(
      item.imagePath,
      height: 150,
      width: double.infinity,
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: MyColors.primaryBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add, size: 20, color: Colors.white),
      ),
    );
  }
}
