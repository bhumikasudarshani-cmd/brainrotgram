import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../auth/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../player/video_reel_item.dart';
import '../studio/studio_job_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  final List<VideoJob> _videos = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            state: 'ready',
            limit: 10,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _videos.clear();
          _videos.addAll(loaded);
          _nextCursor = res['nextCursor'] as String?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            state: 'ready',
            cursor: _nextCursor,
            limit: 10,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _videos.addAll(loaded);
          _nextCursor = res['nextCursor'] as String?;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (index >= _videos.length - 2) {
      _loadMoreVideos();
    }
  }

  void _goToNextVideo() {
    if (_currentPage + 1 < _videos.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final studioJob = ref.watch(studioJobProvider);
    final userName = authState.user?.name ?? 'there';

    return Scaffold(
      backgroundColor:
          _videos.isEmpty ? AppColors.cream : AppColors.reelBackground,
      appBar: _videos.isEmpty
          ? AppBar(
              title: Text(
                'BrainRotGram',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 22,
                    ),
              ),
            )
          : null,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.purpleAccent),
            )
          else if (_videos.isEmpty)
            RefreshIndicator(
              onRefresh: _loadVideos,
              color: AppColors.purpleAccent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _EmptyHomeState(userName: userName),
                ],
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _loadVideos,
              color: AppColors.purpleAccent,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _videos.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final isWithinRange = (index - _currentPage).abs() <= 1;
                  if (!isWithinRange) {
                    return Container(color: AppColors.reelBackground);
                  }

                  return VideoReelItem(
                    key: ValueKey(_videos[index].jobId),
                    video: _videos[index],
                    isActive: index == _currentPage,
                    onNextVideo: _goToNextVideo,
                  );
                },
              ),
            ),

          // Job In Progress Pill
          if (studioJob.activeJobId != null && !studioJob.isCompleted)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: GestureDetector(
                onTap: () => context.go('/studio'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.plum.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.purpleAccent.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.yellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Making 1 video (${studioJob.stage ?? 'rendering'} ${studioJob.progress}%)',
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.uncutSans,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Completed Video Banner
          if (studioJob.isCompleted && studioJob.completedVideo != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  final readyVideo = studioJob.completedVideo;
                  ref.read(studioJobProvider.notifier).dismissBanner();
                  ref.invalidate(userQuotaProvider);
                  if (readyVideo != null) {
                    setState(() {
                      _videos.removeWhere((v) => v.jobId == readyVideo.jobId);
                      _videos.insert(0, readyVideo);
                      _currentPage = 0;
                    });
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  } else {
                    _loadVideos();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your video is ready!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: AppFonts.uncutSans,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Watch',
                          style: TextStyle(
                            color: AppColors.plum,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final String userName;

  const _EmptyHomeState({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Hey $userName 👋',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Your reels feed will appear here.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          _ActionCard(
            icon: Icons.movie_creation_outlined,
            iconColor: AppColors.purpleAccent,
            bgColor: AppColors.lavender.withValues(alpha: 0.5),
            title: 'Make your first video',
            subtitle:
                'Paste a question, an error, or a diff — get a one-minute reel.',
            buttonLabel: 'Open Studio',
            onTap: () {
              context.go('/studio');
            },
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.terminal_rounded,
            iconColor: AppColors.coral,
            bgColor: AppColors.coral.withValues(alpha: 0.15),
            title: 'Connect your coding agent',
            subtitle: 'Run this command in your project to start recording:',
            commandText:
                'pnpm brainrotten login --api-url https://fqfewiusg8.execute-api.ap-south-1.amazonaws.com/api/v1',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final String? commandText;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.commandText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 17,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              if (commandText != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.plum,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    commandText!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.cream,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (buttonLabel != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    child: Text(buttonLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
