import '../../../../core/theme/colors.dart';
import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final VoidCallback? onTap;
  final String iconPath;
  final String title;
  final String subtitle;
  const MenuCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final outerColor = _pressed ? Color(0xFF003A99) : MyColors.bgSecondary;
    final innerColor = _pressed ? MyColors.primaryBlue : MyColors.bgElevated;

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: widget.onTap,
      onHighlightChanged: (isPressed) {
        setState(() => _pressed = isPressed);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 190,
        width: 170,
        decoration: BoxDecoration(
          color: outerColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: _pressed ? MyColors.primaryBlue : MyColors.bgElevated,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: innerColor,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: SizedBox(
                    width: 32,
                    child: Image.asset(widget.iconPath),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
