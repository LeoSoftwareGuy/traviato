import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// What the film's music needs from an audio player (#345, phase 5): a
/// seam so tests drive a fake and the film never depends on a plugin.
abstract interface class SkyMusicPlayer {
  /// Loads the track; throws if it can't.
  Future<void> load();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Duration get position;
  Future<void> dispose();
}

/// The film's track, played by just_audio from the bundled asset.
///
/// The audio session is "ambient": the iPhone's silent switch mutes it and
/// it mixes with whatever else is playing instead of stopping it; the
/// player never takes audio focus.
class JustAudioSkyMusicPlayer implements SkyMusicPlayer {
  JustAudioSkyMusicPlayer({this.asset = defaultAsset});

  static const defaultAsset = 'assets/audio/sky_story_upbeat.m4a';

  final String asset;
  final _player = AudioPlayer(handleAudioSessionActivation: false);

  @override
  Future<void> load() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: false,
      ),
    );
    await _player.setAsset(asset);
  }

  @override
  Future<void> play() async {
    // just_audio's play() completes when playback stops; don't wait.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Duration get position => _player.position;

  @override
  Future<void> dispose() => _player.dispose();
}

/// Keeps the music on the film clock: plays from 0 with the film, fades in
/// and out, pauses and resumes with it, starts again when it loops, and
/// pulls the audio back when it drifts. Any failure (no track, a decode
/// error) is logged once and the film goes on silent.
class SkyStoryMusic {
  SkyStoryMusic(this._player, {required this.filmLength}) {
    _ready = _load();
  }

  final SkyMusicPlayer _player;

  /// The film's length, s: the fade-out ends here.
  final double filmLength;

  static const fadeIn = 0.4;
  static const fadeOut = 2.5;

  /// How far the audio may wander from the picture before it is pulled
  /// back, and how soon after a seek it may be pulled again.
  static const maxDrift = 0.12;
  static const seekCooldown = 0.5;

  late final Future<void> _ready;
  bool _loaded = false;
  bool _failed = false;
  bool _disposed = false;
  bool _playing = false;
  bool _muted = false;
  double _volume = -1;
  double _lastT = 0;
  double? _lastSeekAt;

  /// Whether the track failed and the film is silent.
  bool get failed => _failed;

  bool get muted => _muted;
  set muted(bool value) {
    _muted = value;
    _applyVolume(_lastT);
  }

  /// Resolves once the track has loaded (or failed).
  Future<void> get ready => _ready;

  /// The music's loudness at film time [t] (0–1), before muting.
  static double volumeAt(double t, double filmLength) {
    if (t <= 0 || t >= filmLength) return 0;
    final rampIn = (t / fadeIn).clamp(0.0, 1.0);
    final rampOut = ((filmLength - t) / fadeOut).clamp(0.0, 1.0);
    return rampIn < rampOut ? rampIn : rampOut;
  }

  Future<void> _load() async {
    try {
      await _player.load();
      _loaded = true;
    } catch (e) {
      _fail('load', e);
    }
  }

  void _fail(String what, Object error) {
    if (_failed) return;
    _failed = true;
    debugPrint('Sky Story music $what failed; the film plays silent: $error');
  }

  /// Called every frame with the film's time [t] and whether it is
  /// running.
  void sync(double t, {required bool running}) {
    if (_disposed || _failed || !_loaded) {
      _lastT = t;
      return;
    }
    final looped = t + 1 < _lastT;
    _lastT = t;
    _applyVolume(t);
    if (!running) {
      if (_playing) {
        _playing = false;
        _guard('pause', _player.pause());
      }
      return;
    }
    if (!_playing || looped) {
      _seekTo(t);
      if (!_playing) {
        _playing = true;
        _guard('play', _player.play());
      }
      return;
    }
    final drift = (_player.position.inMicroseconds / 1e6 - t).abs();
    final cooled =
        _lastSeekAt == null || (t - _lastSeekAt!).abs() >= seekCooldown;
    if (drift > maxDrift && cooled) _seekTo(t);
  }

  /// Stops the music until the film runs again (the app was hidden).
  void pause() {
    if (_disposed || _failed || !_loaded || !_playing) return;
    _playing = false;
    _guard('pause', _player.pause());
  }

  void _seekTo(double t) {
    _lastSeekAt = t;
    _guard(
      'seek',
      _player.seek(Duration(microseconds: (t * 1e6).round())),
    );
  }

  void _applyVolume(double t) {
    if (_disposed || _failed || !_loaded) return;
    final volume = _muted ? 0.0 : volumeAt(t, filmLength);
    if ((volume - _volume).abs() < 0.01 &&
        !(volume == 0 && _volume != 0) &&
        !(volume == 1 && _volume != 1)) {
      return;
    }
    _volume = volume;
    _guard('volume', _player.setVolume(volume));
  }

  void _guard(String what, Future<void> call) {
    unawaited(call.catchError((Object e) => _fail(what, e)));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('Sky Story music dispose failed: $e');
    }
  }
}
