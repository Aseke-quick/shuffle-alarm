import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/fonts.dart';
import 'package:shuffle_alarm/design/theme.dart';

/// Shows [child] on a page of the Wakemix theme, dark unless [brightness]
/// says light.
Future<void> pumpDesign(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WakemixTheme.light,
      darkTheme: WakemixTheme.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

/// Loads the bundled fonts, so text in this test has their real sizes.
/// Without it, a widget test draws every glyph as a square of the test
/// font.
Future<void> loadWakemixFonts() async {
  await (FontLoader(
    WakemixFonts.text,
  )..addFont(rootBundle.load('assets/fonts/geist/Geist.ttf'))).load();
}

/// Makes the screen [size] logical pixels, as on a phone, until the test
/// ends.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size * tester.view.devicePixelRatio
    ..viewInsets = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
}

/// Sets the text scale of the platform, such as 2.0 for large text, until
/// the test ends.
void setTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Asks for less motion, as with "Remove animations" on Android, until the
/// test ends.
void askForLessMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The [Brightness] values, for a test of both themes.
const List<Brightness> brightnesses = [Brightness.dark, Brightness.light];
