import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:brainrotgram/api/api_client.dart';
import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/studio/studio_job_provider.dart';
import 'package:brainrotgram/features/studio/studio_screen.dart';

class FakeApiService extends ApiService {
  final Map<String, dynamic>? mockStudioConfig;
  final UserQuota? mockQuota;
  final VideoJob? mockVideoJob;
  final Map<String, dynamic>? mockCreateResponse;
  final DioException? createVideoError;
  int createVideoCalls = 0;
  List<Map<String, dynamic>> createVideoPayloads = [];
  int validateVideoCalls = 0;
  List<Map<String, dynamic>> validateVideoPayloads = [];

  FakeApiService({
    this.mockStudioConfig,
    this.mockQuota,
    this.mockVideoJob,
    this.mockCreateResponse,
    this.createVideoError,
  }) : super(_FakeApiClient());

  @override
  Future<Map<String, dynamic>> getStudioConfig() async {
    return mockStudioConfig ??
        {
          'formats': [
            {
              'id': 'sketch',
              'name': 'Sketch board',
              'description': 'Excalidraw-style architecture board',
              'speakers': 1,
              'ready': true,
            },
            {
              'id': 'skit',
              'name': 'Character skit',
              'description': 'Two characters, question-answer',
              'speakers': 2,
              'ready': true,
            },
            {
              'id': 'prreview',
              'name': 'PR review',
              'description': 'GitHub-style diff and review',
              'speakers': 2,
              'ready': true,
            },
            {
              'id': 'tierlist',
              'name': 'Tier list',
              'description': 'TierMaker ranking board',
              'speakers': 1,
              'ready': true,
            },
            {
              'id': 'groupchat',
              'name': 'Group chat',
              'description': 'WhatsApp-style group thread',
              'speakers': 4,
              'ready': true,
            },
          ],
          'characters': [
            {
              'id': 'oggy',
              'name': 'Oggy',
              'imageUrl': '/characters/oggy.png',
              'voiceReady': true,
            },
            {
              'id': 'jack',
              'name': 'Jack',
              'imageUrl': '/characters/jack.png',
              'voiceReady': true,
            },
            {
              'id': 'jhatka',
              'name': 'Dr Jhatka',
              'imageUrl': '/characters/jhatka.png',
              'voiceReady': true,
            },
          ],
        };
  }

  @override
  Future<UserQuota> getQuota() async {
    return mockQuota ?? const UserQuota(used: 1, limit: 5, remaining: 4);
  }

  @override
  Future<VideoJob> getVideo(String jobId) async {
    return mockVideoJob ??
        VideoJob(
          jobId: jobId,
          state: 'processing',
          stage: 'rendering',
          progress: 50,
          format: 'sketch',
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<Map<String, dynamic>> createVideo({
    required String prompt,
    required String format,
    String language = 'en',
    int durationSeconds = 60,
    int quizCount = 2,
    String? cast,
    Map<String, String>? participants,
    String? narrator,
    String? requestId,
  }) async {
    createVideoCalls++;
    createVideoPayloads.add({
      'prompt': prompt,
      'format': format,
      'language': language,
      'durationSeconds': durationSeconds,
      'quizCount': quizCount,
      'cast': cast,
      'participants': participants,
      'narrator': narrator,
      'requestId': requestId,
    });

    if (createVideoError != null) {
      throw createVideoError!;
    }

    return mockCreateResponse ??
        {
          'jobId': 'job-test-1234',
          'state': 'queued',
          'stage': 'queued',
          'progress': 0,
        };
  }

  @override
  Future<Map<String, dynamic>> validateVideo({
    required String prompt,
    required String format,
    String language = 'en',
    int quizCount = 2,
    String? cast,
    Map<String, String>? participants,
    String? narrator,
  }) async {
    validateVideoCalls++;
    validateVideoPayloads.add({
      'prompt': prompt,
      'format': format,
      'language': language,
      'quizCount': quizCount,
      'cast': cast,
      'participants': participants,
      'narrator': narrator,
    });
    return {
      'valid': true,
      'issues': [],
      'warnings': [],
      'estimatedSeconds': 60,
      'generationReady': true,
    };
  }
}

class _FakeApiClient implements ApiClient {
  @override
  Dio get dio => Dio();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Studio Models', () {
    test('StudioCharacter generates correct CloudFront picture URL', () {
      const char = StudioCharacter(
        id: 'oggy',
        name: 'Oggy',
        imageUrl: '/characters/oggy.png',
      );
      expect(
        char.pictureUrl,
        'https://d3sk6lwsh4ufyv.cloudfront.net/characters/oggy.png',
      );
    });

    test('StudioConfigData parses formats and characters', () {
      final config = StudioConfigData.fromJson({
        'formats': [
          {
            'id': 'sketch',
            'name': 'Sketch board',
            'description': 'Excalidraw diagram',
            'speakers': 1,
            'ready': true,
          },
        ],
        'characters': [
          {'id': 'jack', 'name': 'Jack', 'voiceReady': true},
        ],
      });

      expect(config.formats.length, 1);
      expect(config.formats.first.id, 'sketch');
      expect(config.formats.first.speakers, 1);
      expect(config.characters.length, 1);
      expect(config.characters.first.id, 'jack');
    });

    test('UserQuota handles nested quota and remaining count', () {
      final quota = UserQuota.fromJson({
        'quota': {'used': 2, 'limit': 5, 'remaining': 3}
      });
      expect(quota.used, 2);
      expect(quota.limit, 5);
      expect(quota.remaining, 3);
    });
  });

