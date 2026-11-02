import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/share/data/datasources/share_remote_data_source.dart';
import 'package:traviato/features/share/data/models/share_link_model.dart';
import 'package:traviato/features/share/data/repositories/share_repository_impl.dart';
import 'package:traviato/features/share/data/services/share_image_service.dart';
import 'package:traviato/features/share/domain/entities/og_card_content.dart';

import '../../photo/fakes/fake_photo_repository.dart';

class _FakeRemote implements ShareRemoteDataSource {
  final uploads = <String, Uint8List>{};
  final removed = <String>[];
  final calls = <String>[];
  (String, int)? marked;
  AppException? revokeError;
  AppException? removeError;

  @override
  Future<ShareLinkModel> createLink(String tripId) async => _link();

  @override
  Future<ShareLinkModel?> getActiveLink(String tripId) async => null;

  @override
  Future<void> revokeLink(String tripId) async {
    calls.add('revoke $tripId');
    if (revokeError != null) throw revokeError!;
  }

  @override
  Future<Uint8List> downloadPhoto(String storagePath) async =>
      Uint8List.fromList(storagePath.codeUnits);

  @override
  Future<void> uploadPreviewFile(String path, Uint8List bytes) async {
    calls.add('upload $path');
    uploads[path] = bytes;
  }

  @override
  Future<void> removePreviewFiles(List<String> paths) async {
    calls.add('remove');
    if (removeError != null) throw removeError!;
    removed.addAll(paths);
  }

  @override
  Future<void> markPreviewBuilt(String linkId, int photoCount) async {
    calls.add('mark');
    marked = (linkId, photoCount);
  }
}

/// Tags bytes instead of encoding, so the test can see what went where.
class _FakeImages implements ShareImageService {
  Uint8List? ogCover;

  @override
  Future<Uint8List> downscale(Uint8List bytes) async =>
      Uint8List.fromList([...'small:'.codeUnits, ...bytes]);

  @override
  Future<Uint8List> renderOgCard({
    Uint8List? cover,
    required OgCardContent content,
  }) async {
    ogCover = cover;
    return Uint8List.fromList('og:${content.title}'.codeUnits);
  }
}

ShareLinkModel _link({int previewPhotoCount = 0}) => ShareLinkModel(
  id: 'l1',
  tripId: 't1',
  slug: 'k7Qm2xPa9c',
  createdAt: DateTime.utc(2026, 11, 2),
  previewPhotoCount: previewPhotoCount,
);

const _og = OgCardContent(title: 'One long road', eyebrow: 'HIGHLANDS');

void main() {
  late _FakeRemote remote;
  late _FakeImages images;
  late ShareRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    images = _FakeImages();
    repo = ShareRepositoryImpl(remote: remote, images: images);
  });

  group('buildPreview (#309)', () {
    test(
      'uploads downscaled copies in order, og.jpg, then marks built',
      () async {
        final result = await repo.buildPreview(
          link: _link(),
          photos: [
            buildPhotoEntity(id: 'a', storagePath: 'u/t/a.jpg'),
            buildPhotoEntity(id: 'b', storagePath: 'u/t/b.jpg'),
          ],
          og: _og,
        );

        expect(result.isRight(), isTrue);
        expect(remote.calls, [
          'upload k7Qm2xPa9c/0.jpg',
          'upload k7Qm2xPa9c/1.jpg',
          'upload k7Qm2xPa9c/og.jpg',
          'mark',
        ]);
        expect(
          String.fromCharCodes(remote.uploads['k7Qm2xPa9c/1.jpg']!),
          'small:u/t/b.jpg',
        );
        expect(String.fromCharCodes(images.ogCover!), 'small:u/t/a.jpg');
        expect(remote.marked, ('l1', 2));
      },
    );

    test('removes teaser files a bigger earlier build left', () async {
      await repo.buildPreview(
        link: _link(previewPhotoCount: 4),
        photos: [buildPhotoEntity(id: 'a', storagePath: 'u/t/a.jpg')],
        og: _og,
      );
      expect(remote.removed, [
        'k7Qm2xPa9c/1.jpg',
        'k7Qm2xPa9c/2.jpg',
        'k7Qm2xPa9c/3.jpg',
      ]);
      expect(remote.marked, ('l1', 1));
    });

    test('no photos: og.jpg without a cover, built with 0', () async {
      await repo.buildPreview(link: _link(), photos: [], og: _og);
      expect(remote.calls, ['upload k7Qm2xPa9c/og.jpg', 'mark']);
      expect(images.ogCover, isNull);
      expect(remote.marked, ('l1', 0));
    });
  });

  group('revokeLink (#309)', () {
    test('revokes, then removes every preview file', () async {
      final result = await repo.revokeLink(_link());
      expect(result.isRight(), isTrue);
      expect(remote.calls, ['revoke t1', 'remove']);
      expect(remote.removed, sharePreviewFiles('k7Qm2xPa9c'));
      expect(remote.removed, hasLength(7));
    });

    test('a failed file removal still counts as revoked', () async {
      remote.removeError = const StorageServerException(message: 'down');
      expect((await repo.revokeLink(_link())).isRight(), isTrue);
    });

    test('a failed revoke keeps the files and fails', () async {
      remote.revokeError = const NetworkException();
      final result = await repo.revokeLink(_link());
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      expect(remote.calls, ['revoke t1']);
    });
  });
}
