import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:brainrotgram/api/models/models.dart';

// Exported by brainrotten/scripts/app-contract-fixtures.mjs through its Zod
// schemas. Synthetic data only: no real accounts, media links or credentials.
void main() {
  final fixture =
      jsonDecode(File('test/fixtures/api-contract.json').readAsStringSync())
          as Map<String, dynamic>;

  test('ready jobs preserve fractional lengths beyond three minutes', () {
    final video = VideoJob.fromJson(fixture['video'] as Map<String, dynamic>);
    expect(video.durationSeconds, 215.6);
    expect(video.progress, 100);
  });

  test('processing jobs accept fractional progress and null duration', () {
    final job =
        VideoJob.fromJson(fixture['processing'] as Map<String, dynamic>);
    expect(job.progress, 23);
    expect(job.durationSeconds, isNull);
  });

  test('library rows parse nested review without requiring a video URL', () {
    final row =
        (fixture['library']['jobs'] as List).single as Map<String, dynamic>;
    final job = VideoJob.fromJson(row);
    expect(job.videoUrl, isNull);
    expect(job.review?.bookmarked, isTrue);
    expect(job.review?.positionMs, 185600);
    expect(job.review?.answers['pause-1'], 1);
  });

  test('saved graded answer objects restore selected choices', () {
    final review =
        VideoReview.fromJson(fixture['review'] as Map<String, dynamic>);
    expect(review.answers, {'pause-1': 1});
    expect(review.furthestMs, 215600);
    expect(review.completed, isTrue);
  });

  test('gateway message-only 401 is accepted', () {
    final error = ApiError.fromJson(
        fixture['errors']['gateway'] as Map<String, dynamic>,
        statusCode: 401);
    expect(error.code, 'unauthorized');
    expect(error.message, 'Unauthorized');
    expect(error.retryable, isFalse);
  });

  test('quota and service errors preserve request IDs and retry policy', () {
    final quota =
        ApiError.fromJson(fixture['errors']['quota'] as Map<String, dynamic>);
    expect(quota.isQuota, isTrue);
    expect(quota.title, 'No free videos left');
    expect(quota.requestId, 'fixture-quota');
    expect(quota.retryable, isFalse);
    final unavailable = ApiError.fromJson(
        fixture['errors']['unavailable'] as Map<String, dynamic>);
    expect(unavailable.requestId, 'fixture-unavailable');
    expect(unavailable.retryable, isTrue);
  });

  test('header request ID and status retry policy fill missing error fields',
      () {
    final error = ApiError.fromJson({'message': 'Unavailable'},
        statusCode: 503, requestId: 'header-id');
    expect(error.requestId, 'header-id');
    expect(error.retryable, isTrue);
  });
}
