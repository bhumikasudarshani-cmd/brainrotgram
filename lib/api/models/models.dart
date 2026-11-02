/// Video job model from the API.
class VideoJob {
  final String jobId;
  final String state;
  final String? stage;
  final int? progress;
  final String? title;
  final String format;
  final int? durationSeconds;
  final String? videoUrl;
  final String? posterUrl;
  final String? audioUrl;
  final String? downloadUrl;
  final bool mediaExpired;
  final DateTime? mediaExpiresAt;
  final DateTime createdAt;
  final String? reviewState;
  final int? questionCount;

  const VideoJob({
    required this.jobId,
    required this.state,
    this.stage,
    this.progress,
    this.title,
    required this.format,
    this.durationSeconds,
    this.videoUrl,
    this.posterUrl,
    this.audioUrl,
    this.downloadUrl,
    this.mediaExpired = false,
    this.mediaExpiresAt,
    required this.createdAt,
    this.reviewState,
    this.questionCount,
  });

  factory VideoJob.fromJson(Map<String, dynamic> json) {
    return VideoJob(
      jobId: json['jobId'] as String,
      state: json['state'] as String,
      stage: json['stage'] as String?,
      progress: json['progress'] as int?,
      title: json['title'] as String?,
      format: json['format'] as String,
      durationSeconds: json['durationSeconds'] as int?,
      videoUrl: json['videoUrl'] as String?,
      posterUrl: json['posterUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      mediaExpired: json['mediaExpired'] as bool? ?? false,
      mediaExpiresAt: json['mediaExpiresAt'] != null
          ? DateTime.parse(json['mediaExpiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewState: json['reviewState'] as String?,
      questionCount: json['questionCount'] as int?,
    );
  }

  /// Human-readable format name for display chips.
  String get formatLabel {
    switch (format) {
      case 'sketch':
        return 'Sketch board';
      case 'skit':
        return 'Character skit';
      case 'prreview':
        return 'PR review';
      case 'tierlist':
        return 'Tier list';
      case 'groupchat':
        return 'Group chat';
      case 'casefile':
        return 'Case file';
      case 'whiteboard':
        return 'Whiteboard';
      case 'pov':
        return 'POV';
      default:
        return format;
    }
  }
}

/// User quota from GET /me.
class UserQuota {
  final int used;
  final int limit;
  final int remaining;

  const UserQuota({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    final quota = json['quota'] as Map<String, dynamic>;
    return UserQuota(
      used: quota['used'] as int,
      limit: quota['limit'] as int,
      remaining: quota['remaining'] as int,
    );
  }
}

/// Review state for a video.
class VideoReview {
  final String jobId;
  final int version;
  final int positionMs;
  final int furthestMs;
  final bool completed;
  final bool bookmarked;
  final Map<String, int> answers;
  final DateTime? updatedAt;

  const VideoReview({
    required this.jobId,
    required this.version,
    this.positionMs = 0,
    this.furthestMs = 0,
    this.completed = false,
    this.bookmarked = false,
    this.answers = const {},
    this.updatedAt,
  });

  factory VideoReview.fromJson(Map<String, dynamic> json) {
    return VideoReview(
      jobId: json['jobId'] as String,
      version: json['version'] as int,
      positionMs: json['positionMs'] as int? ?? 0,
      furthestMs: json['furthestMs'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      bookmarked: json['bookmarked'] as bool? ?? false,
      answers: (json['answers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Learning pack question.
class LearningQuestion {
  final String id;
  final String prompt;
  final List<String> choices;
  final int answer;
  final String explanation;
  final int startMs;
  final int endMs;

  const LearningQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.startMs,
    required this.endMs,
  });

  /// Whether this is a Pause & Predict question (shown during playback).
  bool get isPausePredict => id.startsWith('pause-');

  factory LearningQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List).cast<String>(),
      answer: json['answer'] as int,
      explanation: json['explanation'] as String,
      startMs: json['startMs'] as int,
      endMs: json['endMs'] as int,
    );
  }
}

/// API error response shape.
class ApiError {
  final String code;
  final String message;
  final bool retryable;

  const ApiError({
    required this.code,
    required this.message,
    required this.retryable,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      retryable: json['retryable'] as bool? ?? false,
    );
  }
}

/// Session summary from GET /sessions.
class SessionSummary {
  final String sessionId;
  final String title;
  final DateTime createdAt;

  const SessionSummary({
    required this.sessionId,
    required this.title,
    required this.createdAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
