import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_music.dart';

/// Records what the music asked of the player; its position is set by
/// the test.
class FakeSkyMusicPlayer implements SkyMusicPlayer {
  FakeSkyMusicPlayer({this.failLoad = false});

  final bool failLoad;
  final calls = <String>[];
  final seeks = <double>[];
  final volumes = <double>[];
  bool playing = false;
  bool disposed = false;
  double positionS = 0;

  @override
  Future<void> load() async {
    calls.add('load');
    if (failLoad) throw Exception('no track');
  }

  @override
  Future<void> play() async {
    calls.add('play');
    playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position.inMicroseconds / 1e6);
    positionS = position.inMicroseconds / 1e6;
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Duration get position => Duration(microseconds: (positionS * 1e6).round());

  @override
  Future<void> dispose() async => disposed = true;
}
