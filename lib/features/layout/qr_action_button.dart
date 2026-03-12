import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QrActionButton extends StatelessWidget {
  const QrActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      child: GestureDetector(
        onTap: () => context.push('/qr-codes'),
        child: Image.asset('assets/images/icons/qr.png'),
      ),
    );
  }
}
