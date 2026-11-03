import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_service.dart';
import '../../api/models/models.dart';

/// Studio configuration provider from GET /studio/config.
final studioConfigProvider = FutureProvider<StudioConfigData>((ref) async {
  final res = await ref.watch(apiServiceProvider).getStudioConfig();
  return StudioConfigData.fromJson(res);
});

/// User quota provider from GET /me.
final userQuotaProvider = FutureProvider<UserQuota>((ref) async {
  return await ref.watch(apiServiceProvider).getQuota();
});

class StudioJobState {
  final String? activeJobId;
  final String? stage;
  final int progress;
  final bool isCompleted;
  final bool isSubmitting;
  final ApiError? error;
  final VideoJob? completedVideo;
  final String? currentRequestId;

  const StudioJobState({
    this.activeJobId,
    this.stage,
    this.progress = 0,
    this.isCompleted = false,
    this.isSubmitting = false,
    this.error,
    this.completedVideo,
    this.currentRequestId,
  });

  StudioJobState copyWith({
    String? activeJobId,
    String? stage,
    int? progress,
    bool? isCompleted,
    bool? isSubmitting,
    ApiError? error,
    VideoJob? completedVideo,
    String? currentRequestId,
    bool clearError = false,
  }) {
    return StudioJobState(
      activeJobId: activeJobId ?? this.activeJobId,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      completedVideo: completedVideo ?? this.completedVideo,
      currentRequestId: currentRequestId ?? this.currentRequestId,
    );
  }
}

class StudioJobNotifier extends StateNotifier<StudioJobState> {
  final ApiService _apiService;
  Timer? _pollingTimer;
  int _pollCount = 0;
  String? _lastRequestId;
  Map<String, dynamic>? _lastPayload;

  StudioJobNotifier(this._apiService) : super(const StudioJobState());

  String? get lastRequestId => _lastRequestId;
  Map<String, dynamic>? get lastPayload => _lastPayload;

  /// Start tracking and polling an existing jobId.
  void startJob(String jobId) {
    _pollingTimer?.cancel();
    _pollCount = 0;
    state = StudioJobState(
      activeJobId: jobId,
      stage: 'queued',
      progress: 0,
      currentRequestId: _lastRequestId,
    );

    // Initial check
    _pollJobStatus(jobId);

    // Poll every 3 seconds for the first 30 seconds (10 ticks), then every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollCount++;
      if (_pollCount >= 10) {
        timer.cancel();
        _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _pollJobStatus(jobId);
        });
      }
      _pollJobStatus(jobId);
    });
  }

  /// Submit a video generation request.
  /// Reuses requestId if [isRetry] is true and a previous requestId exists.
  Future<bool> generateVideo({
    required String prompt,
    required String format,
    String language = 'en',
    int quizCount = 2,
    String? cast,
    Map<String, String>? participants,
    String? narrator,
    bool isRetry = false,
  }) async {
    final reqId = (isRetry && _lastRequestId != null)
        ? _lastRequestId!
        : const Uuid().v4();
    _lastRequestId = reqId;
    _lastPayload = {
      'prompt': prompt,
      'format': format,
      'language': language,
      'quizCount': quizCount,
      'cast': cast,
      'participants': participants,
      'narrator': narrator,
    };

    state = state.copyWith(
      isSubmitting: true,
      stage: 'Submitting request…',
      progress: 0,
      isCompleted: false,
      clearError: true,
      activeJobId: null,
      currentRequestId: reqId,
    );

    try {
      final res = await _apiService.createVideo(
        prompt: prompt,
        format: format,
        language: language,
        quizCount: quizCount,
        cast: cast,
        participants: participants,
        narrator: narrator,
        requestId: reqId,
      );

      final jobId = res['jobId'] as String;
      state = state.copyWith(isSubmitting: false);
      startJob(jobId);
      return true;
    } on DioException catch (e) {
      ApiError apiError;
      if (e.response?.statusCode == 402 ||
          e.response?.data?['code'] == 'QUOTA_EXCEEDED') {
        apiError = const ApiError(
          code: 'QUOTA_EXCEEDED',
          message: "You've used your 5 free videos.",
          retryable: false,
        );
      } else if (e.response?.data is Map<String, dynamic>) {
        apiError = ApiError.fromJson(e.response!.data as Map<String, dynamic>);
      } else {
        final status = e.response?.statusCode;
        final retryable =
            status != null && (status >= 500 || status == 408 || status == 429);
        apiError = ApiError(
          code: status != null ? '$status' : 'NETWORK_ERROR',
          message: e.message ?? 'Failed to submit video. Please try again.',
          retryable: retryable,
        );
      }
      state = state.copyWith(
        isSubmitting: false,
        error: apiError,
        stage: 'failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
          retryable: true,
        ),
        stage: 'failed',
      );
      return false;
    }
  }

  /// Retries the last failed submission using the preserved requestId.
  Future<bool> retryLastSubmission() async {
    if (_lastPayload == null) return false;
    return generateVideo(
      prompt: _lastPayload!['prompt'] as String,
      format: _lastPayload!['format'] as String,
      language: _lastPayload!['language'] as String? ?? 'en',
      quizCount: _lastPayload!['quizCount'] as int? ?? 2,
      cast: _lastPayload!['cast'] as String?,
      participants: _lastPayload!['participants'] as Map<String, String>?,
      narrator: _lastPayload!['narrator'] as String?,
      isRetry: true,
    );
  }

  Future<void> _pollJobStatus(String jobId) async {
    try {
      final job = await _apiService.getVideo(jobId);
      if (job.state == 'ready') {
        _pollingTimer?.cancel();
        state = state.copyWith(
          stage: 'ready',
          progress: 100,
          isCompleted: true,
          completedVideo: job,
        );
      } else if (job.state == 'failed') {
        _pollingTimer?.cancel();
        state = state.copyWith(
          stage: 'failed',
          error: ApiError(
            code: 'RENDER_FAILED',
            message: job.error ?? 'Video generation failed. Please try again.',
            retryable: true,
          ),
        );
      } else {
        state = state.copyWith(
          stage: job.stage ?? job.state,
          progress: job.progress ?? state.progress,
        );
      }
    } catch (_) {}
  }

  /// Clears active job banner and resets state.
  void dismissBanner() {
    state = const StudioJobState();
  }

  /// Resets studio back to initial state for making another video.
  void resetJob() {
    _pollingTimer?.cancel();
    _lastRequestId = null;
    _lastPayload = null;
    state = const StudioJobState();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final studioJobProvider =
    StateNotifierProvider<StudioJobNotifier, StudioJobState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return StudioJobNotifier(api);
});
