import 'dart:typed_data';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'support/fake_player.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:brainrotgram/api/api_client.dart';
import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/player/video_reel_item.dart';

/// Custom HttpClientAdapter that simulates a 409 conflict on the first PUT
/// and returns the server's version, then succeeds on retry (or fails if failOnRetry is true).
class Mock409HttpClientAdapter implements HttpClientAdapter {
  int putCalls = 0;
  List<Map<String, dynamic>> receivedPayloads = [];
  final bool failOnRetry;

  Mock409HttpClientAdapter({this.failOnRetry = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'PUT') {
      putCalls++;
      final data = options.data is Map
          ? (options.data as Map<String, dynamic>)
          : jsonDecode(options.data.toString()) as Map<String, dynamic>;
      receivedPayloads.add(Map<String, dynamic>.from(data));

      if (putCalls == 1) {
        // First call: 409 Conflict with server's version = 5
        final conflictJson = jsonEncode({
          'code': 'CONFLICT',
          'message': 'Review version mismatch',
          'review': {
            'jobId': 'job-conflict-1',
            'version': 5,
            'positionMs': 2000,
            'furthestMs': 2000,
            'completed': false,
            'bookmarked': false,
            'answers': {},
          },
        });
        return ResponseBody.fromString(
          conflictJson,
          409,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      } else if (putCalls == 2) {
        if (failOnRetry) {
          // Second call fails again: test that it does NOT loop
          final conflictJson = jsonEncode({
            'code': 'CONFLICT',
            'message': 'Still conflict',
            'review': {
              'jobId': 'job-conflict-1',
              'version': 6,
            },
          });
          return ResponseBody.fromString(
            conflictJson,
            409,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        // Retry succeeds with expectedVersion = 5
        final successJson = jsonEncode({
          'jobId': 'job-conflict-1',
          'version': 6,
          'positionMs': 2000,
          'furthestMs': 2000,
          'completed': false,
          'bookmarked': true,
          'answers': {},
        });
        return ResponseBody.fromString(
          successJson,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }

    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _TestApiClient implements ApiClient {
  @override
  final Dio dio;

  _TestApiClient(this.dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final previous = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = FakePlayer();
    addTearDown(() => VideoPlayerPlatform.instance = previous);
  });

  group('Review Conflict 409 Retry - ApiService', () {
    test('retries once with the server version on 409 conflict and succeeds',
        () async {
      final mockAdapter = Mock409HttpClientAdapter(failOnRetry: false);
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final apiService = ApiService(_TestApiClient(dio));

      final initialPatch = {
        'kind': 'bookmark',
        'expectedVersion': 1, // outdated version
        'value': true,
      };

      final result =
          await apiService.updateVideoReview('job-conflict-1', initialPatch);

      // Exactly 2 PUT calls: original call + single retry
      expect(mockAdapter.putCalls, 2);

      // First call sent expectedVersion = 1
      expect(mockAdapter.receivedPayloads[0]['expectedVersion'], 1);

      // Retry call sent server's expectedVersion = 5
      expect(mockAdapter.receivedPayloads[1]['expectedVersion'], 5);

      // Result reflects updated version
      expect(result.version, 6);
      expect(result.bookmarked, isTrue);
    });

    test('never loops if retry also fails with 409', () async {
      final mockAdapter = Mock409HttpClientAdapter(failOnRetry: true);
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final apiService = ApiService(_TestApiClient(dio));

      final initialPatch = {
        'kind': 'bookmark',
        'expectedVersion': 1,
        'value': true,
      };

      // Expect DioException on persistent 409
      expect(
        () => apiService.updateVideoReview('job-conflict-1', initialPatch),
        throwsA(isA<DioException>()),
      );

      // Verify it stopped after exactly 2 calls and did NOT loop infinitely
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockAdapter.putCalls, 2);
    });
  });

  group('Review Conflict 409 Retry - VideoReelItem Widget Test', () {
    testWidgets('user bookmark action retries once on 409 and updates state',
        (tester) async {
      final mockAdapter = Mock409HttpClientAdapter(failOnRetry: false);
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final testApiClient = _TestApiClient(dio);

      // Custom ApiService for widget test
      final widgetApiService = _WidgetTestApiService(
        testApiClient,
        review: const VideoReview(
          jobId: 'job-conflict-1',
          version: 1,
          bookmarked: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(widgetApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VideoReelItem(
                video: VideoJob(
                  jobId: 'job-conflict-1',
                  state: 'ready',
                  format: 'sketch',
                  videoUrl: 'https://example.com/test.mp4',
                  createdAt: DateTime.now(),
                ),
                isActive: true,
                onNextVideo: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Bookmark button initially shows unbookmarked icon
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      // User taps bookmark button
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify that updateVideoReview was invoked, retried with server version 5,
      // and widget state was updated to show bookmarked state
      expect(mockAdapter.putCalls, 2);
      expect(mockAdapter.receivedPayloads[0]['expectedVersion'], 1);
      expect(mockAdapter.receivedPayloads[1]['expectedVersion'], 5);

      // Bookmark icon changes to yellow filled bookmark icon
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });
}

class _WidgetTestApiService extends ApiService {
  final VideoReview review;

  _WidgetTestApiService(super.client, {required this.review});

  @override
  Future<Map<String, dynamic>> getLearningPack(String jobId) async {
    return {
      'schemaVersion': 'BrainrottenLearningPackV1',
      'jobId': jobId,
      'questions': [],
    };
  }

  @override
  Future<VideoReview> getVideoReview(String jobId) async {
    return review;
  }

  @override
  Future<VideoJob> getVideo(String jobId) async {
    return VideoJob(
      jobId: jobId,
      state: 'ready',
      format: 'sketch',
      videoUrl: 'https://example.com/test.mp4',
      createdAt: DateTime.now(),
    );
  }
}
