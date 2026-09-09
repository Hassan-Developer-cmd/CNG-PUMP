import 'package:flutter/material.dart';
import '../../utils/dashed_border_painter.dart';

class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const DashedBorderBox({
    super.key,
    required this.child,
    required this.borderColor,
    this.backgroundColor,
    this.borderRadius = 10.0,
    this.strokeWidth = 1.2,
    this.dashLength = 5.0,
    this.dashGap = 3.5,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      painter: DashedBorderPainter(
        color: borderColor,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        dashGap: dashGap,
        borderRadius: borderRadius,
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
