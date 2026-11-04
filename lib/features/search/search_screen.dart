import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../shared/widgets/app_message.dart';
import '../../theme/app_theme.dart';
import '../player/reel_viewer_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  final List<VideoJob> _videos = [];
  Timer? _debounce;
  String? _format, _cursor;
  String _review = 'all';
  bool _loading = true, _loadingMore = false, _failed = false;
  int _request = 0;
  static const formats = {
    'sketch': 'Sketch',
    'skit': 'Skit',
    'prreview': 'PR review',
    'tierlist': 'Tier list',
    'groupchat': 'Group chat'
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || _loading || _cursor == null)) return;
    final request = more ? _request : ++_request;
    setState(() {
      _failed = false;
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _loadingMore = false;
        _videos.clear();
        _cursor = null;
      }
    });
    try {
      final page = await ref.read(apiServiceProvider).getLibrary(
          q: _query.text.trim(),
          format: _format,
          review: _review,
          state: 'ready',
          cursor: more ? _cursor : null,
          limit: 20);
      final videos = (page['jobs'] as List)
          .map((v) => VideoJob.fromJson(v as Map<String, dynamic>))
          .toList();
      if (!mounted || request != _request) return;
      setState(() {
        if (!more) _videos.clear();
        final ids = _videos.map((v) => v.jobId).toSet();
        _videos.addAll(videos.where((v) => ids.add(v.jobId)));
        _cursor = page['nextCursor'] as String?;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _changed(String value) {
    _debounce?.cancel();
    // Invalidate older responses as soon as the user changes their query.
    _request++;
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _filter() {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Format',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item
                          in {'': 'All formats', ...formats}.entries)
                        ChoiceChip(
                            label: Text(item.value),
                            selected: (_format ?? '') == item.key,
                            onSelected: (_) {
                              setState(() =>
                                  _format = item.key.isEmpty ? null : item.key);
                              Navigator.pop(sheet);
                              _debounce?.cancel();
                              _load();
                            }),
                    ]),
                  ]),
            )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your reels'), actions: [
          IconButton(
              tooltip: 'Filter by format',
              onPressed: _filter,
              icon: Icon(Icons.tune_rounded,
                  color: _format == null
                      ? AppColors.plum
                      : AppColors.purpleAccent))
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _query,
                onChanged: _changed,
                maxLength: 120,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _load();
                },
                decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Search reels',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _query.clear();
                              _load();
                            })),
              )),
          SizedBox(
              height: 48,
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final item in {
                      'all': 'All',
                      'unwatched': 'Unwatched',
                      'bookmarked': 'Saved',
                      'needs-practice': 'Practice'
                    }.entries)
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(item.value),
                              selected: _review == item.key,
                              onSelected: (_) {
                                setState(() => _review = item.key);
                                _debounce?.cancel();
                                _load();
                              })),
                    if (_format != null)
                      InputChip(
                          label: Text(formats[_format]!),
                          onDeleted: () {
                            setState(() => _format = null);
                            _load();
                          }),
                  ])),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _failed && _videos.isEmpty
                    ? AppMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Couldn’t load your reels',
                        actionLabel: 'Try again',
                        onAction: _load)
                    : _videos.isEmpty
                        ? AppMessage(
                            icon: Icons.search_rounded,
                            title: _query.text.isEmpty &&
                                    _review == 'all' &&
                                    _format == null
                                ? 'No reels yet'
                                : 'No matches',
                            actionLabel: 'Create a reel',
                            onAction: () => context.go('/studio'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(20, 12, 20,
                                  MediaQuery.paddingOf(context).bottom + 24),
                              itemCount: _videos.length +
                                  (_cursor != null || _failed ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                if (i == _videos.length) {
                                  return TextButton(
                                      onPressed: _loadingMore
                                          ? null
                                          : () => _load(more: !_failed),
                                      child: Text(_loadingMore
                                          ? 'Loading…'
                                          : _failed
                                              ? 'Try again'
                                              : 'Load more'));
                                }
                                final video = _videos[i];
                                return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                            builder: (_) => ReelViewerScreen(
                                                videos: _videos.toList(),
                                                initialIndex: i))),
                                    child: Row(children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: SizedBox(
                                              width: 72,
                                              height: 104,
                                              child: video.posterUrl == null
                                                  ? const ColoredBox(
                                                      color: AppColors.lavender,
                                                      child: Icon(Icons
                                                          .play_arrow_rounded))
                                                  : CachedNetworkImage(
                                                      imageUrl:
                                                          video.posterUrl!,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (_, __,
                                                              ___) =>
                                                          const ColoredBox(
                                                              color: AppColors
                                                                  .lavender,
                                                              child: Icon(Icons
                                                                  .movie_outlined))))),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(video.title ?? 'Untitled reel',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                            const SizedBox(height: 8),
                                            Text(
                                                '${video.formatLabel}${video.durationSeconds == null ? '' : ' · ${Duration(seconds: video.durationSeconds!.round()).inMinutes}:${(video.durationSeconds!.round() % 60).toString().padLeft(2, '0')}'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          ])),
                                      if (video.review?.bookmarked == true)
                                        const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.bookmark_rounded,
                                                size: 20,
                                                color: AppColors.purpleAccent)),
                                    ]));
                              },
                            )),
          ),
        ]),
      );
}
