import 'package:flutter/material.dart';

class CommonLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const CommonLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', width: iconSize, height: iconSize),
        const SizedBox(width: 8),
        Text(
          '旅リアン',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
