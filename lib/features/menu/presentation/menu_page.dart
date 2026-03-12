import '../../../core/theme/colors.dart';
import '../../layout/cart_button.dart';
import '../../layout/custom_appbar.dart';
import '../../layout/side_nav.dart';
import '../data/menu_repository.dart';
import '../domain/entities/menu_category.dart';
import '../domain/entities/menu_item.dart';
import '../domain/services/cart_service.dart';
import 'widgets/menu_item_card.dart';
import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import 'package:go_router/go_router.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuRepository _repository = getIt<MenuRepository>();
  late final Future<List<MenuCategory>> _menuFuture = _repository.fetchMenu();
  final CartService _cart = getIt<CartService>();

  void _onCartChanged() => setState(() {});

  void _addToCart(MenuItem item) => _cart.addItem(item);

  void _openCart() {
    if (_cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }
    context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        leading: const SideNavButton(active: SideNavSection.menu),
        actions: [
          AnimatedBuilder(
            animation: _cart,
            builder: (context, _) =>
                CartActionButton(count: _cart.totalCount, onTap: _openCart),
          ),
        ],
        title: Text('MENU', style: Theme.of(context).textTheme.displayMedium),
      ),
      body: FutureBuilder<List<MenuCategory>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MyColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load menu',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final categories = snapshot.data ?? const [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No menu items found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return DefaultTabController(
            length: categories.length,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: _MenuCategoryTabs(categories: categories),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final category in categories)
                        _MenuGrid(items: category.items, onAdd: _addToCart),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuCategoryTabs extends StatelessWidget {
  const _MenuCategoryTabs({required this.categories});

  final List<MenuCategory> categories;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context)!;
    final animation = controller.animation!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final activeValue = animation.value;
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < categories.length; i++)
                _CategoryTabChip(
                  category: categories[i],
                  isSelected: (activeValue - i).abs() < 0.5,
                  onTap: () => controller.animateTo(i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTabChip extends StatelessWidget {
  const _CategoryTabChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final MenuCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _iconForCategory(category.id);
    final iconPadding = category.id == 'drinks'
        ? const EdgeInsets.only(right: 4)
        : EdgeInsets.zero;

    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(right: 22, left: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003A99), Color(0xFF5F3AFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBubble(
                isSelected: isSelected,
                icon: icon,
                padding: iconPadding,
                background: Colors.white,
                color: Colors.black87,
              ),
              const SizedBox(width: 10),
              Text(category.title, style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: GestureDetector(
        onTap: onTap,
        child: _IconBubble(
          isSelected: isSelected,
          icon: icon,
          padding: iconPadding,
          background: Colors.white,
          color: Colors.black87,
        ),
      ),
    );
  }

  String _iconForCategory(String id) {
    switch (id) {
      case 'drinks':
        return 'assets/images/menu/drinks.png';
      case 'snacks':
        return 'assets/images/menu/snacks.png';
      case 'mains':
        return 'assets/images/menu/mains.png';
      case 'desserts':
        return 'assets/images/menu/desserts.png';
      default:
        return 'assets/images/menu/drinks.png';
    }
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.background,
    required this.color,
    required this.isSelected,
    this.padding = EdgeInsets.zero,
  });
  final bool isSelected;
  final String icon;
  final Color background;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bubbleSize = isSelected ? 47.0 : 54.0;

    return Container(
      height: bubbleSize,
      width: bubbleSize,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: MyColors.bgElevated),
      ),
      child: Center(
        child: Padding(
          padding: padding,
          child: Image.asset(
            icon,
            width: isSelected ? 18 : 22,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items, required this.onAdd});

  final List<MenuItem> items;
  final void Function(MenuItem item) onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.58,
        crossAxisSpacing: 18.63,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) =>
          MenuItemCard(item: items[index], onAdd: () => onAdd(items[index])),
    );
  }
}
