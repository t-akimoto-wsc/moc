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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 30, top: 20),
        child: CommonLogo(iconSize: iconSize, fontSize: fontSize),
      ),
    );
  }
}
