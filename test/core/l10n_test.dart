import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

/// Placeholders used in [text], out of the [declared] ones (ICU plural
/// branches like `=1{once}` are not placeholders).
Set<String> _placeholders(String text, Set<String> declared) => {
  for (final name in declared)
    if (RegExp('\\{$name[,}]').hasMatch(text)) name,
};

Set<String> _declared(Map<String, Object?> en, String key) {
  final meta = en['@$key'];
  if (meta is! Map || meta['placeholders'] is! Map) return const {};
  return (meta['placeholders'] as Map).keys.cast<String>().toSet();
}

void main() {
  final en = _arb('app_en.arb');
  final si = _arb('app_si.arb');
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();

  test('Sinhala and English have exactly the same messages', () {
    final siKeys = si.keys.where((k) => !k.startsWith('@')).toSet();
    expect(siKeys.difference(keys), isEmpty, reason: 'only in Sinhala');
    expect(keys.difference(siKeys), isEmpty, reason: 'missing in Sinhala');
  });

  test('every message is filled in and keeps its placeholders', () {
    for (final key in keys) {
      final e = en[key]! as String;
      final s = si[key]! as String;
      expect(e.trim(), isNotEmpty, reason: key);
      expect(s.trim(), isNotEmpty, reason: key);
      final declared = _declared(en, key);
      expect(_placeholders(e, declared), declared, reason: key);
      expect(_placeholders(s, declared), declared, reason: key);
    }
  });

  test('Sinhala messages are actually translated', () {
    // Names, codes and a few technical words stay in Latin script.
    const latinAllowed = {
      'appName',
      'deleteAllConfirmWord',
      'currencyLkrSymbol',
    };
    final sinhala = RegExp('[඀-෿]');
    String words(String text) => text.replaceAll(RegExp(r'\{\w+\}'), '');
    final untranslated = [
      for (final key in keys)
        if (!latinAllowed.contains(key) &&
            RegExp('[A-Za-z]{3,}').hasMatch(words(en[key]! as String)) &&
            !sinhala.hasMatch(si[key]! as String))
          key,
    ];
    expect(untranslated, isEmpty);
  });
}
