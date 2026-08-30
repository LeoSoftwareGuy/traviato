import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/trip/presentation/widgets/trip_cover_image.dart';

import '../../fakes/fake_trip_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? imagePath,
  FakeTripRepository? tripRepo,
}) {
  return tester.pumpWidget(
    ProviderScope(
      // Matches the app's runApp(ProviderScope(retry: ...)) — without this,
      // a failing FutureProvider retries indefinitely instead of settling
      // into an error state (guidelines doc 02).
      retry: (_, _) => null,
      overrides: [
        if (tripRepo != null)
          tripRepositoryProvider.overrideWithValue(tripRepo),
      ],
      child: MaterialApp(
        home: Scaffold(body: TripCoverImage(imagePath: imagePath)),
      ),
    ),
  );
}

void main() {
  testWidgets('a bundled asset path renders Image.asset, no network', (
    tester,
  ) async {
    await _pump(tester, imagePath: 'asset:hero');
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
  });

  testWidgets('null shows the placeholder, no network', (tester) async {
    await _pump(tester);
    await tester.pump();

    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
  });

  testWidgets('a storage path resolves through getCoverImageUrl', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..getCoverImageUrlResult = const Right(
        'https://signed.example/cover.jpg',
      );

    await _pump(tester, imagePath: 'u1/t1/cover.jpg', tripRepo: tripRepo);
    await tester.pump();

    expect(tripRepo.getCoverImageUrlCallCount, 1);
  });

  testWidgets('a signing failure shows the broken-image state', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..getCoverImageUrlResult = const Left(NetworkFailure());

    await _pump(tester, imagePath: 'u1/t1/cover.jpg', tripRepo: tripRepo);
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
