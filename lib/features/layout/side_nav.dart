import '../../core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SideNavSection {
  home,
  menu,
  order,
  reserve,
  schedule,
  challenges,
  shoutboard,
}

class SideNavButton extends StatelessWidget {
  const SideNavButton({super.key, required this.active});

  final SideNavSection active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/images/icons/nav.png'),
      onPressed: () => _openDrawer(context),
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 0, left: 8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 120,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF0F0F0)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(2, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SideItem(
                      label: 'Home',
                      asset: 'assets/images/icons/home.png',
                      selected: active == SideNavSection.home,
                      onTap: () => _navigate(dialogContext, context, '/home'),
                    ),
                    _SideItem(
                      label: 'Menu',
                      asset: 'assets/images/icons/menu.png',
                      selected: active == SideNavSection.menu,
                      onTap: () => _navigate(dialogContext, context, '/menu'),
                    ),
                    _SideItem(
                      label: 'Order',
                      asset: 'assets/images/icons/order.png',
                      selected: active == SideNavSection.order,
                      onTap: () => _navigate(dialogContext, context, '/cart'),
                    ),
                    _SideItem(
                      label: 'Reserve',
                      asset: 'assets/images/icons/reserve.png',
                      selected: active == SideNavSection.reserve,
                      onTap: () =>
                          _navigate(dialogContext, context, '/reserve'),
                    ),
                    _SideItem(
                      label: 'Schedule',
                      asset: 'assets/images/icons/schedule.png',
                      selected: active == SideNavSection.schedule,
                      onTap: () =>
                          _navigate(dialogContext, context, '/schedule'),
                    ),
                    _SideItem(
                      label: 'Challenges',
                      asset: 'assets/images/icons/challanges.png',
                      selected: active == SideNavSection.challenges,
                      onTap: () =>
                          _navigate(dialogContext, context, '/challenges'),
                    ),
                    _SideItem(
                      label: 'Shoutboard',
                      asset: 'assets/images/icons/fan.png',
                      selected: active == SideNavSection.shoutboard,
                      onTap: () => _navigate(dialogContext, context, '/fan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigate(
    BuildContext dialogContext,
    BuildContext parentContext,
    String route,
  ) {
    Navigator.of(dialogContext).pop();
    if (route == '/cart') {
      parentContext.push(route);
    } else {
      parentContext.go(route);
    }
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.label,
    this.asset,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? asset;
  final Icon? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = MyColors.primaryBlue;
    final Color activeTextColor = MyColors.primaryBlue;
    final Color inactiveColor = Colors.white;
    final Color inactiveTextColor = MyColors.primaryGrey2;
    final Color iconColor = selected ? Colors.white : inactiveColor;
    final Color bubbleColor = selected ? activeColor : MyColors.primaryGrey2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: asset != null
                        ? Image.asset(
                            asset!,
                            width: 27,
                            height: 27,
                            color: iconColor,
                          )
                        : Icon(icon?.icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? activeTextColor : inactiveTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected)
            Positioned(
              right: 0,
              top: 24,
              bottom: 24,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
