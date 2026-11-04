import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/player/video_reel_item.dart';

import 'quiz_timing_test.dart' show FakeQuizApiService;
import 'support/fake_player.dart';

class RetryApi extends FakeQuizApiService {
  int refreshes = 0;
  final bool expired;
  final Completer<VideoJob>? pending;
  RetryApi({this.expired = false, this.pending})
      : super(
          learningPack: {'questions': []},
          review: const VideoReview(jobId: 'fixture-job', version: 0),
        );

  @override
  Future<VideoJob> getVideo(String jobId) async {
    refreshes++;
    return pending?.future ??
        Future.value(VideoJob(
            jobId: jobId,
            state: 'ready',
            format: 'sketch',
            createdAt: DateTime(2026),
            mediaExpired: expired,
            videoUrl: expired ? null : 'https://example.invalid/fresh.mp4'));
  }
}

void main() {
  testWidgets('runtime playback errors refresh once then show an error',
      (tester) async {
    final platform = FakePlayer();
    final oldPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = oldPlatform);
    final api = RetryApi();
    await tester.pumpWidget(ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: MaterialApp(
            home: Scaffold(
                body: VideoReelItem(
          video: VideoJob(
              jobId: 'fixture-job',
              state: 'ready',
              format: 'sketch',
              createdAt: DateTime(2026),
              videoUrl: 'https://example.invalid/stale.mp4'),
          isActive: false,
          onNextVideo: () {},
        )))));
    await tester.pumpAndSettle();
    platform.streams[1]!
        .addError(PlatformException(code: '403', message: 'Expired'));
    await tester.pumpAndSettle();
    expect(api.refreshes, 1);
    expect(platform.urls, [
      'https://example.invalid/stale.mp4',
      'https://example.invalid/fresh.mp4'
    ]);
    platform.streams[2]!
        .addError(PlatformException(code: '403', message: 'Still expired'));
    await tester.pumpAndSettle();
    expect(api.refreshes, 1);
    expect(find.text('Unable to play video'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('refresh finishing after disposal creates no player',
      (tester) async {
    final platform = FakePlayer();
    final oldPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = oldPlatform);
    final pending = Completer<VideoJob>();
    final api = RetryApi(pending: pending);
    await tester.pumpWidget(ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: MaterialApp(
            home: Scaffold(
                body: VideoReelItem(
          video: VideoJob(
              jobId: 'fixture-job',
              state: 'ready',
              format: 'sketch',
              createdAt: DateTime(2026)),
          isActive: false,
          onNextVideo: () {},
        )))));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete(VideoJob(
        jobId: 'fixture-job',
        state: 'ready',
        format: 'sketch',
        createdAt: DateTime(2026),
        videoUrl: 'https://example.invalid/fresh.mp4'));
    await tester.pumpAndSettle();
    expect(platform.urls, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
