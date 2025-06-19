import 'package:flutter/material.dart';
import 'common_logo.dart';

class CommonLogoPositioned extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const CommonLogoPositioned({
    super.key,
    this.iconSize = 40,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 30,
      child: CommonLogo(iconSize: iconSize, fontSize: fontSize),
    );
  }
}
