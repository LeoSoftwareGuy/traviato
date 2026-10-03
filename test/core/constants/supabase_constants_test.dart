import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against client code calling an RPC that no migration creates
/// (#175: `delete_photo` "could not find function"). Reads the sources rather
/// than the constants so a newly added `DBFunctions` entry is picked up
/// automatically.
void main() {
  test('every DBFunctions RPC is created by a migration', () {
    final constants = File(
      'lib/core/constants/supabase_constants.dart',
    ).readAsStringSync();
    final block = RegExp(
      r'abstract class DBFunctions \{([^}]*)\}',
    ).firstMatch(constants)!.group(1)!;
    final rpcNames = RegExp(
      r"static const \w+ = '(\w+)';",
    ).allMatches(block).map((m) => m.group(1)!).toList();
    expect(rpcNames, isNotEmpty);

    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .map((f) => f.readAsStringSync().toLowerCase())
        .join('\n');

    for (final name in rpcNames) {
      expect(
        RegExp(
          r'create (or replace )?function (public\.)?' + name + r'\(',
        ).hasMatch(migrations),
        isTrue,
        reason: 'RPC `$name` is in DBFunctions but no migration creates it',
      );
    }
  });
}
