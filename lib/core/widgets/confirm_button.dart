import 'package:flutter/material.dart';

class ConfirmButton extends StatelessWidget {
  const ConfirmButton({
    super.key,
    required this.onPressed,
    required this.title,
  });
  final VoidCallback onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(220),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(220)),
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
                fontSize: 16.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
