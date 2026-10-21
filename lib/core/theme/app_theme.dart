import 'package:flutter/material.dart';

/// Colors that don't map cleanly onto Material's ColorScheme.
@immutable
class Palette extends ThemeExtension<Palette> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkInverse;
  final Color muted;
  final Color faint;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color warm;
  final Color danger;

  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkInverse,
    required this.muted,
    required this.faint,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.warm,
    required this.danger,
  });

  static const light = Palette(
    background: Color(0xFFF4F2ED),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFECE9E2),
    ink: Color(0xFF15140F),
    inkInverse: Color(0xFFF4F2ED),
    muted: Color(0xFF6B675E),
    faint: Color(0xFFA39E93),
    line: Color(0xFFE3DFD6),
    accent: Color(0xFF1F6F4A),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDCEBE2),
    warm: Color(0xFFB4531A),
    danger: Color(0xFFB3261E),
  );

  static const dark = Palette(
    background: Color(0xFF111210),
    surface: Color(0xFF1A1B19),
    surfaceAlt: Color(0xFF242522),
    ink: Color(0xFFECEAE4),
    inkInverse: Color(0xFF111210),
    muted: Color(0xFFA09C93),
    faint: Color(0xFF6E6A62),
    line: Color(0xFF2C2D2A),
    accent: Color(0xFF7BC89A),
    onAccent: Color(0xFF0F1A13),
    accentSoft: Color(0xFF203127),
    warm: Color(0xFFE39A5C),
    danger: Color(0xFFF2B8B5),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) => t < 0.5 ? this : (other as Palette? ?? this);
}

class AppTheme {
  static const String body = 'Barlow';
  static const String display = 'BarlowCondensed';

  static ThemeData get lightTheme => _build(Palette.light, Brightness.light);
  static ThemeData get darkTheme => _build(Palette.dark, Brightness.dark);

  static TextTheme _text(Palette p) {
    TextStyle d(double size, {FontWeight w = FontWeight.w600, double height = 1.05}) => TextStyle(
          fontFamily: display,
          fontSize: size,
          fontWeight: w,
          height: height,
          color: p.ink,
          letterSpacing: -0.2,
        );
    TextStyle b(double size, {FontWeight w = FontWeight.w400, double height = 1.4, Color? color, double ls = 0}) =>
        TextStyle(
          fontFamily: body,
          fontSize: size,
          fontWeight: w,
          height: height,
          color: color ?? p.ink,
          letterSpacing: ls,
        );

    return TextTheme(
      displayLarge: d(52),
      displayMedium: d(40),
      displaySmall: d(32),
      headlineLarge: d(34),
      headlineMedium: d(28),
      headlineSmall: d(22),
      titleLarge: b(19, w: FontWeight.w600, height: 1.25),
      titleMedium: b(16, w: FontWeight.w600, height: 1.3),
      titleSmall: b(14, w: FontWeight.w600, height: 1.3),
      bodyLarge: b(16),
      bodyMedium: b(15),
      bodySmall: b(13, color: p.muted),
      labelLarge: b(15, w: FontWeight.w600, height: 1.2),
      labelMedium: b(13, w: FontWeight.w600, height: 1.2),
      labelSmall: b(11, w: FontWeight.w600, height: 1.2, color: p.muted, ls: 0.9),
    );
  }

  static ThemeData _build(Palette p, Brightness brightness) {
    final text = _text(p);
    final radius = BorderRadius.circular(12);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.ink,
      onPrimary: p.inkInverse,
      secondary: p.accent,
      onSecondary: p.onAccent,
      tertiary: p.warm,
      onTertiary: p.onAccent,
      error: p.danger,
      onError: p.inkInverse,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainer: p.surface,
      surfaceContainerLow: p.background,
      onSurfaceVariant: p.muted,
      outline: p.faint,
      outlineVariant: p.line,
    );

    final buttonPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      fontFamily: body,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: p.line,
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.line)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.surfaceAlt,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? p.ink : p.faint),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            letterSpacing: 0.2,
            fontSize: 12,
            color: s.contains(WidgetState.selected) ? p.ink : p.faint,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.inkInverse,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.faint,
          padding: buttonPadding,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.inkInverse,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.faint,
          elevation: 0,
          padding: buttonPadding,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.line, width: 1.2),
          padding: buttonPadding,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          textStyle: text.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: p.ink)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.ink,
        foregroundColor: p.inkInverse,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        labelStyle: text.bodyMedium!.copyWith(color: p.muted),
        floatingLabelStyle: text.bodyMedium!.copyWith(color: p.ink),
        hintStyle: text.bodyMedium!.copyWith(color: p.faint),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: p.danger),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.line)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.line)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.ink, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.danger, width: 1.4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.ink,
        disabledColor: p.surfaceAlt,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium!.copyWith(color: p.inkInverse),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: p.line)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.ink : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.inkInverse : p.ink,
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.surface : p.faint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : p.line,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.ink : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.inkInverse),
        side: BorderSide(color: p.faint, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.faint),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.ink,
        linearTrackColor: p.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.faint,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: p.ink,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.line,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.faint,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium!.copyWith(color: p.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: p.inkInverse),
        actionTextColor: p.inkInverse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.ink,
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: p.surface),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(6)),
        textStyle: text.bodySmall!.copyWith(color: p.inkInverse),
      ),
    );
  }
}
