import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/api_service.dart';
import '../../api/models/models.dart';

class StudioJobState {
  final String? activeJobId;
  final String? stage;
  final int progress;
  final bool isCompleted;
  final String? error;
  final VideoJob? completedVideo;

  const StudioJobState({
    this.activeJobId,
    this.stage,
    this.progress = 0,
    this.isCompleted = false,
    this.error,
    this.completedVideo,
  });

  StudioJobState copyWith({
    String? activeJobId,
    String? stage,
    int? progress,
    bool? isCompleted,
    String? error,
    VideoJob? completedVideo,
  }) {
    return StudioJobState(
      activeJobId: activeJobId ?? this.activeJobId,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      completedVideo: completedVideo ?? this.completedVideo,
    );
  }
}

class StudioJobNotifier extends StateNotifier<StudioJobState> {
  final ApiService _apiService;
  Timer? _pollingTimer;
  int _pollCount = 0;

  StudioJobNotifier(this._apiService) : super(const StudioJobState());

  void startJob(String jobId) {
    _pollingTimer?.cancel();
    _pollCount = 0;
    state = StudioJobState(
      activeJobId: jobId,
      stage: 'queued',
      progress: 0,
    );

    // Initial check
    _pollJobStatus(jobId);

    // Poll every 3 seconds for the first 30 seconds (10 ticks), then every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollCount++;
      if (_pollCount > 10) {
        timer.cancel();
        _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _pollJobStatus(jobId);
        });
      }
      _pollJobStatus(jobId);
    });
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
          error: 'Video generation failed. Please try again.',
        );
      } else {
        state = state.copyWith(
          stage: job.stage ?? job.state,
          progress: job.progress ?? state.progress,
        );
      }
    } catch (_) {}
  }

  void dismissBanner() {
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
