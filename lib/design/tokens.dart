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
    required this.glass,
    required this.glassLine,
    required this.gentle,
    required this.medium,
    required this.strong,
    required this.fieldOlive,
    required this.fieldPine,
    required this.fieldBronze,
    required this.shadow,
  });

  /// The reference design: alarms are set at night.
  static const dark = WakemixColors(
    brightness: Brightness.dark,
    background: Color(0xFF171B12),
    surface: Color(0xFF262B1D),
    surfaceHigh: Color(0xFF333A27),
    outline: Color(0xFF3C432F),
    text: Color(0xFFF5F2E6),
    textMuted: Color(0xFFBEBCA6),
    textDisabled: Color(0xFF85846F),
    accent: Color(0xFFE2D398),
    onAccent: Color(0xFF1E2114),
    accentText: Color(0xFFE2D398),
    danger: Color(0xFFF0907A),
    glass: Color(0x11FFFFFF),
    glassLine: Color(0x1CFFFFFF),
    gentle: Color(0xFFA9C27A),
    medium: Color(0xFFE2D398),
    strong: Color(0xFFE39A6B),
    fieldOlive: Color(0x576E8438),
    fieldPine: Color(0x662F5D46),
    fieldBronze: Color(0x42A0662F),
    shadow: Color(0x47000000),
  );

  /// For a device set to light mode.
  static const light = WakemixColors(
    brightness: Brightness.light,
    background: Color(0xFFF2EEE5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE9E4D6),
    outline: Color(0xFFDDD6C4),
    text: Color(0xFF20211B),
    textMuted: Color(0xFF63614D),
    textDisabled: Color(0xFF9C9A86),
    accent: Color(0xFF59603A),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF4A5130),
    danger: Color(0xFFA83A25),
    glass: Color(0xB8FFFFFF),
    glassLine: Color(0x1420211B),
    gentle: Color(0xFF5C7A2E),
    medium: Color(0xFF8A7422),
    strong: Color(0xFFB4582C),
    fieldOlive: Color(0x296E8438),
    fieldPine: Color(0x1F2F5D46),
    fieldBronze: Color(0x24A0662F),
    shadow: Color(0x173C371E),
  );

  /// The fill of a card of a gentle sound, with [onStrength] on it: the same
  /// in both themes, as a card is a thing of its own.
  static const gentleFill = Color(0xFFA9C27A);

  /// The fill of a card of a medium sound.
  static const mediumFill = Color(0xFFE2D398);

  /// The fill of a card of a strong sound.
  static const strongFill = Color(0xFFE39A6B);

  /// Text and icons on [gentleFill], [mediumFill] and [strongFill].
  static const onStrength = Color(0xFF1E2114);

  /// The colors of the theme around [context].
  static WakemixColors of(BuildContext context) =>
      Theme.of(context).extension<WakemixColors>()!;

  final Brightness brightness;

  /// The page, below the color fields.
  final Color background;

  /// Solid cards: dialogs, snack bars and the bottom bar.
  final Color surface;

  /// Inputs, pressed states and keys that are off.
  final Color surfaceHigh;

  /// Hairlines. Decoration only: too faint to be the one thing that shows a
  /// control.
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

  /// The fill of a glass card: a little light over the color fields.
  final Color glass;

  /// The hairline around a glass card.
  final Color glassLine;

  /// A gentle sound, or a morning that went well, as a mark on the page.
  final Color gentle;

  /// A medium sound, or a morning with a Snooze, as a mark on the page.
  final Color medium;

  /// A strong sound, or a missed morning, as a mark on the page.
  final Color strong;

  /// The color fields behind the page, each at its strongest (`Backdrop`).
  final Color fieldOlive;
  final Color fieldPine;
  final Color fieldBronze;

  /// The soft shadow under a glass card.
  final Color shadow;

  /// The color of a sound of [intensity], from 1 (gentle) to 3 (strong), as a
  /// mark on the page.
  Color strength(int intensity) => switch (intensity) {
    <= 1 => gentle,
    2 => medium,
    _ => strong,
  };

  /// The fill of a card of a sound of [intensity], from 1 to 3.
  static Color strengthFill(int intensity) => switch (intensity) {
    <= 1 => gentleFill,
    2 => mediumFill,
    _ => strongFill,
  };

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
    Color? glass,
    Color? glassLine,
    Color? gentle,
    Color? medium,
    Color? strong,
    Color? fieldOlive,
    Color? fieldPine,
    Color? fieldBronze,
    Color? shadow,
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
    glass: glass ?? this.glass,
    glassLine: glassLine ?? this.glassLine,
    gentle: gentle ?? this.gentle,
    medium: medium ?? this.medium,
    strong: strong ?? this.strong,
    fieldOlive: fieldOlive ?? this.fieldOlive,
    fieldPine: fieldPine ?? this.fieldPine,
    fieldBronze: fieldBronze ?? this.fieldBronze,
    shadow: shadow ?? this.shadow,
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
      glass: mix(glass, other.glass),
      glassLine: mix(glassLine, other.glassLine),
      gentle: mix(gentle, other.gentle),
      medium: mix(medium, other.medium),
      strong: mix(strong, other.strong),
      fieldOlive: mix(fieldOlive, other.fieldOlive),
      fieldPine: mix(fieldPine, other.fieldPine),
      fieldBronze: mix(fieldBronze, other.fieldBronze),
      shadow: mix(shadow, other.shadow),
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

/// Corner radii. Buttons, switches, chips and the tabs are fully round.
abstract final class Corners {
  /// The big cards, such as the next alarm.
  static const hero = 28.0;

  /// Cards, rows, tiles, inputs and dialogs.
  static const card = 24.0;

  /// Day keys and the small tiles inside a row.
  static const dayKey = 16.0;

  /// Fully round: buttons and chips.
  static const round = 999.0;
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
  /// The clock on the ringing screen: read half asleep.
  static const ringClock = 96.0;

  /// The time on the card of the next alarm, on a wide screen.
  static const heroWide = 148.0;

  /// The time on the card of the next alarm, and the chosen value of a time
  /// wheel.
  static const hero = 88.0;

  /// The big titles of a page on a wide screen, and the figures of a tile.
  static const figure = 30.0;

  /// The time in an alarm row.
  static const rowTime = 32.0;
  static const title = 20.0;
  static const body = 15.0;
  static const label = 13.0;

  /// The smallest size used.
  static const caption = 11.0;
}

/// Sizes of the layout.
abstract final class Layout {
  /// One column of content is at most this wide, and centered.
  static const maxContentWidth = 560.0;

  /// From this width on, a page is wide: the tabs sit in a top bar and the
  /// content can take two columns ([isWide]).
  static const wideBreakpoint = 1000.0;

  /// The content of a wide page is at most this wide, and centered.
  static const maxWideWidth = 1312.0;

  /// Whether the screen around [context] is wide: a laptop or a desktop, not
  /// a phone.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  /// The space between content and the edges of the screen.
  static const double gutter = Space.s16;

  /// The smallest touch target: one thumb, half asleep.
  static const minTouchTarget = 48.0;

  /// The height of a wide button.
  static const wideButtonHeight = 56.0;
}
