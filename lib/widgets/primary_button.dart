import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? bgColor;
  final Color? fgColor;
  final bool iconInWhiteCircle;
  final Color? iconCircleColor;
  final Color? iconColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.bgColor,
    this.fgColor,
    this.iconInWhiteCircle = false,
    this.iconCircleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingIcon;
    if (icon != null) {
      if (iconInWhiteCircle) {
        leadingIcon = Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconCircleColor ?? Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor ?? AppColors.navy),
        ).pOnly(right: 8);
      } else {
        leadingIcon = Icon(icon, color: fgColor ?? Colors.white).pOnly(right: 8);
      }
    }

    final child = HStack([
      if (leadingIcon != null) leadingIcon,
      label.text.color(fgColor ?? Colors.white).semiBold.make(),
    ]).centered();

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor ?? AppColors.navy,
        foregroundColor: fgColor ?? Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: child,
    );
  }
}
