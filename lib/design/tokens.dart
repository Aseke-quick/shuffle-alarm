import 'package:material_ui/material_ui.dart';

/// The colors of one Wakemix theme, dark or light: the only color values of
/// the app (ADR-001). Widgets read them with [WakemixColors.of].
///
/// `test/design/contrast_test.dart` checks every pair of text and background,
/// and of control and background, against WCAG AA.
@immutable
class WakemixColors extends ThemeExtension<WakemixColors> {
  const WakemixColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.textDisabled,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.danger,
  });

  /// The reference design: alarms are set at night.
  static const dark = WakemixColors(
    brightness: Brightness.dark,
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF151518),
    surfaceHigh: Color(0xFF1E1E22),
    outline: Color(0xFF2E2E33),
    text: Color(0xFFF4F4F5),
    textMuted: Color(0xFF8A8A90),
    textDisabled: Color(0xFF55555B),
    accent: Color(0xFF5B8CFF),
    onAccent: Color(0xFF0B0B0C),
    accentText: Color(0xFF5B8CFF),
    danger: Color(0xFFFF6B6B),
  );

  /// For a device set to light mode.
  static const light = WakemixColors(
    brightness: Brightness.light,
    background: Color(0xFFF6F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEDEDE8),
    outline: Color(0xFFE3E3DE),
    text: Color(0xFF0B0B0C),
    textMuted: Color(0xFF5C5C63),
    textDisabled: Color(0xFF9A9AA0),
    accent: Color(0xFF2F5BFF),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF2348E0),
    danger: Color(0xFFC62828),
  );

  /// The colors of the theme around [context].
  static WakemixColors of(BuildContext context) =>
      Theme.of(context).extension<WakemixColors>()!;

  final Brightness brightness;

  /// The page.
  final Color background;

  /// Cards, sheets and the record's label.
  final Color surface;

  /// Inputs, pressed states and day keys that are off.
  final Color surfaceHigh;

  /// Hairlines and the record's grooves. Decoration only: too faint to be
  /// the one thing that shows a control.
  final Color outline;

  /// Main text.
  final Color text;

  /// Meta text, and the borders and thumbs of controls.
  final Color textMuted;

  /// Alarms that are off, always together with the word "Off". Exempt from
  /// the contrast rule.
  final Color textDisabled;

  /// Fills and active states.
  final Color accent;

  /// Text and icons on [accent], and on [danger].
  final Color onAccent;

  /// Text in the accent color.
  final Color accentText;

  /// Errors.
  final Color danger;

  @override
  WakemixColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? outline,
    Color? text,
    Color? textMuted,
    Color? textDisabled,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? danger,
  }) => WakemixColors(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    outline: outline ?? this.outline,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    textDisabled: textDisabled ?? this.textDisabled,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentText: accentText ?? this.accentText,
    danger: danger ?? this.danger,
  );

  @override
  WakemixColors lerp(WakemixColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return WakemixColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceHigh: mix(surfaceHigh, other.surfaceHigh),
      outline: mix(outline, other.outline),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textDisabled: mix(textDisabled, other.textDisabled),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentText: mix(accentText, other.accentText),
      danger: mix(danger, other.danger),
    );
  }
}

/// Spacing, on a 4-point grid.
abstract final class Space {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}

/// Corner radii. Switches and chips are fully round.
abstract final class Corners {
  /// Cards, buttons, inputs and dialogs.
  static const card = 16.0;

  /// Day keys.
  static const dayKey = 10.0;
}

/// Motion: short and ease-out, and none at all when the platform asks for
/// less motion ([reduceMotion]).
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOut;

  /// How far a new list item moves up as it fades in.
  static const enterOffset = 8.0;

  /// Whether the platform asks for less motion, such as with "Remove
  /// animations" on Android or "Reduce motion" on iOS.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], or no time at all when the platform asks for less motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  /// For dialogs and snack bars: no animation when the platform asks for
  /// less motion, else their own.
  static AnimationStyle? styleOf(BuildContext context) =>
      reduceMotion(context) ? AnimationStyle.noAnimation : null;
}

/// Font sizes, in logical pixels before the user's text scale.
abstract final class TypeScale {
  /// The time on the rotary dial.
  static const dial = 56.0;

  /// The time on the record's label.
  static const record = 34.0;

  /// The time in an alarm row.
  static const rowTime = 22.0;
  static const title = 20.0;
  static const body = 15.0;
  static const label = 13.0;

  /// The smallest size used.
  static const caption = 11.0;
}

/// Sizes of the layout.
abstract final class Layout {
  /// Content is at most this wide, and centered, on wide screens such as
  /// the web and desktop.
  static const maxContentWidth = 560.0;

  /// The space between content and the edges of the screen.
  static const double gutter = Space.s16;

  /// The smallest touch target: one thumb, half asleep.
  static const minTouchTarget = 48.0;

  /// The height of a wide button.
  static const wideButtonHeight = 52.0;
}
