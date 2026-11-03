import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../api/api_constants.dart';
import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../theme/app_theme.dart';
import '../quiz/end_quiz_overlay.dart';
import 'pause_predict_overlay.dart';

class VideoReelItem extends ConsumerStatefulWidget {
  final VideoJob video;
  final bool isActive;
  final VoidCallback onNextVideo;

  const VideoReelItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onNextVideo,
  });

  @override
  ConsumerState<VideoReelItem> createState() => VideoReelItemState();
}

class VideoReelItemState extends ConsumerState<VideoReelItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @visibleForTesting
  void checkPausePredict(int currentMs) => _checkPausePredict(currentMs);
  bool _hasError = false;
  bool _retriedOnce = false;
  bool _isPlaying = false;
  bool _showHeartAnimation = false;

  VideoReview? _review;
  List<LearningQuestion> _learningQuestions = [];
  String? _takeaway;
  bool _showEndQuiz = false;

  LearningQuestion? _currentPauseQuestion;
  bool _showPauseExplanation = false;
  Timer? _positionReportTimer;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnimation = CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.elasticOut,
    );

    _loadLearningAndReview();
    _initializePlayer(widget.video.videoUrl);
  }

  Future<void> _loadLearningAndReview() async {
    try {
      final api = ref.read(apiServiceProvider);
      final reviewFuture = api.getVideoReview(widget.video.jobId);
      final learningFuture = api.getLearningPack(widget.video.jobId);

      final review = await reviewFuture;
      if (mounted) {
        setState(() {
          _review = review;
        });
      }

      final pack = await learningFuture;
      if (mounted && pack.containsKey('questions')) {
        final qList = (pack['questions'] as List)
            .map((q) => LearningQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
        setState(() {
          _learningQuestions = qList;
          _takeaway = pack['takeaway'] as String?;
        });
      }
    } catch (_) {
      // Review or learning might not exist yet or offline
    }
  }

  Future<void> _initializePlayer(String? url) async {
    if (url == null || url.isEmpty) {
      if (!_retriedOnce) {
        _retriedOnce = true;
        _retryWithFreshUrl();
      } else {
        if (mounted) setState(() => _hasError = true);
      }
      return;
    }

    try {
      final oldController = _controller;
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await oldController?.dispose();

      await _controller!.initialize();
      _controller!.setLooping(false);
      _controller!.addListener(_playerListener);

      // Resume from positionMs if available
      if (_review != null && _review!.positionMs > 0) {
        final resumeTo = Duration(milliseconds: _review!.positionMs);
        if (resumeTo < _controller!.value.duration) {
          await _controller!.seekTo(resumeTo);
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        if (widget.isActive) {
          _controller!.play();
          _isPlaying = true;
        }
      }
    } catch (e) {
      if (!_retriedOnce) {
        _retriedOnce = true;
        _retryWithFreshUrl();
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  Future<void> _retryWithFreshUrl() async {
    try {
      final api = ref.read(apiServiceProvider);
      final fresh = await api.getVideo(widget.video.jobId);
      if (fresh.videoUrl != null) {
        await _initializePlayer(fresh.videoUrl);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _playerListener() {
    if (!mounted || _controller == null) return;

    final val = _controller!.value;

    if (val.hasError && !_retriedOnce) {
      _retriedOnce = true;
      _retryWithFreshUrl();
      return;
    }

    // Check pause & predict questions
    final currentMs = val.position.inMilliseconds;
    _checkPausePredict(currentMs);

    // Check if finished
    if (val.isInitialized &&
        val.position >= val.duration &&
        val.duration > Duration.zero) {
      if (!_showEndQuiz) {
        setState(() {
          _showEndQuiz = true;
          _isPlaying = false;
        });
        _recordWatchPosition(val.duration.inMilliseconds, completed: true);
      }
    }
  }

  void _checkPausePredict(int currentMs) {
    if (_learningQuestions.isEmpty) return;

    LearningQuestion? match;
    for (final q in _learningQuestions) {
      if (q.isPausePredict &&
          currentMs >= q.startMs &&
          currentMs <= q.endMs) {
        match = q;
        break;
      }
    }

    if (match != _currentPauseQuestion) {
      setState(() {
        _currentPauseQuestion = match;
        _showPauseExplanation = false;
      });
    } else if (match != null && currentMs >= match.endMs) {
      if (!_showPauseExplanation) {
        setState(() {
          _showPauseExplanation = true;
        });
      }
    }
  }

  void _recordWatchPosition(int positionMs, {bool completed = false}) {
    if (_review == null) return;
    ref.read(apiServiceProvider).updateVideoReview(
      widget.video.jobId,
      {
        'kind': 'watch',
        'expectedVersion': _review!.version,
        'positionMs': positionMs,
      },
    ).then((updated) {
      if (mounted) setState(() => _review = updated);
    }).catchError((_) {});
  }

  @override
  void didUpdateWidget(covariant VideoReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _isInitialized) {
      if (widget.isActive && !_isPlaying && !_showEndQuiz) {
        _controller!.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isActive && _isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _positionReportTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    setState(() => _showHeartAnimation = true);
    _heartAnimController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
    _toggleBookmark();
  }

  Future<void> _toggleBookmark() async {
    if (_review == null) return;
    final newValue = !_review!.bookmarked;
    try {
      final updated = await ref.read(apiServiceProvider).updateVideoReview(
        widget.video.jobId,
        {
          'kind': 'bookmark',
          'expectedVersion': _review!.version,
          'value': newValue,
        },
      );
      if (mounted) setState(() => _review = updated);
    } catch (_) {}
  }

  Future<void> _handlePauseAnswer(int choice) async {
    if (_currentPauseQuestion == null || _review == null) return;
    try {
      final updated = await ref.read(apiServiceProvider).updateVideoReview(
        widget.video.jobId,
        {
          'kind': 'answer',
          'expectedVersion': _review!.version,
          'questionId': _currentPauseQuestion!.id,
          'choice': choice,
        },
      );
      if (mounted) setState(() => _review = updated);
    } catch (_) {}
  }

  Future<void> _handleQuizAnswer(String qId, int choice) async {
    if (_review == null) return;
    try {
      final updated = await ref.read(apiServiceProvider).updateVideoReview(
        widget.video.jobId,
        {
          'kind': 'answer',
          'expectedVersion': _review!.version,
          'questionId': qId,
          'choice': choice,
        },
      );
      if (mounted) setState(() => _review = updated);
    } catch (_) {}
  }

  Future<void> _handleResetQuiz() async {
    if (_review == null) return;
    try {
      final updated = await ref.read(apiServiceProvider).updateVideoReview(
        widget.video.jobId,
        {
          'kind': 'reset-answers',
          'expectedVersion': _review!.version,
        },
      );
      if (mounted) setState(() => _review = updated);
    } catch (_) {}
  }

  void _replayVideo() {
    setState(() {
      _showEndQuiz = false;
      _isPlaying = true;
    });
    _controller?.seekTo(Duration.zero);
    _controller?.play();
  }

  void _shareVideo() {
    final title = widget.video.title ?? 'BrainRot reel';
    Share.share(
      '$title\nWatch micro-learning reels from code: ${ApiConstants.websiteUrl}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.video.mediaExpired) {
      return Container(
        color: AppColors.reelBackground,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.lavender, size: 48),
              const SizedBox(height: 12),
              Text(
                widget.video.mediaExpired
                    ? 'Media has expired (30 days)'
                    : 'Unable to play video',
                style: const TextStyle(color: AppColors.cream, fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (!widget.video.mediaExpired)
                ElevatedButton.icon(
                  onPressed: _retryWithFreshUrl,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.reelBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player or Poster
          if (_isInitialized && _controller != null)
            GestureDetector(
              onTap: _togglePlayPause,
              onDoubleTap: _handleDoubleTap,
              onLongPressStart: (_) {
                if (_isPlaying) _controller?.pause();
              },
              onLongPressEnd: (_) {
                if (_isPlaying) _controller?.play();
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (widget.video.posterUrl != null)
            CachedNetworkImage(
              imageUrl: widget.video.posterUrl!,
              fit: BoxFit.cover,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.purpleAccent),
            ),

          // Play/Pause indicator icon
          if (_isInitialized && !_isPlaying && !_showEndQuiz)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Double-tap heart burst animation
          if (_showHeartAnimation)
            Center(
              child: ScaleTransition(
                scale: _heartScaleAnimation,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.coral,
                  size: 100,
                ),
              ),
            ),

          // Right rail actions (Save/Bookmark, Share)
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              children: [
                IconButton(
                  onPressed: _toggleBookmark,
                  icon: Icon(
                    _review?.bookmarked == true
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _review?.bookmarked == true
                        ? AppColors.yellow
                        : Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: _shareVideo,
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Bottom info overlay (format chip + title)
          Positioned(
            left: 16,
            right: 70,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAccent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.video.formatLabel,
                    style: const TextStyle(
                      fontFamily: AppFonts.uncutSans,
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.title ?? 'BrainRot Learning Reel',
                  style: const TextStyle(
                    fontFamily: AppFonts.uncutSans,
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Thin progress bar at the very bottom
          if (_isInitialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.purpleAccent,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

          // Pause & Predict Card Overlay
          if (_currentPauseQuestion != null && !_showEndQuiz)
            PausePredictOverlay(
              question: _currentPauseQuestion!,
              existingAnswer:
                  _review?.answers[_currentPauseQuestion!.id],
              showExplanation: _showPauseExplanation,
              onAnswerSelected: _handlePauseAnswer,
            ),

          // End-of-video full screen quiz overlay
          if (_showEndQuiz)
            Positioned.fill(
              child: EndQuizOverlay(
                questions: _learningQuestions
                    .where((q) => !q.isPausePredict)
                    .toList(),
                takeaway: _takeaway,
                onAnswer: _handleQuizAnswer,
                onResetAnswers: _handleResetQuiz,
                onReplay: _replayVideo,
                onNext: widget.onNextVideo,
              ),
            ),
        ],
      ),
    );
  }
}
