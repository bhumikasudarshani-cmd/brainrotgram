import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakePlayer extends VideoPlayerPlatform {
  final streams = <int, StreamController<VideoEvent>>{};
  final urls = <String?>[];
  final seeks = <Duration>[];
  int plays = 0, pauses = 0;

  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    final id = urls.length + 1;
    urls.add(options.dataSource.uri);
    streams[id] = StreamController<VideoEvent>.broadcast();

    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    scheduleMicrotask(() => streams[playerId]!.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(milliseconds: 215600),
        size: const Size(720, 1280))));
    return streams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    unawaited(streams[playerId]!.close());
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async { plays++; }
  @override
  Future<void> pause(int playerId) async { pauses++; }
  @override
  Future<void> seekTo(int playerId, Duration position) async { seeks.add(position); }
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}
