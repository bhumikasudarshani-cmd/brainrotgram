import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:brainrotgram/api/api_client.dart';
import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/auth/auth_provider.dart';
import 'package:brainrotgram/features/player/reel_viewer_screen.dart';
import 'package:brainrotgram/features/profile/profile_screen.dart';

class FakeProfileApiService extends ApiService {
  final UserQuota? mockQuota;
  final List<VideoJob> readyVideos;
  final List<VideoJob> bookmarkedVideos;
  int getLibraryCalls = 0;
  List<Map<String, dynamic>> getLibraryParams = [];

  FakeProfileApiService({
    this.mockQuota,
    this.readyVideos = const [],
    this.bookmarkedVideos = const [],
  }) : super(_FakeProfileApiClient());

  @override
  Future<UserQuota> getQuota() async {
    return mockQuota ?? const UserQuota(used: 2, limit: 5, remaining: 3);
  }

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
    return VideoReview(jobId: jobId, version: 0);
  }

  @override
  Future<VideoJob> getVideo(String jobId) async {
    return VideoJob(
      jobId: jobId,
      state: 'ready',
      format: 'sketch',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, dynamic>> getLibrary({
    String? q,
    String? format,
    String? state,
    String? review,
    int limit = 12,
    String? cursor,
  }) async {
    getLibraryCalls++;
    getLibraryParams.add({
      'q': q,
      'format': format,
      'state': state,
      'review': review,
      'limit': limit,
      'cursor': cursor,
    });

    if (review == 'bookmarked') {
      return {
        'jobs': bookmarkedVideos
            .map((v) => {
                  'jobId': v.jobId,
                  'title': v.title,
                  'format': v.format,
                  'state': v.state,
                  'posterUrl': v.posterUrl,
                  'videoUrl': v.videoUrl,
                  'createdAt': v.createdAt.toIso8601String(),
                  'mediaExpired': v.mediaExpired,
                })
            .toList(),
        'nextCursor': null,
      };
    }

    return {
      'jobs': readyVideos
          .map((v) => {
                'jobId': v.jobId,
                'title': v.title,
                'format': v.format,
                'state': v.state,
                'posterUrl': v.posterUrl,
                'videoUrl': v.videoUrl,
                'createdAt': v.createdAt.toIso8601String(),
                'mediaExpired': v.mediaExpired,
              })
          .toList(),
      'nextCursor': null,
    };
  }
}

class _FakeProfileApiClient implements ApiClient {
  @override
  Dio get dio => Dio();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileScreen Widget', () {
    testWidgets('renders user info and live quota ring from GET /me',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeProfileApiService(
        mockQuota: const UserQuota(used: 2, limit: 5, remaining: 3),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
            authProvider.overrideWith((ref) => AuthNotifier()
              ..state = const AuthState(
                status: AuthStatus.authenticated,
                user: AuthUser(
                  name: 'Alice Developer',
                  email: 'alice@example.com',
                ),
              )),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // User details
      expect(find.text('Alice Developer'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);

      // Quota ring
      expect(find.text('3 of 5 free reels left'), findsOneWidget);
    });

    testWidgets('displays 3-column poster grid for ready videos',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testVideos = [
        VideoJob(
          jobId: 'vid-1',
          title: 'Binary Search',
          format: 'sketch',
          state: 'ready',
          createdAt: DateTime.now(),
        ),
        VideoJob(
          jobId: 'vid-2',
          title: 'Docker Layers',
          format: 'skit',
          state: 'ready',
          createdAt: DateTime.now(),
        ),
      ];

      final fakeApi = FakeProfileApiService(readyVideos: testVideos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // TabBar
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);

      // Videos rendered in grid
      expect(find.text('Binary Search'), findsOneWidget);
      expect(find.text('Docker Layers'), findsOneWidget);

      // Tapping a poster opens the ReelViewerScreen
      await tester.tap(find.text('Binary Search'));
      await tester.pumpAndSettle();

      expect(find.byType(ReelViewerScreen), findsOneWidget);
    });

    testWidgets('empty state displays when user has no videos', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeProfileApiService(readyVideos: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No videos yet'), findsOneWidget);
      expect(
        find.textContaining('Create a reel or send one from your agent'),
        findsOneWidget,
      );
    });

    testWidgets('Saved tab displays bookmarked videos or empty state',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeProfileApiService(
        readyVideos: [],
        bookmarkedVideos: [
          VideoJob(
            jobId: 'bookmarked-1',
            title: 'Memory Leaks in Node',
            format: 'prreview',
            state: 'ready',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Memory Leaks in Node'), findsOneWidget);
    });

    testWidgets('About row shows fan project statement and credits action',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeProfileApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(
        find.textContaining(
            'Unofficial, non-commercial fan project. Characters and gameplay belong to their owners; voices are AI clones.'),
        findsOneWidget,
      );
    });

    testWidgets('Sign out button triggers confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeProfileApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Sign out
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
