/// Video job model from the API.
class VideoJob {
  final String? sessionId;
  final String jobId;
  final String state;
  final String? stage;
  final int? progress;
  final String? title;
  final String format;
  final num? durationSeconds;
  final String? videoUrl;
  final String? posterUrl;
  final String? audioUrl;
  final String? downloadUrl;
  final bool mediaExpired;
  final DateTime? mediaExpiresAt;
  final DateTime createdAt;
  final VideoReview? review;
  final int? questionCount;
  final String? error;

  const VideoJob({
    required this.jobId,
    this.sessionId,
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
    this.review,
    this.questionCount,
    this.error,
  });

  factory VideoJob.fromJson(Map<String, dynamic> json) {
    return VideoJob(
      jobId: json['jobId'] as String,
      sessionId: json['sessionId'] as String?,
      state: json['state'] as String,
      stage: json['stage'] as String?,
      progress: (json['progress'] as num?)?.round(),
      title: json['title'] as String?,
      format: json['format'] as String,
      durationSeconds: json['durationSeconds'] as num?,
      videoUrl: json['videoUrl'] as String?,
      posterUrl: json['posterUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      mediaExpired: json['mediaExpired'] as bool? ?? false,
      mediaExpiresAt: json['mediaExpiresAt'] != null
          ? DateTime.parse(json['mediaExpiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      review: json['review'] is Map<String, dynamic>
          ? VideoReview.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      questionCount: json['questionCount'] as int?,
      error: json['error'] as String?,
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
    final quota = json['quota'] as Map<String, dynamic>? ?? json;
    return UserQuota(
      used: quota['used'] as int? ?? 0,
      limit: quota['limit'] as int? ?? 5,
      remaining: quota['remaining'] as int? ?? 0,
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
            (k, v) => MapEntry(k, (v as Map<String, dynamic>)['choice'] as int),
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
  final String? requestId;

  const ApiError({
    required this.code,
    required this.message,
    required this.retryable,
    this.requestId,
  });

  bool get isQuota => code == 'trial_limit_reached' || code == 'QUOTA_EXCEEDED';

  String get title => isQuota ? 'No free videos left' : 'Could not make video';

  factory ApiError.fromJson(Map<String, dynamic> json,
      {int? statusCode, String? requestId}) {
    return ApiError(
      code: json['code'] as String? ??
          (statusCode == 401 ? 'unauthorized' : 'ERROR'),
      message: json['message'] as String? ?? 'An error occurred.',
      retryable: json['retryable'] as bool? ??
          (statusCode != null &&
              (statusCode >= 500 || statusCode == 408 || statusCode == 429)),
      requestId: json['requestId'] as String? ?? requestId,
    );
  }
}

/// Studio format from GET /studio/config.
class StudioFormat {
  final String id;
  final String name;
  final String description;
  final int speakers;
  final String? visuals;
  final bool ready;

  const StudioFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.speakers,
    this.visuals,
    this.ready = true,
  });

  factory StudioFormat.fromJson(Map<String, dynamic> json) {
    return StudioFormat(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      speakers: json['speakers'] as int? ?? 1,
      visuals: json['visuals'] as String?,
      ready: json['ready'] as bool? ?? true,
    );
  }
}

/// Studio character from GET /studio/config.
class StudioCharacter {
  final String id;
  final String name;
  final String? imageUrl;
  final bool voiceReady;

  const StudioCharacter({
    required this.id,
    required this.name,
    this.imageUrl,
    this.voiceReady = true,
  });

  String get pictureUrl =>
      'https://d3sk6lwsh4ufyv.cloudfront.net/characters/$id.png';

  factory StudioCharacter.fromJson(Map<String, dynamic> json) {
    return StudioCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      voiceReady: json['voiceReady'] as bool? ?? true,
    );
  }
}

/// Full studio config data from GET /studio/config.
class StudioConfigData {
  final List<StudioFormat> formats;
  final List<StudioCharacter> characters;

  const StudioConfigData({
    required this.formats,
    required this.characters,
  });

  factory StudioConfigData.fromJson(Map<String, dynamic> json) {
    final rawFormats = json['formats'] as List? ?? [];
    final rawChars = json['characters'] as List? ?? [];
    return StudioConfigData(
      formats: rawFormats
          .map((f) => StudioFormat.fromJson(f as Map<String, dynamic>))
          .toList(),
      characters: rawChars
          .map((c) => StudioCharacter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Session summary from GET /sessions.
class SessionSummary {
  final String? projectName;
  final String? objective;
  final String? agent;
  final String sessionId;
  final String title;
  final DateTime createdAt;

  const SessionSummary({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    this.projectName,
    this.objective,
    this.agent,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      projectName: json['projectName'] as String?,
      objective: json['objective'] as String?,
      agent: json['agent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
