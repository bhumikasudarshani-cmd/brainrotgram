import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../theme/app_theme.dart';
import 'studio_job_provider.dart';

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  final _topicController = TextEditingController();
  String _selectedFormat = 'sketch';
  String _selectedLanguage = 'en';
  int _questionCount = 2;

  // Voice state
  bool _aiPickVoices = true;
  String? _askerId;
  String? _explainerId;
  String? _narratorId;

  static const _defaultFormats = [
    StudioFormat(
      id: 'sketch',
      name: 'Sketch board',
      description: 'Excalidraw-style architecture board',
      speakers: 1,
    ),
    StudioFormat(
      id: 'skit',
      name: 'Character skit',
      description: 'Two characters, question-answer',
      speakers: 2,
    ),
    StudioFormat(
      id: 'prreview',
      name: 'PR review',
      description: 'GitHub-style diff and review',
      speakers: 2,
    ),
    StudioFormat(
      id: 'tierlist',
      name: 'Tier list',
      description: 'TierMaker ranking board',
      speakers: 1,
    ),
    StudioFormat(
      id: 'groupchat',
      name: 'Group chat',
      description: 'WhatsApp-style group thread',
      speakers: 4,
    ),
  ];

  static const _languages = {
    'en': 'English',
    'hinglish': 'Hinglish',
    'benglish': 'Benglish',
  };

  @override
  void initState() {
    super.initState();
    _topicController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  IconData _formatIcon(String id) {
    switch (id) {
      case 'sketch':
        return Icons.draw_rounded;
      case 'skit':
        return Icons.people_rounded;
      case 'prreview':
        return Icons.code_rounded;
      case 'tierlist':
        return Icons.format_list_numbered_rounded;
      case 'groupchat':
        return Icons.chat_rounded;
      default:
        return Icons.video_collection_rounded;
    }
  }

  void _onGeneratePressed(UserQuota? quota) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    if (quota != null && quota.remaining <= 0) return;

    String? cast;
    Map<String, String>? participants;
    String? narrator;

    if (_selectedFormat == 'skit') {
      if (_aiPickVoices) {
        cast = 'auto';
      } else {
        cast = 'custom';
        participants = {
          'learner': _askerId ?? 'jack',
          'expert': _explainerId ?? 'jhatka',
        };
      }
    } else if (_selectedFormat == 'sketch' || _selectedFormat == 'tierlist') {
      if (_narratorId != null && _narratorId != 'auto') {
        narrator = _narratorId;
      }
    }

    await ref.read(studioJobProvider.notifier).generateVideo(
          prompt: topic,
          format: _selectedFormat,
          language: _selectedLanguage,
          quizCount: _questionCount,
          cast: cast,
          participants: participants,
          narrator: narrator,
        );
  }

  Future<void> _pickCharacter({
    required String title,
    required List<StudioCharacter> characters,
    required String? currentId,
    required ValueChanged<String?> onSelected,
    bool allowAiPick = false,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.uncutSans,
                    color: AppColors.plum,
                  ),
                ),
                const SizedBox(height: 16),
                if (allowAiPick) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.purpleAccent,
                      child: Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 20),
                    ),
                    title: const Text('Let AI pick',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: (currentId == null || currentId == 'auto')
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.purpleAccent)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () => Navigator.of(context).pop('auto'),
                  ),
                  const Divider(),
                ],
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final char = characters[index];
                      final isSelected = char.id == currentId;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(char.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.purpleAccent.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.purpleAccent
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: char.pictureUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 50,
                                    height: 50,
                                    color: AppColors.lavender,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: AppColors.lavender,
                                    child: const Icon(Icons.person_rounded,
                                        color: AppColors.purpleAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                char.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.purpleAccent
                                      : AppColors.plum,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Widget _buildCharacterCard({
    required String label,
    required String? characterId,
    required List<StudioCharacter> characters,
    required VoidCallback onTap,
  }) {
    final char = characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => characters.isNotEmpty
          ? characters.first
          : const StudioCharacter(id: 'unknown', name: 'Select Character'),
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: char.pictureUrl,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 38,
                    height: 38,
                    color: AppColors.lavender,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 38,
                    height: 38,
                    color: AppColors.lavender,
                    child: const Icon(Icons.person_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      char.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.plum,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.swap_vert_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePickers(
    StudioConfigData? config,
    StudioFormat selectedFormat,
  ) {
    final characters = config?.characters ?? [];

    // Format 1: Character skit (speakers == 2)
    if (selectedFormat.id == 'skit') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Let AI pick'),
                selected: _aiPickVoices,
                onSelected: (val) => setState(() => _aiPickVoices = true),
                selectedColor: AppColors.purpleAccent,
                labelStyle: TextStyle(
                  color: _aiPickVoices ? Colors.white : AppColors.plum,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ChoiceChip(
                label: const Text('Choose speakers'),
                selected: !_aiPickVoices,
                onSelected: (val) => setState(() => _aiPickVoices = false),
                selectedColor: AppColors.purpleAccent,
                labelStyle: TextStyle(
                  color: !_aiPickVoices ? Colors.white : AppColors.plum,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_aiPickVoices)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.purpleAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI will pick the asker and explainer automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                _buildCharacterCard(
                  label: 'Asker',
                  characterId: _askerId ??
                      (characters.isNotEmpty ? characters[0].id : 'jack'),
                  characters: characters,
                  onTap: () {
                    _pickCharacter(
                      title: 'Select Asker',
                      characters: characters,
                      currentId: _askerId ?? 'jack',
                      onSelected: (id) => setState(() => _askerId = id),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _buildCharacterCard(
                  label: 'Explainer',
                  characterId: _explainerId ??
                      (characters.length > 1 ? characters[1].id : 'jhatka'),
                  characters: characters,
                  onTap: () {
                    _pickCharacter(
                      title: 'Select Explainer',
                      characters: characters,
                      currentId: _explainerId ?? 'jhatka',
                      onSelected: (id) => setState(() => _explainerId = id),
                    );
                  },
                ),
              ],
            ),
        ],
      );
    }

    // Format 2: Sketch board & Tier list (speakers == 1)
    if (selectedFormat.id == 'sketch' || selectedFormat.id == 'tierlist') {
      final isAi = _narratorId == null || _narratorId == 'auto';
      StudioCharacter? chosenChar;
      if (!isAi) {
        chosenChar = characters.firstWhere(
          (c) => c.id == _narratorId,
          orElse: () => characters.isNotEmpty
              ? characters.first
              : const StudioCharacter(id: 'unknown', name: 'Unknown'),
        );
      }

      return InkWell(
        onTap: () {
          _pickCharacter(
            title: 'Select Narrator',
            characters: characters,
            currentId: _narratorId,
            allowAiPick: true,
            onSelected: (id) => setState(() => _narratorId = id),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              if (isAi)
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.purpleAccent,
                  child: Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                )
              else
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: chosenChar?.pictureUrl ?? '',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.lavender,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.lavender,
                      child: const Icon(Icons.person_rounded, size: 20),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Narrator',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isAi ? 'Let AI pick' : (chosenChar?.name ?? 'Narrator'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.plum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    // Format 3: PR review and Group chat (AI picks)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded,
              color: AppColors.purpleAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI picks voices and characters automatically for this format.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.plum,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaWidget(AsyncValue<UserQuota> quotaAsync) {
    return quotaAsync.when(
      data: (quota) {
        if (quota.remaining <= 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 20, color: AppColors.coral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You've used all ${quota.limit} free videos.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.plum,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.yellow.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.movie_filter_rounded,
                  size: 18, color: AppColors.purpleAccent),
              const SizedBox(width: 8),
              Text(
                '${quota.remaining} of ${quota.limit} free videos left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.plum,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading quota…',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.movie_filter_rounded,
                size: 18, color: AppColors.purpleAccent),
            SizedBox(width: 8),
            Text('Free videos available'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(
    ApiError error,
    VoidCallback onRetry,
    VoidCallback onDismiss,
  ) {
    final displayMessage = error.message;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.coral, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.plum,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayMessage,
            style: const TextStyle(fontSize: 13, color: AppColors.plum),
          ),
          if (error.requestId != null)
            SelectableText('Request ID: ${error.requestId}',
                style: const TextStyle(fontSize: 11, color: AppColors.plum)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
              if (error.retryable) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: AppColors.cream,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressScreen(StudioJobState jobState) {
    final isCompleted = jobState.isCompleted;
    final isFailed = jobState.stage == 'failed' || jobState.error != null;
    final progress = jobState.progress;
    final stage = jobState.stage ?? 'queued';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Creating reel'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted) ...[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.purpleAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your video is ready!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap watch to open your new learning reel.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(studioJobProvider.notifier).dismissBanner();
                        context.go('/home');
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Watch Video'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(studioJobProvider.notifier).resetJob();
                      },
                      child: const Text('Make another video'),
                    ),
                  ),
                ] else if (isFailed) ...[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: AppColors.coral, size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    jobState.error?.title ?? 'Generation failed',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (jobState.error != null)
                    Text(
                      jobState.error!.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  if (jobState.error?.requestId != null)
                    SelectableText('Request ID: ${jobState.error!.requestId}'),
                  const SizedBox(height: 24),
                  if (jobState.error?.retryable == true)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(studioJobProvider.notifier)
                              .retryLastSubmission();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(studioJobProvider.notifier).resetJob();
                      },
                      child: const Text('Back to Studio'),
                    ),
                  ),
                ] else ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 124,
                        height: 124,
                        child: CircularProgressIndicator(
                          value: progress > 0 ? progress / 100 : null,
                          strokeWidth: 8,
                          backgroundColor: AppColors.lavender,
                          color: AppColors.purpleAccent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.plum,
                              fontFamily: AppFonts.uncutSans,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.purpleAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stage.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.purpleAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Making your reel…',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 200,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Home'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studioJob = ref.watch(studioJobProvider);

    // If job is actively running, submitting, or completed: show Progress Screen
    if (studioJob.activeJobId != null ||
        studioJob.isSubmitting ||
        (studioJob.isCompleted && studioJob.completedVideo != null)) {
      return _buildProgressScreen(studioJob);
    }

    final configAsync = ref.watch(studioConfigProvider);
    final quotaAsync = ref.watch(userQuotaProvider);
    final quota = quotaAsync.valueOrNull;

    final formats = configAsync.valueOrNull?.formats ?? _defaultFormats;
    final selectedFormat = formats.firstWhere(
      (f) => f.id == _selectedFormat,
      orElse: () => formats.first,
    );

    final isTopicEmpty = _topicController.text.trim().isEmpty;
    final isQuotaExhausted = quota != null && quota.remaining <= 0;
    final canGenerate =
        !isTopicEmpty && !isQuotaExhausted && !studioJob.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Create'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          // Inline error banner if any submission error occurred
          if (studioJob.error != null)
            _buildErrorBanner(
              studioJob.error!,
              () => ref.read(studioJobProvider.notifier).retryLastSubmission(),
              () => ref.read(studioJobProvider.notifier).resetJob(),
            ),

          // Real Quota Line
          _buildQuotaWidget(quotaAsync),
          const SizedBox(height: 20),

          // Topic
          Text(
            'Topic',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topicController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Paste an error, a diff summary, or a question…',
            ),
          ),
          const SizedBox(height: 24),

          // Format Cards
          Text(
            'Format',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final format in formats)
                SizedBox(
                  width: width,
                  child: _FormatOption(
                      format: format,
                      icon: _formatIcon(format.id),
                      selected: _selectedFormat == format.id,
                      onTap: () => setState(() => _selectedFormat = format.id)),
                )
            ]);
          }),
          const SizedBox(height: 24),

          // Voice Pickers (depend on format)
          Text(
            'Voices',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          _buildVoicePickers(configAsync.valueOrNull, selectedFormat),
          const SizedBox(height: 24),

          // Language
          Text(
            'Language',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _languages.entries.map((e) {
              final selected = _selectedLanguage == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _selectedLanguage = e.key),
                selectedColor: AppColors.purpleAccent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.plum,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Questions count
          Text(
            'Questions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final n in [1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n'),
                    selected: _questionCount == n,
                    onSelected: (_) => setState(() => _questionCount = n),
                    selectedColor: AppColors.purpleAccent,
                    labelStyle: TextStyle(
                      color:
                          _questionCount == n ? Colors.white : AppColors.plum,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canGenerate ? () => _onGeneratePressed(quota) : null,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final StudioFormat format;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FormatOption(
      {required this.format,
      required this.icon,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('format-${format.id}'),
        label: format.name,
        selected: selected,
        button: true,
        excludeSemantics: true,
        onTap: onTap,
        child: Tooltip(
            message: format.description,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 112),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color:
                            selected ? AppColors.lavender : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? AppColors.purpleAccent
                                : Colors.transparent,
                            width: 2)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(icon, size: 26, color: AppColors.plum),
                                Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 20,
                                    color: selected
                                        ? AppColors.purpleAccent
                                        : AppColors.textSecondary)
                              ]),
                          const SizedBox(height: 12),
                          Text(format.name,
                              maxLines: 2,
                              style: const TextStyle(
                                  fontFamily: AppFonts.uncutSans,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.plum)),
                        ]),
                  ),
                ))),
      );
}
