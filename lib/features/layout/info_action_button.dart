import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InfoActionButton extends StatelessWidget {
  const InfoActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      child: GestureDetector(
        onTap: () => context.push('/info'),
        child: Image.asset('assets/images/icons/info.png'),
      ),
    );
  }
}
