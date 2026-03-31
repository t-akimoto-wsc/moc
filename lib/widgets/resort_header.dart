import 'package:flutter/material.dart';

class ResortHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final bool showBrand;

  const ResortHeader({
    super.key,
    required this.title,
    this.automaticallyImplyLeading = false,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.showBrand = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showAppName = width >= 360;
    final double resolvedLeadingWidth =
        leadingWidth ?? (showBrand ? (showAppName ? 170 : 64) : 56);

    final Widget? resolvedLeading = showBrand
        ? Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
                if (showAppName) ...[
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      '旅リアン',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B3C5D),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        : leading;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: 0,
      centerTitle: true,
      leadingWidth: resolvedLeadingWidth,
      leading: resolvedLeading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0B3C5D),
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB3E5FC),
              Color(0xFFE1F5FE),
            ],
          ),
        ),
      ),
    );
  }
}
