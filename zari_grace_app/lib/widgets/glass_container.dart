import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final Color borderColor;
  final Color fillColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.08,
    this.radius = 16.0,
    this.borderColor = const Color(0xFFFFFFFF),
    this.fillColor = const Color(0xFFFFFFFF),
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor.withOpacity(0.12),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fillColor.withOpacity(opacity * 1.5),
                fillColor.withOpacity(opacity * 0.5),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
