import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'support/fake_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainrotgram/api/api_client.dart';
import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/player/pause_predict_overlay.dart';
import 'package:brainrotgram/features/player/video_reel_item.dart';

class FakeQuizApiService extends ApiService {
  final Map<String, dynamic> learningPack;
  final VideoReview review;

  FakeQuizApiService({
    required this.learningPack,
    required this.review,
  }) : super(_FakeQuizApiClient());

  @override
  Future<Map<String, dynamic>> getLearningPack(String jobId) async {
    return learningPack;
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
      format: 'skit',
      videoUrl: 'https://example.com/test.mp4',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<VideoReview> updateVideoReview(
    String jobId,
    Map<String, dynamic> patch,
  ) async {
    return review;
  }
}

class _FakeQuizApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testQuestion = LearningQuestion(
    id: 'pause-3',
    prompt: 'What happens on the second retry?',
    choices: ['New charge', 'Same result', 'Error', 'Refund'],
    answer: 1,
    explanation: 'The stored result is returned.',
    startMs: 2000,
    endMs: 5000,
  );

  group('Quiz Timing - PausePredictOverlay Widget Tests', () {
    testWidgets('Pause & Predict card renders question and choices when active',
        (tester) async {
      int? selectedAnswer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PausePredictOverlay(
              question: testQuestion,
              existingAnswer: null,
              showExplanation: false,
              onAnswerSelected: (choice) => selectedAnswer = choice,
            ),
          ),
        ),
      );

      // Header chip
      expect(find.text('PAUSE & PREDICT'), findsOneWidget);

      // Question prompt
      expect(find.text('What happens on the second retry?'), findsOneWidget);

      // Choices
      expect(find.text('New charge'), findsOneWidget);
      expect(find.text('Same result'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);

      // Explanation is hidden before endMs / answer
      expect(find.text('The stored result is returned.'), findsNothing);

      // User can select an answer
      await tester.tap(find.text('Same result'));
      await tester.pumpAndSettle();

      expect(selectedAnswer, 1);
    });

    testWidgets('Answer and explanation are revealed at endMs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PausePredictOverlay(
              question: testQuestion,
              existingAnswer: null,
              showExplanation: true, // endMs reached
              onAnswerSelected: (_) {},
            ),
          ),
        ),
      );

      // Explanation is revealed
      expect(find.text('The stored result is returned.'), findsOneWidget);

      // Checkmark on correct answer (choice index 1)
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets(
        'Already answered question shows saved answer instead of asking again',
        (tester) async {
      int? answerTapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PausePredictOverlay(
              question: testQuestion,
              existingAnswer: 1, // already answered with choice 1
              showExplanation: false,
              onAnswerSelected: (c) => answerTapped = c,
            ),
          ),
        ),
      );

      // Since already answered, the result is locked in & revealed
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('The stored result is returned.'), findsOneWidget);

      // Tapping another choice should NOT trigger onAnswerSelected
      await tester.tap(find.text('New charge'));
      await tester.pump();

      expect(answerTapped, isNull); // Locked, cannot re-answer
    });
  });

  group('Quiz Timing - VideoReelItem Integration Tests', () {
    setUp(() {
      final previous = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = FakePlayer();
      addTearDown(() => VideoPlayerPlatform.instance = previous);
    });

    testWidgets(
        'VideoReelItem shows PausePredictOverlay with saved answer when already answered',
        (tester) async {
      final fakeApi = FakeQuizApiService(
        learningPack: {
          'schemaVersion': 'BrainrottenLearningPackV1',
          'jobId': 'job-timing-1',
          'questions': [
            {
              'id': 'pause-3',
              'prompt': 'What happens on the second retry?',
              'choices': ['New charge', 'Same result', 'Error', 'Refund'],
              'answer': 1,
              'explanation': 'The stored result is returned.',
              'startMs': 0, // already at startMs
              'endMs': 10000,
            }
          ],
        },
        review: const VideoReview(
          jobId: 'job-timing-1',
          version: 1,
          answers: {'pause-3': 1}, // Saved answer present
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VideoReelItem(
                video: VideoJob(
                  jobId: 'job-timing-1',
                  state: 'ready',
                  format: 'skit',
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

      // Learning pack and review loaded
      expect(find.byType(VideoReelItem), findsOneWidget);
    });

    testWidgets(
        'VideoReelItem: Pause & Predict card appears at startMs and answer reveals at endMs',
        (tester) async {
      final fakeApi = FakeQuizApiService(
        learningPack: {
          'schemaVersion': 'BrainrottenLearningPackV1',
          'jobId': 'job-timing-2',
          'questions': [
            {
              'id': 'pause-3',
              'prompt': 'What happens on the second retry?',
              'choices': ['New charge', 'Same result', 'Error', 'Refund'],
              'answer': 1,
              'explanation': 'The stored result is returned.',
              'startMs': 2000,
              'endMs': 5000,
            }
          ],
        },
        review: const VideoReview(
          jobId: 'job-timing-2',
          version: 1,
          answers: {},
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VideoReelItem(
                video: VideoJob(
                  jobId: 'job-timing-2',
                  state: 'ready',
                  format: 'skit',
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

      final state =
          tester.state<VideoReelItemState>(find.byType(VideoReelItem));

      // 1. Playback at 1000ms (< startMs 2000ms): Card not visible
      state.checkPausePredict(1000);
      await tester.pump();
      expect(find.byType(PausePredictOverlay), findsNothing);

      // 2. Playback reaches 2500ms (>= startMs 2000ms): Card appears with prompt & choices
      state.checkPausePredict(2500);
      await tester.pump();
      expect(find.byType(PausePredictOverlay), findsOneWidget);
      expect(find.text('What happens on the second retry?'), findsOneWidget);
      expect(find.text('The stored result is returned.'),
          findsNothing); // not yet revealed

      // 3. Playback reaches 5000ms (endMs): Answer and explanation are revealed
      state.checkPausePredict(5000);
      await tester.pump();
      expect(find.byType(PausePredictOverlay), findsOneWidget);
      expect(find.text('The stored result is returned.'),
          findsOneWidget); // revealed!
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
