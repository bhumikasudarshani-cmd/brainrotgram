import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainrotgram/api/api_service.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/home/home_screen.dart';
import 'package:brainrotgram/features/search/search_screen.dart';
import 'package:brainrotgram/features/sessions/session_detail_screen.dart';
import 'package:brainrotgram/theme/app_theme.dart';
import 'profile_screen_test.dart' show FakeProfileApiService;

Map<String, dynamic> video(String title, {String? sessionId}) => {
      'jobId': title,
      'title': title,
      'sessionId': sessionId,
      'state': 'ready',
      'format': 'sketch',
      'createdAt': '2026-11-04T00:00:00.000Z',
      'durationSeconds': 215.6
    };
Map<String, dynamic> session = {
  'sessionId': 's1',
  'projectName': 'weather-app',
  'agent': 'Agent',
  'title': 'Fix disposal race',
  'objective': 'Keep async state updates inside the widget lifetime.',
  'createdAt': '2026-11-04T00:00:00.000Z'
};

class WorkApi extends FakeProfileApiService {
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> videos;
  final calls = <Map<String, dynamic>>[];
  final pending = <String, Completer<Map<String, dynamic>>>{};
  Map<String, dynamic>? saved;
  WorkApi({this.sessions = const [], this.videos = const []});
  @override
  Future<List<VideoJob>> getVideos() async =>
      videos.map(VideoJob.fromJson).toList();
  @override
  Future<Map<String, dynamic>> getSessionPage(
          {int limit = 20, String? cursor}) async =>
      {'sessions': sessions, 'nextCursor': null};
  @override
  Future<Map<String, dynamic>> getLibrary(
      {String? q,
      String? format,
      String? state,
      String? review,
      int limit = 12,
      String? cursor}) async {
    calls.add({'q': q, 'format': format, 'review': review, 'cursor': cursor});
    if (pending.containsKey(q)) return pending[q]!.future;
    return {'jobs': videos, 'nextCursor': null};
  }

  @override
  Future<Map<String, dynamic>> getSession(String sessionId) async => {
        'session': {
          ...session,
          'context': {
            'summary':
                'An async fetch updated a disposed widget. Added a mounted check.',
            'changes': ['Guard updates to lib/weather.dart after disposal.']
          },
          'activity': {
            'predictionPrompt':
                'What happens if the screen closes during a fetch?',
            'practice': {
              'prompt': 'Apply the same guard to another async callback.',
              'successCriteria': 'The callback checks mounted before setState.'
            },
            'reflectionPrompt':
                'What will you check before trusting another async change?'
          }
        },
        'review': {
          'version': 0,
          'prediction': null,
          'practice': null,
          'reflection': null
        },
        'videos': [],
      };
  @override
  Future<Map<String, dynamic>> updateSessionReview(
      String sessionId, Map<String, dynamic> patch) async {
    saved = patch;
    return {
      'version': 1,
      'prediction': {'text': patch['text']},
      'practice': null,
      'reflection': null
    };
  }
}

Future<void> mount(WidgetTester tester, WorkApi api, Widget page) async {
  tester.view.physicalSize = const Size(384, 832);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: MaterialApp(theme: AppTheme.light, home: page)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Home groups real agent checkpoints into projects and opens their context',
      (tester) async {
    final api = WorkApi(
        sessions: [session],
        videos: [video('State updates after disposal', sessionId: 's1')]);
    await mount(tester, api, const HomeScreen());
    expect(find.text('weather-app'), findsOneWidget);
    expect(find.text('Recent reels'), findsOneWidget);
    await tester.tap(find.text('weather-app'));
    await tester.pumpAndSettle();
    expect(find.text('Agent checkpoints'), findsOneWidget);
    expect(find.text('State updates after disposal'), findsOneWidget);
    await tester.tap(find.text('Fix disposal race'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect(find.textContaining('Added a mounted check'), findsOneWidget);
  });
  testWidgets('standalone reels remain recent without inventing projects',
      (tester) async {
    await mount(tester, WorkApi(videos: [video('Standalone concept')]),
        const HomeScreen());
    expect(find.text('No projects linked yet'), findsOneWidget);
    expect(find.text('Standalone concept'), findsOneWidget);
    expect(find.text('weather-app'), findsNothing);
  });
  testWidgets('search sends real filters and ignores stale query responses',
      (tester) async {
    final api = WorkApi();
    api.pending['docker'] = Completer();
    api.pending['git'] = Completer();
    await mount(tester, api, const SearchScreen());
    final field = find.byType(TextField);
    await tester.enterText(field, 'docker');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.enterText(field, 'git');
    await tester.pump(const Duration(milliseconds: 301));
    api.pending['docker']!.complete({
      'jobs': [video('Old docker result')],
      'nextCursor': null
    });
    await tester.pump();
    api.pending['git']!.complete({
      'jobs': [video('Latest git result')],
      'nextCursor': null
    });
    await tester.pumpAndSettle();
    expect(find.text('Latest git result'), findsOneWidget);
    expect(find.text('Old docker result'), findsNothing);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(api.calls.last['review'], 'bookmarked');
    await tester.tap(find.byTooltip('Filter by format'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sketch'));
    await tester.pumpAndSettle();
    expect(api.calls.last['format'], 'sketch');
  });
  testWidgets('learning saves a prediction with the current review version',
      (tester) async {
    final api = WorkApi();
    await mount(tester, api, const SessionDetailScreen(sessionId: 's1'));
    await tester.enterText(find.byType(TextField).first,
        'The response must not update a disposed widget.');
    await tester.scrollUntilVisible(find.text('Save prediction'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save prediction'));
    await tester.pumpAndSettle();
    expect(api.saved, containsPair('kind', 'predict'));
    expect(api.saved, containsPair('expectedVersion', 0));
    expect(api.saved, containsPair('confidence', 3));
    expect(find.text('I tried it'), findsOneWidget);
  });
}
