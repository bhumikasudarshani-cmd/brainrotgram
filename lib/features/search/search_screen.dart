import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search your videos...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _FilterChip(label: 'All', selected: true),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Sketch board'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Character skit'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'PR review'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Tier list'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Group chat'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress filter chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _FilterChip(label: 'Unwatched', icon: Icons.visibility_off_outlined),
                  SizedBox(width: 8),
                  _FilterChip(label: 'In Progress', icon: Icons.play_arrow_rounded),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Completed', icon: Icons.check_circle_outline),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Unanswered', icon: Icons.help_outline_rounded),
                ],
              ),
            ),
            const Spacer(),
            // Empty state
            Column(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search your video library',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Filter by format, progress, or keywords.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    this.selected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.plum,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.purpleAccent,
      side: BorderSide(
        color: selected ? Colors.transparent : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
