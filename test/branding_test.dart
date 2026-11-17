import 'dart:io';
import 'dart:typed_data';

import 'package:espanol_pro/app/theme.dart';
import 'package:espanol_pro/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const res = 'android/app/src/main/res';

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String colorRes(String file, String name) {
  final m = RegExp('<color name="$name">(#[0-9A-Fa-f]{6})</color>')
      .firstMatch(File('$res/$file').readAsStringSync());
  expect(m, isNotNull, reason: '$name missing in $file');
  return m!.group(1)!.toUpperCase();
}

void main() {
  test('Flutter brand colours match the Android icon and splash colours', () {
    expect(colorRes('values/colors.xml', 'brand_teal'), hex(brandTeal));
    expect(colorRes('values/colors.xml', 'splash_background'), hex(brandTeal));
    expect(
      colorRes('values-night/colors.xml', 'splash_background'),
      hex(brandTealNight),
    );
  });

  test('adaptive icon has background, foreground and themed layer', () {
    final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
        .readAsStringSync();
    expect(xml, contains('@color/brand_teal'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('<monochrome'));
    for (final f in ['ic_launcher_foreground', 'ic_launcher_monochrome']) {
      final v = File('$res/drawable/$f.xml').readAsStringSync();
      expect(v, contains('android:viewportWidth="108"'));
      expect(v, contains('android:pathData="M'));
    }
  });

  test('legacy launcher PNGs have the exact size for each density', () {
    const sizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in sizes.entries) {
      final bytes = File('$res/mipmap-${e.key}/ic_launcher.png')
          .readAsBytesSync();
      final header = ByteData.sublistView(bytes, 16, 24);
      expect(header.getUint32(0), e.value, reason: '${e.key} width');
      expect(header.getUint32(4), e.value, reason: '${e.key} height');
    }
  });

  test('both splash generations use the brand mark', () {
    for (final f in [
      'drawable/launch_background.xml',
      'drawable-v21/launch_background.xml',
    ]) {
      final xml = File('$res/$f').readAsStringSync();
      expect(xml, contains('@color/splash_background'), reason: f);
      expect(xml, contains('@drawable/ic_launcher_foreground'), reason: f);
    }
    for (final f in ['values-v31/styles.xml', 'values-night-v31/styles.xml']) {
      final xml = File('$res/$f').readAsStringSync();
      expect(xml, contains('windowSplashScreenAnimatedIcon'), reason: f);
      expect(xml, contains('windowSplashScreenBackground'), reason: f);
    }
  });

  testWidgets('in-app loading screen shows the mark and an accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: BrandSplash())),
      ),
    );
    expect(find.text('ñ'), findsOneWidget);
    expect(find.text('Español Pro'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Español Pro')), findsOneWidget);
  });
}
