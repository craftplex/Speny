import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF3F5F9);
  static const Color cardBg = Color(0xFFF8F9FC);
  static const Color primaryPurple = Color(0xFF8A62F6);
  static const Color secondaryPurple = Color(0xFFB597FE);
  static const Color accentLightPurple = Color(0xFFECE6FF);
  static const Color darkText = Color(0xFF1D1E2C);
  static const Color subText = Color(0xFF7A7E9A);
  static const Color darkNavBg = Color(0xFF14151C);

  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFD3D8E5);

  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFFF5252);
  static const Color orange = Color(0xFFFF9800);
}

class NeoGlassTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
        background: AppColors.background,
        surface: AppColors.cardBg,
      ),
      fontFamily: 'Roboto',
    );
  }
}

/// Neomorphic Container Widget
class NeoContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final bool isPressed;

  const NeoContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor = AppColors.cardBg,
    this.onTap,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isPressed
                ? []
                : const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      offset: Offset(-4, -4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppColors.shadowDark,
                      offset: Offset(4, 4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glassmorphic Card Widget with optional gradient and soft backdrop blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.gradientColors,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  AppColors.primaryPurple,
                  AppColors.secondaryPurple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
