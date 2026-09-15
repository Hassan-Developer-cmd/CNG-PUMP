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
    this.borderRadius = 8.0,
    this.strokeWidth = 1.0,
    this.dashLength = 3.0,
    this.dashGap = 2.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final Widget content = Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: onTap == null
            ? Colors.transparent
            : borderColor.withValues(alpha: 0.08),
        highlightColor: onTap == null
            ? Colors.transparent
            : borderColor.withValues(alpha: 0.04),
        child: CustomPaint(
          // IMPORTANT:
          // foregroundPainter draws the dashed border
          // AFTER the child has been painted.
          foregroundPainter: DashedBorderPainter(
            color: borderColor,
            strokeWidth: strokeWidth,
            dashLength: dashLength,
            dashGap: dashGap,
            borderRadius: borderRadius,
          ),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor ?? const Color(0xFFFCFDFD),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );

    return content;
  }
}
