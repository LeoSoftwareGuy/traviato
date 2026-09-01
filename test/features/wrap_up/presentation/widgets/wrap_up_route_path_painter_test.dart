import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/widgets/wrap_up_route_path_painter.dart';

void main() {
  group('layoutRoutePoints', () {
    const size = Size(320, 260);

    test(
      'a single stop (e.g. a trip that never left one place) is one centered point',
      () {
        final points = layoutRoutePoints(1, size);

        expect(points.length, 1);
        expect(points.single.dx, size.width / 2);
      },
    );

    test('zero stops (no location data) is an empty list', () {
      expect(layoutRoutePoints(0, size), isEmpty);
    });

    test('multiple stops span the panel width in order', () {
      final points = layoutRoutePoints(4, size);

      expect(points.length, 4);
      expect(points.first.dx, lessThan(points.last.dx));
      for (final p in points) {
        expect(p.dx, inInclusiveRange(0, size.width));
      }
    });
  });
}