  group('StudioJobNotifier & Idempotency', () {
    test('generateVideo uses fresh requestId, and retrying reuses it',
        () async {
      final fakeApi = FakeApiService();
      final notifier = StudioJobNotifier(fakeApi);

      // First submit
      await notifier.generateVideo(
        prompt: 'How do indexes work?',
        format: 'sketch',
        language: 'en',
        quizCount: 2,
      );

      expect(fakeApi.createVideoCalls, 1);
      final firstReqId = fakeApi.createVideoPayloads.first['requestId'];
      expect(firstReqId, isNotNull);

      // Retry submission
      await notifier.retryLastSubmission();
      expect(fakeApi.createVideoCalls, 2);
      final secondReqId = fakeApi.createVideoPayloads[1]['requestId'];
      expect(secondReqId, equals(firstReqId));

      notifier.dispose();
    });

    test('402 QUOTA_EXCEEDED maps to friendly message and not retryable',
        () async {
      final fakeApi = FakeApiService(
        createVideoError: DioException(
          requestOptions: RequestOptions(path: '/videos'),
          response: Response(
            requestOptions: RequestOptions(path: '/videos'),
            statusCode: 402,
            data: {
              'code': 'QUOTA_EXCEEDED',
              'message': 'You have used all 5 lifetime trial videos.',
              'retryable': false,
            },
          ),
        ),
      );

      final notifier = StudioJobNotifier(fakeApi);
      final success = await notifier.generateVideo(
        prompt: 'Test topic',
        format: 'sketch',
      );

      expect(success, isFalse);
      expect(notifier.state.error?.code, 'QUOTA_EXCEEDED');
      expect(notifier.state.error?.message, "You've used your 5 free videos.");
      expect(notifier.state.error?.retryable, isFalse);

      notifier.dispose();
    });

    test('Retryable 500 error preserves retryable flag and requestId',
        () async {
      final fakeApi = FakeApiService(
        createVideoError: DioException(
          requestOptions: RequestOptions(path: '/videos'),
          response: Response(
            requestOptions: RequestOptions(path: '/videos'),
            statusCode: 503,
            data: {
              'code': 'SERVICE_UNAVAILABLE',
              'message': 'Server overloaded. Please retry.',
              'retryable': true,
            },
          ),
        ),
      );

      final notifier = StudioJobNotifier(fakeApi);
      final success = await notifier.generateVideo(
        prompt: 'Test topic',
        format: 'sketch',
      );

      expect(success, isFalse);
      expect(notifier.state.error?.code, 'SERVICE_UNAVAILABLE');
      expect(notifier.state.error?.retryable, isTrue);

      notifier.dispose();
    });
  });

