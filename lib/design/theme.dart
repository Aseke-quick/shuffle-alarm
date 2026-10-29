import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/fonts.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The Wakemix themes: Material 3 from the tokens, dark and light. The app
/// follows the system setting; dark is the reference design.
abstract final class WakemixTheme {
  static final ThemeData dark = _theme(WakemixColors.dark);
  static final ThemeData light = _theme(WakemixColors.light);
}

/// The text styles Material's [TextTheme] has no place for: Geist Mono for
/// small counters and captions. Widgets read them with [WakemixType.of].
@immutable
class WakemixType extends ThemeExtension<WakemixType> {
  const WakemixType({required this.meta, required this.caption});

  /// Small counters and meta text, such as "in 7 h 20 min" and "Bed by
  /// 22:30 for 8 h of sleep".
  final TextStyle meta;

  /// Captions, such as "ALL ALARMS": the smallest text.
  final TextStyle caption;

  static WakemixType of(BuildContext context) =>
      Theme.of(context).extension<WakemixType>()!;

  @override
  WakemixType copyWith({TextStyle? meta, TextStyle? caption}) =>
      WakemixType(meta: meta ?? this.meta, caption: caption ?? this.caption);

  @override
  WakemixType lerp(WakemixType? other, double t) {
    if (other == null) return this;
    return WakemixType(
      meta: TextStyle.lerp(meta, other.meta, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}

/// The type scale of the tokens on Material's text roles: Unbounded for
/// display, headline and the large title, Geist for the rest.
TextTheme _textTheme() {
  TextStyle display(double size, {double height = 1.1}) => WakemixFonts.style(
    WakemixFonts.display,
    size: size,
    weight: FontWeight.w500,
    height: height,
    letterSpacing: -0.02 * size,
  );
  TextStyle text(double size, FontWeight weight, {double height = 1.4}) =>
      WakemixFonts.style(
        WakemixFonts.text,
        size: size,
        weight: weight,
        height: height,
      );
  return TextTheme(
    displayLarge: display(TypeScale.dial, height: 1),
    displayMedium: display(TypeScale.record, height: 1),
    displaySmall: display(28),
    headlineLarge: display(28),
    headlineMedium: display(24),
    headlineSmall: display(TypeScale.rowTime, height: 1.15),
    titleLarge: display(TypeScale.title, height: 1.2),
    titleMedium: text(TypeScale.body, FontWeight.w600),
    titleSmall: text(TypeScale.label, FontWeight.w600),
    bodyLarge: text(TypeScale.body, FontWeight.w400),
    bodyMedium: text(TypeScale.body, FontWeight.w400),
    bodySmall: text(TypeScale.label, FontWeight.w400),
    labelLarge: text(TypeScale.body, FontWeight.w600, height: 1.2),
    labelMedium: text(TypeScale.label, FontWeight.w500, height: 1.2),
    labelSmall: text(TypeScale.caption, FontWeight.w500, height: 1.2),
  );
}

ThemeData _theme(WakemixColors c) {
  final textTheme = _textTheme().apply(bodyColor: c.text, displayColor: c.text);
  final type = WakemixType(
    meta: WakemixFonts.style(
      WakemixFonts.meta,
      size: TypeScale.label,
      height: 1.4,
      color: c.textMuted,
    ),
    caption: WakemixFonts.style(
      WakemixFonts.meta,
      size: TypeScale.caption,
      weight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.9,
      color: c.textMuted,
    ),
  );
  final scheme = ColorScheme(
    brightness: c.brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.surfaceHigh,
    onPrimaryContainer: c.text,
    secondary: c.accent,
    onSecondary: c.onAccent,
    secondaryContainer: c.surfaceHigh,
    onSecondaryContainer: c.text,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    error: c.danger,
    onError: c.onAccent,
    surface: c.background,
    onSurface: c.text,
    onSurfaceVariant: c.textMuted,
    surfaceDim: c.background,
    surfaceBright: c.surfaceHigh,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surfaceHigh,
    // Material draws the borders of text fields, chips and switches in
    // `outline`, which must show the control (3:1); hairlines use
    // `outlineVariant`.
    outline: c.textMuted,
    outlineVariant: c.outline,
    inverseSurface: c.text,
    onInverseSurface: c.background,
    inversePrimary: c.accent,
    surfaceTint: Colors.transparent,
  );
  const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
  );
  final buttonText = textTheme.labelLarge!;
  final fieldBorder = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(Corners.card)),
    borderSide: BorderSide(color: c.textMuted),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    fontFamily: WakemixFonts.text,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    dividerColor: c.outline,
    disabledColor: c.textDisabled,
    // Touch targets of 48 dp on every platform, the web and desktop too,
    // where Material would make them smaller.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [c, type],
    appBarTheme: AppBarThemeData(
      backgroundColor: c.background,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: Layout.gutter,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: c.text),
      actionsIconTheme: IconThemeData(color: c.text),
    ),
    iconTheme: IconThemeData(color: c.text),
    dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceHigh,
        disabledForegroundColor: c.textDisabled,
        textStyle: buttonText,
        minimumSize: const Size(64, Layout.minTouchTarget),
        shape: cardShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        disabledForegroundColor: c.textDisabled,
        side: BorderSide(color: c.textMuted),
        textStyle: buttonText,
        minimumSize: const Size(64, Layout.minTouchTarget),
        shape: cardShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accentText,
        textStyle: buttonText,
        minimumSize: const Size(64, Layout.minTouchTarget),
        shape: cardShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size.square(Layout.minTouchTarget),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => switch (states) {
          _ when states.contains(WidgetState.disabled) => c.textDisabled,
          _ when states.contains(WidgetState.selected) => c.onAccent,
          _ => c.textMuted,
        },
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : c.textMuted,
      ),
    ),
    chipTheme: ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelMedium!.copyWith(color: c.text),
      secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: c.onAccent),
      checkmarkColor: c.onAccent,
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s8,
        vertical: Space.s8,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.all(Space.s16),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: c.danger),
      ),
      labelStyle: textTheme.bodyLarge!.copyWith(color: c.textMuted),
      // The accent only while the field has the focus.
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => textTheme.bodyLarge!.copyWith(
          color: states.contains(WidgetState.focused)
              ? c.accentText
              : c.textMuted,
        ),
      ),
      hintStyle: textTheme.bodyLarge!.copyWith(color: c.textMuted),
      helperStyle: textTheme.bodySmall!.copyWith(color: c.textMuted),
      errorStyle: textTheme.bodySmall!.copyWith(color: c.danger),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.32),
      selectionHandleColor: c.accent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: cardShape,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: c.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: c.background),
      behavior: SnackBarBehavior.floating,
      shape: cardShape,
      elevation: 0,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.text,
        borderRadius: const BorderRadius.all(Radius.circular(Space.s8)),
      ),
      textStyle: textTheme.bodySmall!.copyWith(color: c.background),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.surface,
      shape: cardShape,
      helpTextStyle: type.caption,
      hourMinuteShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
      ),
      hourMinuteColor: c.surfaceHigh,
      hourMinuteTextColor: c.text,
      hourMinuteTextStyle: WakemixFonts.style(
        WakemixFonts.display,
        size: 40,
        weight: FontWeight.w500,
      ),
      dayPeriodShape: cardShape,
      dayPeriodBorderSide: BorderSide(color: c.textMuted),
      dayPeriodColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent
            : Colors.transparent,
      ),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.onAccent : c.textMuted,
      ),
      dayPeriodTextStyle: textTheme.titleMedium,
      entryModeIconColor: c.textMuted,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: c.accentText,
        textStyle: buttonText,
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: c.accentText,
        textStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surfaceHigh,
        contentPadding: EdgeInsets.zero,
        border: fieldBorder.copyWith(borderSide: BorderSide.none),
        enabledBorder: fieldBorder.copyWith(borderSide: BorderSide.none),
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
        hintStyle: TextStyle(color: c.textMuted),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
    ),
  );
}
