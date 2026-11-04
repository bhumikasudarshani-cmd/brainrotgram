import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models/models.dart';
import '../../theme/app_theme.dart';

class PausePredictOverlay extends StatefulWidget {
  final LearningQuestion question;
  final int? existingAnswer;
  final bool showExplanation;
  final double bottomInset;
  final Function(int choice) onAnswerSelected;

  const PausePredictOverlay({
    super.key,
    required this.question,
    this.existingAnswer,
    this.showExplanation = false,
    this.bottomInset = 0,
    required this.onAnswerSelected,
  });

  @override
  State<PausePredictOverlay> createState() => _PausePredictOverlayState();
}

class _PausePredictOverlayState extends State<PausePredictOverlay> {
  int? _selectedChoice;

  @override
  void initState() {
    super.initState();
    _selectedChoice = widget.existingAnswer;
  }

  @override
  void didUpdateWidget(covariant PausePredictOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingAnswer != null) {
      _selectedChoice = widget.existingAnswer;
    }
  }

  void _handleSelect(int index) {
    if (_selectedChoice != null) return; // already locked
    HapticFeedback.lightImpact();
    setState(() {
      _selectedChoice = index;
    });
    widget.onAnswerSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswered = _selectedChoice != null;
    final isRevealed = widget.showExplanation || hasAnswered;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomInset + 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.plum.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lavender.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Predict',
                    style: TextStyle(
                      fontFamily: AppFonts.uncutSans,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.yellow,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.question.prompt,
              style: const TextStyle(
                fontFamily: AppFonts.uncutSans,
                color: AppColors.cream,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.question.choices.length, (i) {
              final choiceText = widget.question.choices[i];
              Color btnBg = AppColors.surface.withValues(alpha: 0.12);
              Color border = Colors.white.withValues(alpha: 0.2);
              Color textColor = AppColors.cream;

              if (isRevealed) {
                if (i == widget.question.answer) {
                  btnBg = AppColors.correct.withValues(alpha: 0.3);
                  border = AppColors.correct;
                  textColor = AppColors.cream;
                } else if (_selectedChoice == i &&
                    i != widget.question.answer) {
                  btnBg = AppColors.incorrect.withValues(alpha: 0.3);
                  border = AppColors.incorrect;
                  textColor = AppColors.cream;
                }
              } else if (_selectedChoice == i) {
                btnBg = AppColors.purpleAccent.withValues(alpha: 0.4);
                border = AppColors.purpleAccent;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _handleSelect(i),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            choiceText,
                            style: TextStyle(
                              fontFamily: AppFonts.uncutSans,
                              color: textColor,
                              fontSize: 13,
                              fontWeight: _selectedChoice == i
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isRevealed && i == widget.question.answer)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.correct, size: 18)
                        else if (isRevealed &&
                            _selectedChoice == i &&
                            i != widget.question.answer)
                          const Icon(Icons.cancel_rounded,
                              color: AppColors.incorrect, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (isRevealed && widget.question.explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.explanation,
                  style: const TextStyle(
                    fontFamily: AppFonts.uncutSans,
                    color: AppColors.yellow,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
