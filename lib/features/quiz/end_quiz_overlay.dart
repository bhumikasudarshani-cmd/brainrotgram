import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/models/models.dart';
import '../../theme/app_theme.dart';

class EndQuizOverlay extends StatefulWidget {
  final List<LearningQuestion> questions;
  final String? takeaway;
  final void Function(String questionId, int choice) onAnswer;
  final VoidCallback onResetAnswers, onReplay;
  final VoidCallback? onNext, onClose;
  const EndQuizOverlay(
      {super.key,
      required this.questions,
      this.takeaway,
      required this.onAnswer,
      required this.onResetAnswers,
      required this.onReplay,
      this.onNext,
      this.onClose});
  @override
  State<EndQuizOverlay> createState() => _EndQuizOverlayState();
}

class _EndQuizOverlayState extends State<EndQuizOverlay> {
  int _index = 0;
  final Map<int, int> _answers = {};
  bool _complete = false;
  int get _correct => _answers.entries
      .where((e) => e.value == widget.questions[e.key].answer)
      .length;

  Widget _actions() => Row(children: [
        Expanded(
            child: OutlinedButton.icon(
                onPressed: widget.onReplay,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Replay'))),
        if (widget.onNext != null) ...[
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton.icon(
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next')))
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final summary = widget.questions.isEmpty || _complete;
    final question = summary ? null : widget.questions[_index];
    final answer = _answers[_index];
    return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.sizeOf(context).height * .72),
          child: Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                summary
                                    ? widget.questions.isEmpty
                                        ? 'Takeaway'
                                        : '$_correct / ${widget.questions.length} correct'
                                    : '${_index + 1} / ${widget.questions.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary))),
                        if (widget.onClose != null)
                          IconButton(
                              tooltip: 'Close recap',
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close_rounded, size: 20)),
                      ]),
                      Flexible(
                          child: SingleChildScrollView(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                            if (summary) ...[
                              if (widget.takeaway?.isNotEmpty == true)
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 20),
                                    child: Text(widget.takeaway!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(height: 1.5))),
                              if (_complete)
                                TextButton(
                                    onPressed: () {
                                      widget.onResetAnswers();
                                      setState(() {
                                        _index = 0;
                                        _answers.clear();
                                        _complete = false;
                                      });
                                    },
                                    child: const Text('Try again')),
                            ] else ...[
                              const SizedBox(height: 8),
                              Text(question!.prompt,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 20),
                              for (final choice
                                  in question.choices.asMap().entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: answer == null
                                            ? () {
                                                HapticFeedback.selectionClick();
                                                setState(() =>
                                                    _answers[_index] =
                                                        choice.key);
                                                widget.onAnswer(
                                                    question.id, choice.key);
                                              }
                                            : null,
                                        style: OutlinedButton.styleFrom(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.all(16),
                                          foregroundColor: AppColors.plum,
                                          disabledForegroundColor:
                                              AppColors.plum,
                                          backgroundColor: answer == null
                                              ? AppColors.surface
                                              : choice.key == question.answer
                                                  ? AppColors.correct
                                                      .withValues(alpha: .16)
                                                  : choice.key == answer
                                                      ? AppColors.incorrect
                                                          .withValues(
                                                              alpha: .12)
                                                      : AppColors.surface,
                                          side: BorderSide(
                                              color: answer != null &&
                                                      choice.key ==
                                                          question.answer
                                                  ? AppColors.correct
                                                  : AppColors.divider),
                                        ),
                                        child: Row(children: [
                                          Expanded(child: Text(choice.value)),
                                          if (answer != null &&
                                              choice.key == question.answer)
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors.correct,
                                                size: 20)
                                        ]),
                                      )),
                                ),
                              if (answer != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(question.explanation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(height: 1.5))),
                            ],
                          ]))),
                      if (summary)
                        _actions()
                      else
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: answer == null
                                  ? null
                                  : () => setState(() {
                                        if (_index + 1 <
                                            widget.questions.length) {
                                          _index++;
                                        } else {
                                          _complete = true;
                                        }
                                      }),
                              child: Text(_index + 1 < widget.questions.length
                                  ? 'Continue'
                                  : 'Done'),
                            )),
                    ]),
              )),
        ));
  }
}