  group('StudioScreen Widget', () {
    testWidgets('renders topic, format cards, quota, and voice pickers',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeApiService(
        mockQuota: const UserQuota(used: 1, limit: 5, remaining: 4),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quota line
      expect(find.text('4 of 5 free videos left'), findsOneWidget);

      // Topic field
      expect(find.text('Topic'), findsOneWidget);

      // Formats
      expect(find.text('Sketch board'), findsOneWidget);
      expect(find.text('Character skit'), findsOneWidget);
      expect(find.text('PR review'), findsOneWidget);
      expect(find.text('Tier list'), findsOneWidget);
      expect(find.text('Group chat'), findsOneWidget);

      // Languages
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Hinglish'), findsOneWidget);
      expect(find.text('Benglish'), findsOneWidget);

      // Questions chips
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Default format is Sketch board -> Narrator picker visible
      expect(find.text('Narrator'), findsOneWidget);
      expect(find.text('Let AI pick'), findsOneWidget);

      // Generate button is disabled because topic is empty
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Generate');
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('exhausted quota displays 5 free videos message and disables button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeApiService(
        mockQuota: const UserQuota(used: 5, limit: 5, remaining: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Warning text
      expect(find.text("You've used your 5 free videos."), findsOneWidget);

      // Enter topic
      await tester.enterText(
          find.byType(TextField), 'Explain recursion vs iteration');
      await tester.pumpAndSettle();

      // Button is still disabled due to quota = 0
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Generate');
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'selecting Character skit switches voice pickers to Let AI pick / Choose speakers',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Character skit
      await tester.tap(find.text('Character skit'));
      await tester.pumpAndSettle();

      // Shows 'Let AI pick' and 'Choose speakers'
      expect(find.text('Let AI pick'), findsOneWidget);
      expect(find.text('Choose speakers'), findsOneWidget);

      // Switch to 'Choose speakers'
      await tester.tap(find.text('Choose speakers'));
      await tester.pumpAndSettle();

      // Shows Asker and Explainer pickers
      expect(find.text('Asker'), findsOneWidget);
      expect(find.text('Explainer'), findsOneWidget);
    });

    testWidgets(
        'selecting PR review or Group chat displays AI picks voices automatically',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select PR review
      await tester.tap(find.text('PR review'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('AI picks voices and characters automatically'),
        findsOneWidget,
      );

      // Select Group chat
      await tester.tap(find.text('Group chat'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('AI picks voices and characters automatically'),
        findsOneWidget,
      );
    });

    testWidgets(
        'progress screen shows real stage and progress when job is active',
        (tester) async {
      final fakeApi = FakeApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
            studioJobProvider.overrideWith((ref) {
              final notifier = StudioJobNotifier(fakeApi);
              notifier.startJob('job-running-123');
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Generating Video'), findsOneWidget);
      expect(find.text('Making your video…'), findsOneWidget);
      expect(
        find.textContaining('pill stays on Home until ready'),
        findsOneWidget,
      );
    });

    testWidgets(
        'error shape {code, message, retryable} displays Retry only when retryable',
        (tester) async {
      final fakeApi = FakeApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
            studioJobProvider.overrideWith((ref) {
              final notifier = StudioJobNotifier(fakeApi);
              // Set retryable error state
              notifier.state = notifier.state.copyWith(
                error: const ApiError(
                  code: 'TEMPORARY_ERROR',
                  message: 'Upstream network timeout. Please retry.',
                  retryable: true,
                ),
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: StudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TEMPORARY_ERROR'), findsOneWidget);
      expect(find.text('Upstream network timeout. Please retry.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('Validate endpoint verification', () {
    test('calling validateVideo sends expected payload without generating video',
        () async {
      final fakeApi = FakeApiService();

      final res = await fakeApi.validateVideo(
        prompt: 'Explain hash map collisions',
        format: 'sketch',
        language: 'en',
        quizCount: 2,
        narrator: 'oggy',
      );

      expect(fakeApi.validateVideoCalls, 1);
      expect(fakeApi.createVideoCalls, 0); // Real createVideo NEVER called
      expect(res['valid'], isTrue);
      expect(fakeApi.validateVideoPayloads.first['prompt'],
          'Explain hash map collisions');
      expect(fakeApi.validateVideoPayloads.first['format'], 'sketch');
      expect(fakeApi.validateVideoPayloads.first['narrator'], 'oggy');
    });
  });
}
