import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

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

  static const _formats = [
    _FormatOption('sketch', 'Sketch board', 'Excalidraw-style architecture board',
        Icons.draw_rounded),
    _FormatOption('skit', 'Character skit', 'Two characters, question-answer',
        Icons.people_rounded),
    _FormatOption('prreview', 'PR review', 'GitHub-style diff and review',
        Icons.code_rounded),
    _FormatOption('tierlist', 'Tier list', 'TierMaker ranking board',
        Icons.format_list_numbered_rounded),
    _FormatOption('groupchat', 'Group chat', 'WhatsApp-style group thread',
        Icons.chat_rounded),
  ];

  static const _languages = {
    'en': 'English',
    'hinglish': 'Hinglish',
    'benglish': 'Benglish',
  };

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Studio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
              hintText:
                  'Paste an error, a diff summary, or a question…',
            ),
          ),
          const SizedBox(height: 24),

          // Format
          Text(
            'Format',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          ..._formats.map((f) => _FormatCard(
                format: f,
                selected: _selectedFormat == f.id,
                onTap: () => setState(() => _selectedFormat = f.id),
              )),
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
                      color: _questionCount == n ? Colors.white : AppColors.plum,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Quota info placeholder
          Container(
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
                  '_ of 5 free videos left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.plum,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _topicController.text.trim().isEmpty ? null : () {
                // TODO: POST /videos with requestId
              },
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

class _FormatOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const _FormatOption(this.id, this.name, this.description, this.icon);
}

class _FormatCard extends StatelessWidget {
  final _FormatOption format;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.purpleAccent.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.purpleAccent : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                format.icon,
                color: selected ? AppColors.purpleAccent : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: selected ? AppColors.purpleAccent : AppColors.plum,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      format.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.purpleAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
