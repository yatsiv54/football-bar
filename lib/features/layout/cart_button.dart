import '../../core/theme/colors.dart';
import 'package:flutter/material.dart';

class CartActionButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const CartActionButton({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/menu/cart.png'),
              if (count > 0)
                Positioned(
                  bottom: 4,
                  left: 10,
                  child: Container(
                    height: 21,
                    width: 21,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        count < 99 ? count.toString() : 'X',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge!.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
