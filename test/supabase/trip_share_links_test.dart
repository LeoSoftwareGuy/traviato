import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the share-links migration (#309). The behaviour is
/// covered by supabase/tests/database/trip_share_links.test.sql (pgTAP,
/// `supabase test db`).
void main() {
  late String sql;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_create_trip_share_links.sql'));
    sql = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
  });

  test('RLS on, nothing granted to anon on the table', () {
    expect(
      sql,
      contains('alter table public.trip_share_links enable row level security'),
    );
    expect(
      sql,
      contains(
        'revoke all on public.trip_share_links from anon, authenticated',
      ),
    );
    expect(sql, isNot(contains('on public.trip_share_links to anon')));
  });

  test('clients may only update revoked_at', () {
    expect(
      sql,
      contains('grant update (revoked_at) on public.trip_share_links'),
    );
  });

  test('only the preview RPC is open to anon', () {
    final anonGrants = RegExp(
      r'grant execute on function public\.(\w+)\([^)]*\)\s+to anon',
    ).allMatches(sql).map((m) => m.group(1)).toList();
    expect(anonGrants, ['get_shared_memory_preview']);
  });

  test('the preview bucket is public and JPEG-only', () {
    expect(sql, contains("'share-previews', 'share-previews', true"));
    expect(sql, contains("'{image/jpeg}'"));
  });
}
