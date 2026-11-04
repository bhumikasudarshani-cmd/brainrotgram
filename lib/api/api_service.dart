import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';
import 'models/models.dart';

class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  Dio get _dio => _client.dio;

  /// GET /me - Quota tracking
  Future<UserQuota> getQuota() async {
    final response = await _dio.get('/me');
    return UserQuota.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /studio/config
  Future<Map<String, dynamic>> getStudioConfig() async {
    final response = await _dio.get('/studio/config');
    return response.data as Map<String, dynamic>;
  }

  /// GET /library
  Future<Map<String, dynamic>> getLibrary({
    String? q,
    String? format,
    String? state,
    String? review,
    int limit = 12,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (format != null && format.isNotEmpty) queryParams['format'] = format;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (review != null && review.isNotEmpty) queryParams['review'] = review;
    if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;

    final response = await _dio.get('/library', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  /// GET /videos - list ready videos
  Future<List<VideoJob>> getVideos() async {
    final response = await _dio.get('/videos');
    final jobs = (response.data['jobs'] as List? ?? [])
        .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
        .toList();
    return jobs;
  }

  /// GET /videos/{jobId} - fetch single job & fresh presigned URLs
  Future<VideoJob> getVideo(String jobId) async {
    final response = await _dio.get('/videos/$jobId');
    return VideoJob.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /videos/{jobId}/learning
  Future<Map<String, dynamic>> getLearningPack(String jobId) async {
    final response = await _dio.get('/videos/$jobId/learning');
    return response.data as Map<String, dynamic>;
  }

  /// GET /videos/{jobId}/review
  Future<VideoReview> getVideoReview(String jobId) async {
    final response = await _dio.get('/videos/$jobId/review');
    return VideoReview.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /videos/{jobId}/review with optimistic concurrency & single 409 retry
  Future<VideoReview> updateVideoReview(
    String jobId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final response = await _dio.put('/videos/$jobId/review', data: patch);
      return VideoReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 && e.response?.data != null) {
        final data = e.response!.data as Map<String, dynamic>;
        final currentReview = data['review'] as Map<String, dynamic>?;
        if (currentReview != null && currentReview.containsKey('version')) {
          final serverVersion = currentReview['version'] as int;
          final retryPatch = Map<String, dynamic>.from(patch)
            ..['expectedVersion'] = serverVersion;
          final retryResponse =
              await _dio.put('/videos/$jobId/review', data: retryPatch);
          return VideoReview.fromJson(
              retryResponse.data as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }

  /// POST /videos - generate video with requestId
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
    final reqId = requestId ?? const Uuid().v4();
    final body = <String, dynamic>{
      'requestId': reqId,
      'prompt': prompt,
      'format': format,
      'language': language,
      'durationSeconds': durationSeconds,
      'quizCount': quizCount,
    };
    if (cast != null) body['cast'] = cast;
    if (participants != null) body['participants'] = participants;
    if (narrator != null) body['narrator'] = narrator;

    final response = await _dio.post('/videos', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// POST /videos/validate - free check
  Future<Map<String, dynamic>> validateVideo({
    required String prompt,
    required String format,
    String language = 'en',
    int quizCount = 2,
    String? cast,
    Map<String, String>? participants,
    String? narrator,
  }) async {
    final body = <String, dynamic>{
      'prompt': prompt,
      'format': format,
      'language': language,
      'quizCount': quizCount,
    };
    if (cast != null) body['cast'] = cast;
    if (participants != null) body['participants'] = participants;
    if (narrator != null) body['narrator'] = narrator;

    final response = await _dio.post('/videos/validate', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionPage(
      {int limit = 20, String? cursor}) async {
    final response = await _dio.get('/sessions', queryParameters: {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return response.data as Map<String, dynamic>;
  }

  /// GET /sessions
  Future<List<SessionSummary>> getSessions(
      {int limit = 20, String? cursor}) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    final response = await _dio.get('/sessions', queryParameters: queryParams);
    final list = (response.data['sessions'] as List? ?? [])
        .map((s) => SessionSummary.fromJson(s as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// GET /sessions/{sessionId}
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId');
    return response.data as Map<String, dynamic>;
  }

  /// GET /sessions/{sessionId}/review
  Future<Map<String, dynamic>> getSessionReview(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId/review');
    return response.data as Map<String, dynamic>;
  }

  /// PUT /sessions/{sessionId}/review with 409 retry
  Future<Map<String, dynamic>> updateSessionReview(
    String sessionId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final response =
          await _dio.put('/sessions/$sessionId/review', data: patch);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 && e.response?.data != null) {
        final data = e.response!.data as Map<String, dynamic>;
        final currentReview = data['sessionReview'] as Map<String, dynamic>?;
        if (currentReview != null && currentReview.containsKey('version')) {
          final serverVersion = currentReview['version'] as int;
          final retryPatch = Map<String, dynamic>.from(patch)
            ..['expectedVersion'] = serverVersion;
          final retryResp =
              await _dio.put('/sessions/$sessionId/review', data: retryPatch);
          return retryResp.data as Map<String, dynamic>;
        }
      }
      rethrow;
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiService(client);
});
