import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_constants.dart';
import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../auth/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../player/reel_viewer_screen.dart';
import '../studio/studio_job_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<VideoJob> _readyVideos = [];
  String? _readyCursor;
  bool _isLoadingReady = false;
  bool _isLoadingMoreReady = false;

  final List<VideoJob> _savedVideos = [];
  String? _savedCursor;
  bool _isLoadingSaved = false;
  bool _isLoadingMoreSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _scrollController.addListener(_onScroll);

    _loadReadyVideos();
    _loadSavedVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_tabController.index == 0) {
        _loadMoreReadyVideos();
      } else {
        _loadMoreSavedVideos();
      }
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(userQuotaProvider);
    await Future.wait([
      _loadReadyVideos(),
      _loadSavedVideos(),
    ]);
  }

  Future<void> _loadReadyVideos() async {
    setState(() => _isLoadingReady = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            state: 'ready',
            limit: 12,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _readyVideos.clear();
          _readyVideos.addAll(loaded);
          _readyCursor = res['nextCursor'] as String?;
          _isLoadingReady = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReady = false);
    }
  }

  Future<void> _loadMoreReadyVideos() async {
    if (_isLoadingMoreReady || _readyCursor == null) return;
    setState(() => _isLoadingMoreReady = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            state: 'ready',
            cursor: _readyCursor,
            limit: 12,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _readyVideos.addAll(loaded);
          _readyCursor = res['nextCursor'] as String?;
          _isLoadingMoreReady = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreReady = false);
    }
  }

  Future<void> _loadSavedVideos() async {
    setState(() => _isLoadingSaved = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            review: 'bookmarked',
            limit: 12,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _savedVideos.clear();
          _savedVideos.addAll(loaded);
          _savedCursor = res['nextCursor'] as String?;
          _isLoadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  Future<void> _loadMoreSavedVideos() async {
    if (_isLoadingMoreSaved || _savedCursor == null) return;
    setState(() => _isLoadingMoreSaved = true);
    try {
      final res = await ref.read(apiServiceProvider).getLibrary(
            review: 'bookmarked',
            cursor: _savedCursor,
            limit: 12,
          );
      final rawJobs = res['jobs'] as List? ?? [];
      final loaded = rawJobs
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _savedVideos.addAll(loaded);
          _savedCursor = res['nextCursor'] as String?;
          _isLoadingMoreSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreSaved = false);
    }
  }

  void _openReelViewer(List<VideoJob> videos, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReelViewerScreen(
          videos: videos,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _onSignOutPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final logoutUri = Uri.parse(
        '${ApiConstants.logoutEndpoint}?client_id=${ApiConstants.clientId}&logout_uri=${ApiConstants.signOutUri}',
      );
      try {
        await launchUrl(logoutUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Widget _buildQuotaRing(AsyncValue<UserQuota> quotaAsync) => quotaAsync.when(
        data: (quota) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('${quota.remaining} of ${quota.limit} free reels left',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))),
        loading: () => const SizedBox(
            height: 20, child: Center(child: LinearProgressIndicator())),
        error: (_, __) => const Text('Couldn’t load your balance',
            textAlign: TextAlign.center),
      );

  Widget _buildPosterGrid({
    required List<VideoJob> videos,
    required bool isLoading,
    required bool isLoadingMore,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (isLoading && videos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purpleAccent),
        ),
      );
    }

    if (videos.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.plum,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return InkWell(
              onTap: () => _openReelViewer(videos, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: AppColors.surface,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (video.posterUrl != null && !video.mediaExpired)
                        CachedNetworkImage(
                          imageUrl: video.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.lavender,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.plum,
                            child: const Center(
                              child: Icon(Icons.movie_rounded,
                                  color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.plum,
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              video.formatLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Bottom gradient overlay with title & format
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                video.title ?? video.formatLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purpleAccent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final quotaAsync = ref.watch(userQuotaProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.purpleAccent,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.purpleAccent,
                    backgroundImage: user?.pictureUrl != null
                        ? NetworkImage(user!.pictureUrl!)
                        : null,
                    child: user?.pictureUrl == null
                        ? Text(
                            user?.initials ?? '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Quota ring from GET /me
            _buildQuotaRing(quotaAsync),
            const SizedBox(height: 24),

            // Videos / Saved tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.plum,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.purpleAccent,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Saved'),
              ],
            ),
            const SizedBox(height: 16),

            // Active Tab Content
            if (_tabController.index == 0)
              _buildPosterGrid(
                videos: _readyVideos,
                isLoading: _isLoadingReady,
                isLoadingMore: _isLoadingMoreReady,
                emptyTitle: 'No videos yet',
                emptySubtitle: 'Create a reel or send one from your agent.',
                emptyIcon: Icons.movie_outlined,
              )
            else
              _buildPosterGrid(
                videos: _savedVideos,
                isLoading: _isLoadingSaved,
                isLoadingMore: _isLoadingMoreSaved,
                emptyTitle: 'No saved videos',
                emptySubtitle: 'Reels you bookmark appear here.',
                emptyIcon: Icons.bookmark_border_rounded,
              ),
            const SizedBox(height: 28),

            // About row
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                    color: AppColors.purpleAccent),
                title: const Text(
                  'About',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Unofficial, non-commercial fan project. Characters and gameplay belong to their owners; voices are AI clones.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.open_in_new_rounded,
                    size: 18, color: AppColors.textSecondary),
                onTap: () async {
                  final uri = Uri.parse(
                      'https://d3sk6lwsh4ufyv.cloudfront.net/credits.html');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
            ),
            const SizedBox(height: 10),

            // Sign out row
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.coral),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.coral,
                  ),
                ),
                onTap: _onSignOutPressed,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
