import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../shared/widgets/app_message.dart';
import '../../shared/widgets/brand_wordmark.dart';
import '../../theme/app_theme.dart';
import '../player/reel_viewer_screen.dart';
import '../sessions/session_detail_screen.dart';
import '../studio/studio_job_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<VideoJob> _videos = [];
  final List<SessionSummary> _sessions = [];
  String? _cursor;
  bool _loading = true, _failed = false, _more = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final result =
          await Future.wait<Object>([api.getVideos(), api.getSessionPage()]);
      if (!mounted) return;
      final page = result[1] as Map<String, dynamic>;
      setState(() {
        _videos = (result[0] as List<VideoJob>)
            .where((v) => v.state == 'ready')
            .toList();
        _sessions
          ..clear()
          ..addAll((page['sessions'] as List)
              .map((s) => SessionSummary.fromJson(s as Map<String, dynamic>)));
        _cursor = page['nextCursor'] as String?;
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

  Future<void> _loadMore() async {
    if (_more || _cursor == null) return;
    setState(() => _more = true);
    try {
      final page =
          await ref.read(apiServiceProvider).getSessionPage(cursor: _cursor);
      if (!mounted) return;
      setState(() {
        final ids = _sessions.map((s) => s.sessionId).toSet();
        _sessions.addAll((page['sessions'] as List)
            .map((s) => SessionSummary.fromJson(s as Map<String, dynamic>))
            .where((s) => ids.add(s.sessionId)));
        _cursor = page['nextCursor'] as String?;
        _more = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _more = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Couldn’t load more projects. Try again.')));
      }
    }
  }

  void _watch(List<VideoJob> videos, int index) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              ReelViewerScreen(videos: videos, initialIndex: index)));
  Future<void> _connect() async {
    try {
      await launchUrl(Uri.parse('https://d3sk6lwsh4ufyv.cloudfront.net/mcp'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Couldn’t open agent setup.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(studioJobProvider);
    ref.listen<StudioJobState>(studioJobProvider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) _load();
    });
    final projects = <String, List<SessionSummary>>{};
    for (final session in _sessions) {
      projects
          .putIfAbsent(
              session.projectName?.trim().isNotEmpty == true
                  ? session.projectName!
                  : 'Unassigned',
              () => [])
          .add(session);
    }
    return Scaffold(
      appBar: AppBar(
          centerTitle: false, titleSpacing: 20, title: const BrandWordmark()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? AppMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn’t load your work',
                  actionLabel: 'Try again',
                  onAction: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        20, 16, 20, MediaQuery.paddingOf(context).bottom + 24),
                    children: [
                      if (job.activeJobId != null && !job.isCompleted)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              tileColor: AppColors.lavender,
                              leading: job.error == null
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.error_outline_rounded),
                              title: Text(job.error == null
                                  ? 'Making your reel · ${job.progress}%'
                                  : 'Couldn’t create reel'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go('/studio'),
                            )),
                      Text('Projects',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      if (projects.isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No projects linked yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Ask your agent to save a learning session.'),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                      onPressed: _connect,
                                      icon: const Icon(Icons.terminal_rounded,
                                          size: 18),
                                      label: const Text('Connect your agent')),
                                ])),
                      for (final project in projects.entries)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    final ids = project.value
                                        .map((s) => s.sessionId)
                                        .toSet();
                                    Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                            builder: (_) => ProjectScreen(
                                                name: project.key,
                                                sessions: project.value,
                                                videos: _videos
                                                    .where((v) => ids
                                                        .contains(v.sessionId))
                                                    .toList())));
                                  },
                                  child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(children: [
                                        const Icon(Icons.folder_outlined,
                                            color: AppColors.purpleAccent,
                                            size: 28),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(project.key,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600)),
                                              const SizedBox(height: 6),
                                              Text(project.value.first.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              const SizedBox(height: 6),
                                              Text(
                                                  [
                                                    project.value.first.agent,
                                                    DateFormat.MMMd().format(
                                                        project.value.first
                                                            .createdAt
                                                            .toLocal())
                                                  ]
                                                      .whereType<String>()
                                                      .join(' · '),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                            ])),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right_rounded,
                                            size: 20),
                                      ]))),
                            )),
                      if (_cursor != null)
                        TextButton(
                            onPressed: _more ? null : _loadMore,
                            child: Text(_more ? 'Loading…' : 'More projects')),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: Text('Recent reels',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600))),
                        if (_videos.isNotEmpty)
                          TextButton(
                              onPressed: () => context.go('/search'),
                              child: const Text('View all'))
                      ]),
                      const SizedBox(height: 12),
                      if (_videos.isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.icon(
                                    onPressed: () => context.go('/studio'),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create a reel')))),
                      if (_videos.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _videos.length > 6 ? 6 : _videos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 268),
                          itemBuilder: (context, index) => _ReelCover(
                              video: _videos[index],
                              onTap: () => _watch(_videos, index)),
                        ),
                    ],
                  )),
    );
  }
}

class ProjectScreen extends StatelessWidget {
  final String name;
  final List<SessionSummary> sessions;
  final List<VideoJob> videos;
  const ProjectScreen(
      {super.key,
      required this.name,
      required this.sessions,
      required this.videos});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: ListView(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.paddingOf(context).bottom + 24),
            children: [
              Text('Agent checkpoints',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final session in sessions)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(session.title),
                      subtitle: session.objective == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(session.objective!)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => SessionDetailScreen(
                                  sessionId: session.sessionId))),
                    )),
              if (videos.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Reels', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                for (final video in videos)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_circle_outline_rounded,
                          size: 36),
                      title: Text(video.title ?? 'Untitled reel'),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => ReelViewerScreen(
                                  videos: videos,
                                  initialIndex: videos.indexOf(video))))),
              ],
            ]),
      );
}

class _ReelCover extends StatelessWidget {
  final VideoJob video;
  final VoidCallback onTap;
  const _ReelCover({required this.video, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
                height: 204,
                width: double.infinity,
                child: video.posterUrl == null
                    ? const ColoredBox(
                        color: AppColors.lavender,
                        child: Icon(Icons.movie_outlined,
                            color: AppColors.purpleAccent))
                    : CachedNetworkImage(
                        imageUrl: video.posterUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.lavender,
                            child: Icon(Icons.movie_outlined))))),
        const SizedBox(height: 10),
        Text(video.title ?? 'Untitled reel',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ]));
}
