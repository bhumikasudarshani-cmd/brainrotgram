import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/api_service.dart';
import '../../api/models/models.dart';
import '../../shared/widgets/app_message.dart';
import '../../theme/app_theme.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final List<SessionSummary> _sessions = [];
  String? _cursor;
  bool _loading = true, _failed = false, _more = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_more || _loading || _cursor == null)) return;
    setState(() {
      _failed = false;
      if (more) {
        _more = true;
      } else {
        _loading = true;
      }
    });
    try {
      final page = await ref
          .read(apiServiceProvider)
          .getSessionPage(cursor: more ? _cursor : null);
      final rows = (page['sessions'] as List)
          .map((s) => SessionSummary.fromJson(s as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        if (!more) _sessions.clear();
        final ids = _sessions.map((s) => s.sessionId).toSet();
        _sessions.addAll(rows.where((s) => ids.add(s.sessionId)));
        _cursor = page['nextCursor'] as String?;
        _loading = false;
        _more = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
          _more = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Learn')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed && _sessions.isEmpty
                ? AppMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Couldn’t load your sessions',
                    actionLabel: 'Try again',
                    onAction: _load)
                : _sessions.isEmpty
                    ? const AppMessage(
                        icon: Icons.school_outlined,
                        title: 'No learning sessions yet',
                        detail: 'Sessions from your coding agent appear here.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(20, 12, 20,
                              MediaQuery.paddingOf(context).bottom + 24),
                          itemCount: _sessions.length +
                              (_cursor != null || _failed ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            if (i == _sessions.length) {
                              return TextButton(
                                  onPressed: _more
                                      ? null
                                      : () => _load(more: !_failed),
                                  child: Text(_more
                                      ? 'Loading…'
                                      : _failed
                                          ? 'Try again'
                                          : 'Load more'));
                            }
                            final session = _sessions[i];
                            return Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) => SessionDetailScreen(
                                              sessionId: session.sessionId))),
                                  child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                [
                                                  session.projectName,
                                                  DateFormat.MMMd().format(
                                                      session.createdAt
                                                          .toLocal())
                                                ]
                                                    .whereType<String>()
                                                    .where((s) => s.isNotEmpty)
                                                    .join(' · '),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            const SizedBox(height: 8),
                                            Row(children: [
                                              Expanded(
                                                  child: Text(session.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600))),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20)
                                            ]),
                                            if (session.objective?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 8),
                                              Text(session.objective!,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary))
                                            ],
                                          ])),
                                ));
                          },
                        )),
      );
}
