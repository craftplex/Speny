import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF5F8F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color primaryPurple = Color(0xFF087F5B);
  static const Color secondaryPurple = Color(0xFF36B58A);
  static const Color accentLightPurple = Color(0xFFE5F5EC);
  static const Color darkText = Color(0xFF142D25);
  static const Color subText = Color(0xFF75847C);
  static const Color darkNavBg = Color(0xFFFFFFFF);
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFE6ECE7);
  static const Color green = Color(0xFF16845D);
  static const Color red = Color(0xFFD95F5B);
  static const Color orange = Color(0xFFE39A45);
  static const Color line = Color(0xFFE9EFEB);
  static const Color paleGreen = Color(0xFFEAF6EF);
}

class NeoGlassTheme {
  static ThemeData get theme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryPurple,
      onSecondary: Colors.white,
      error: AppColors.red,
      onError: Colors.white,
      surface: AppColors.cardBg,
      onSurface: AppColors.darkText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.subText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primaryPurple,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

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
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? card
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: onTap,
                child: card,
              ),
            ),
    );
  }
}

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
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              const [Color(0xFF075C43), Color(0xFF128562), Color(0xFF31A77B)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
