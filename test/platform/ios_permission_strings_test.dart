import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// iOS shows permission prompts from `Info.plist` (English) or a localized
/// `InfoPlist.strings` (#254) — a key missing there silently falls back to
/// English on a Russian iPhone.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final usageKeys = RegExp(
    r'<key>(NS\w+UsageDescription)</key>',
  ).allMatches(plist).map((m) => m[1]!).toSet();

  test('Info.plist declares usage descriptions', () {
    expect(usageKeys, isNotEmpty);
  });

  test('every usage description has a Russian translation', () {
    final strings = File(
      'ios/Runner/ru.lproj/InfoPlist.strings',
    ).readAsStringSync();
    final entries = {
      for (final m in RegExp(
        r'^"(\w+)" = "(.+)";$',
        multiLine: true,
      ).allMatches(strings))
        m[1]!: m[2]!,
    };
    expect(entries.keys.toSet(), usageKeys);
    for (final value in entries.values) {
      expect(value, contains('Storyni'));
      expect(value, matches(RegExp('[а-яё]')));
    }
  });

  test('the Xcode project bundles it and iOS knows the app speaks ru', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(project, contains('path = ru.lproj/InfoPlist.strings;'));
    expect(project, contains('/* InfoPlist.strings in Resources */,'));
    expect(
      RegExp(r'knownRegions = \([^)]*\bru,').hasMatch(project),
      isTrue,
    );
    expect(
      RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>\s*'
        r'<string>en</string>\s*<string>ru</string>',
      ).hasMatch(plist),
      isTrue,
    );
  });
}
