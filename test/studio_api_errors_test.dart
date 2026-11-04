import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/studio/studio_job_provider.dart';
import 'studio_test.dart' show FakeApiService;

void main() {
  for (final body in [
    {
      'code': 'trial_limit_reached',
      'message': 'You have used all 5 lifetime trial videos.',
      'retryable': false,
      'requestId': 'quota-request'
    },
    '<html>Service unavailable</html>',
  ]) {
    test(
        'submission handles ${body is String ? 'non-JSON errors' : 'hosted quota errors'}',
        () async {
      final options = RequestOptions(path: '/videos');
      final notifier = StudioJobNotifier(FakeApiService(
          createVideoError: DioException(
        requestOptions: options,
        response: Response(
            requestOptions: options,
            statusCode: body is String ? 503 : 403,
            data: body,
            headers: Headers.fromMap({
              'x-request-id': ['header-id']
            })),
      )));
      addTearDown(notifier.dispose);
      expect(
          await notifier.generateVideo(
              prompt: 'Explain retry handling', format: 'sketch'),
          isFalse);
      final error = notifier.state.error!;
      if (body is String) {
        expect(error.retryable, isTrue);
        expect(error.requestId, 'header-id');
        expect(error.code, '503');
      } else {
        expect(error.isQuota, isTrue);
        expect(error.retryable, isFalse);
        expect(error.requestId, 'quota-request');
      }
    });
  }

  test('needs_review stops polling without offering another generation',
      () async {
    final notifier = StudioJobNotifier(FakeApiService(
        mockVideoJob: VideoJob(
      jobId: 'review-job',
      state: 'needs_review',
      stage: 'failed',
      error: 'Generation was interrupted. Reservation held for review.',
      format: 'sketch',
      createdAt: DateTime(2026),
    )));
    addTearDown(notifier.dispose);
    notifier.startJob('review-job');
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.stage, 'failed');
    expect(notifier.state.error?.code, 'needs_review');
    expect(notifier.state.error?.retryable, isFalse);
  });
}
