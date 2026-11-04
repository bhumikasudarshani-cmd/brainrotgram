import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../shared/widgets/app_message.dart';
import '../../theme/app_theme.dart';
import '../player/reel_viewer_screen.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});
  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  Map<String, dynamic>? _session, _review;
  List<VideoJob> _videos = [];
  bool _loading = true, _failed = false, _saving = false, _practiced = false;
  int _step = 0, _predictionConfidence = 3, _reflectionConfidence = 3;
  int get _confidence =>
      _step == 2 ? _reflectionConfidence : _predictionConfidence;
  String? _error;
  final _prediction = TextEditingController(),
      _practice = TextEditingController(),
      _reflection = TextEditingController(),
      _next = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prediction.dispose();
    _practice.dispose();
    _reflection.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data =
          await ref.read(apiServiceProvider).getSession(widget.sessionId);
      if (!mounted) return;
      final review = data['review'] as Map<String, dynamic>;
      _prediction.text = review['prediction']?['text'] as String? ?? '';
      _practice.text = review['practice']?['attempt'] as String? ?? '';
      _reflection.text = review['reflection']?['explanation'] as String? ?? '';
      _next.text = review['reflection']?['nextAction'] as String? ?? '';
      setState(() {
        _session = data['session'] as Map<String, dynamic>;
        _review = review;
        _videos = (data['videos'] as List? ?? [])
            .map((v) => VideoJob.fromJson(v as Map<String, dynamic>))
            .where((v) => v.state == 'ready')
            .toList();
        _practiced = review['practice']?['completed'] as bool? ?? false;
        _step = review['prediction'] == null
            ? 0
            : review['practice'] == null
                ? 1
                : 2;
        _predictionConfidence =
            (review['prediction']?['confidence'] as num?)?.toInt() ?? 3;
        _reflectionConfidence =
            (review['reflection']?['confidence'] as num?)?.toInt() ?? 3;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _save({bool skip = false}) async {
    final text = (_step == 0
            ? _prediction
            : _step == 1
                ? _practice
                : _reflection)
        .text
        .trim();
    if (!skip && text.length < 3) {
      setState(() => _error = 'Write a short response first.');
      return;
    }
    final patch = <String, dynamic>{'expectedVersion': _review!['version']};
    if (_step == 0) {
      patch.addAll({
        'kind': 'predict',
        'text': skip ? '' : text,
        'confidence': skip ? null : _confidence,
        'skipped': skip
      });
    }
    if (_step == 1) {
      patch.addAll(
          {'kind': 'practice', 'attempt': text, 'completed': _practiced});
    }
    if (_step == 2) {
      patch.addAll({
        'kind': 'reflect',
        'explanation': text,
        'confidence': _confidence,
        'traps': _review!['reflection']?['traps'] ?? [],
        'nextAction': _next.text.trim()
      });
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(apiServiceProvider)
          .updateSessionReview(widget.sessionId, patch);
      if (!mounted) return;
      setState(() {
        _review = updated;
        _saving = false;
        if (_step < 2) _step++;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.response?.data is Map<String, dynamic>
            ? ApiError.fromJson(e.response!.data as Map<String, dynamic>)
                .message
            : 'Couldn’t save. Try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Couldn’t save. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failed) {
      return Scaffold(
          appBar: AppBar(),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : AppMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn’t open this session',
                  actionLabel: 'Try again',
                  onAction: _load));
    }
    final activity = _session!['activity'] as Map<String, dynamic>;
    final prompt = _step == 0
        ? activity['predictionPrompt'] as String
        : _step == 1
            ? activity['practice']['prompt'] as String
            : activity['reflectionPrompt'] as String;
    return Scaffold(
      appBar: AppBar(
          title: Text(_session!['projectName'] as String,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            Text(_session!['title'] as String,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(_session!['objective'] as String,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            if (_session!['context']?['summary'] != null) ...[
              const SizedBox(height: 20),
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: true,
                  title: const Text('What changed'),
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_session!['context']['summary'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5))),
                    if ((_session!['context']['changes'] as List? ?? [])
                        .isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final change in _session!['context']
                                        ['changes'] as List)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text('• $change'))
                                  ]))),
                  ]),
            ],
            if (_videos.isNotEmpty) ...[
              const SizedBox(height: 24),
              for (final video in _videos)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.play_circle_outline_rounded, size: 36),
                    title: Text(video.title ?? 'Watch reel'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => ReelViewerScreen(
                                videos: _videos,
                                initialIndex: _videos.indexOf(video))))),
            ],
            const SizedBox(height: 24),
            SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('Predict')),
                  ButtonSegment(value: 1, label: Text('Practice')),
                  ButtonSegment(value: 2, label: Text('Reflect'))
                ],
                selected: {_step},
                onSelectionChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _step = value.single;
                          _error = null;
                        })),
            const SizedBox(height: 24),
            Text(prompt, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
                enabled: !_saving,
                key: ValueKey(_step),
                controller: _step == 0
                    ? _prediction
                    : _step == 1
                        ? _practice
                        : _reflection,
                minLines: 4,
                maxLines: 8,
                maxLength: _step == 0
                    ? 2000
                    : _step == 1
                        ? 4000
                        : 3000,
                decoration: const InputDecoration(
                    hintText: 'Your response', counterText: '')),
            if (_step == 1) ...[
              const SizedBox(height: 12),
              Text(activity['practice']['successCriteria'] as String,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              if (activity['practice']['hint'] != null)
                ExpansionTile(
                    title: const Text('Hint'),
                    tilePadding: EdgeInsets.zero,
                    children: [Text(activity['practice']['hint'] as String)]),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I tried it'),
                  value: _practiced,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _practiced = v ?? false)),
            ] else ...[
              const SizedBox(height: 20),
              Text('Confidence', style: Theme.of(context).textTheme.labelLarge),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final value in [1, 2, 3, 4, 5])
                  ChoiceChip(
                      label: Text('$value'),
                      tooltip: '$value of 5',
                      selected: _confidence == value,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() {
                                if (_step == 2) {
                                  _reflectionConfidence = value;
                                } else {
                                  _predictionConfidence = value;
                                }
                              }))
              ]),
            ],
            if (_step == 2) ...[
              const SizedBox(height: 16),
              TextField(
                  enabled: !_saving,
                  controller: _next,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      labelText: 'Next step (optional)', counterText: ''))
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.incorrect))
            ],
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? 'Saving…'
                    : _step == 0
                        ? 'Save prediction'
                        : _step == 1
                            ? 'Save attempt'
                            : 'Save reflection')),
            if (_step == 0)
              TextButton(
                  onPressed: _saving ? null : () => _save(skip: true),
                  child: const Text('Skip for now')),
          ]),
    );
  }
}
