import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassDecoration {
  static Widget backdropFilter({
    required Widget child,
    double blur = 20.0,
    bool isDark = false,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceCard.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.40),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
