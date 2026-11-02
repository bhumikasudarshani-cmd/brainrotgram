import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models/models.dart';
import '../../theme/app_theme.dart';

class EndQuizOverlay extends StatefulWidget {
  final List<LearningQuestion> questions;
  final String? takeaway;
  final Function(String questionId, int choice) onAnswer;
  final VoidCallback onResetAnswers;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const EndQuizOverlay({
    super.key,
    required this.questions,
    this.takeaway,
    required this.onAnswer,
    required this.onResetAnswers,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<EndQuizOverlay> createState() => _EndQuizOverlayState();
}

class _EndQuizOverlayState extends State<EndQuizOverlay> {
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};
  bool _isAnswered = false;
  bool _completed = false;

  int get _score {
    int count = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_userAnswers[i] == widget.questions[i].answer) {
        count++;
      }
    }
    return count;
  }

  void _selectChoice(int choice) {
    if (_isAnswered) return;
    HapticFeedback.lightImpact();
    final q = widget.questions[_currentIndex];

    setState(() {
      _userAnswers[_currentIndex] = choice;
      _isAnswered = true;
    });

    widget.onAnswer(q.id, choice);
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < widget.questions.length) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _completed = true;
      });
    }
  }

  void _restartQuiz() {
    widget.onResetAnswers();
    setState(() {
      _currentIndex = 0;
      _userAnswers.clear();
      _isAnswered = false;
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return _buildTakeawayView();
    }

    if (_completed) {
      return _buildScoreSummaryView();
    }

    final q = widget.questions[_currentIndex];
    final selectedChoice = _userAnswers[_currentIndex];

    return Container(
      color: AppColors.plum.withValues(alpha: 0.98),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Question ${_currentIndex + 1} of ${widget.questions.length}',
                    style: const TextStyle(
                      fontFamily: AppFonts.uncutSans,
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onReplay,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded,
                          color: AppColors.cream, size: 16),
                      SizedBox(width: 4),
                      Text('Replay',
                          style: TextStyle(
                              color: AppColors.cream,
                              fontFamily: AppFonts.uncutSans)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              q.prompt,
              style: const TextStyle(
                fontFamily: AppFonts.basteleur,
                color: AppColors.cream,
                fontSize: 22,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: q.choices.length,
                itemBuilder: (ctx, i) {
                  final choiceText = q.choices[i];
                  Color bg = AppColors.surface.withValues(alpha: 0.1);
                  Color border = Colors.white.withValues(alpha: 0.2);
                  Color textColor = AppColors.cream;

                  if (_isAnswered) {
                    if (i == q.answer) {
                      bg = AppColors.correct.withValues(alpha: 0.35);
                      border = AppColors.correct;
                    } else if (selectedChoice == i && i != q.answer) {
                      bg = AppColors.incorrect.withValues(alpha: 0.35);
                      border = AppColors.incorrect;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectChoice(i),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                choiceText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
            ),
            if (_isAnswered) ...[
              if (q.explanation.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lavender.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    q.explanation,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentIndex + 1 < widget.questions.length
                        ? 'Next Question'
                        : 'View Results',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSummaryView() {
    return Container(
      color: AppColors.plum.withValues(alpha: 0.98),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.yellow,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quiz Completed!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.cream,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_score of ${widget.questions.length} correct',
              style: const TextStyle(
                fontFamily: AppFonts.uncutSans,
                color: AppColors.coral,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.takeaway != null && widget.takeaway!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.lavender.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KEY TAKEAWAY',
                      style: TextStyle(
                        fontFamily: AppFonts.uncutSans,
                        color: AppColors.yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.takeaway!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReplay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cream,
                      side: const BorderSide(color: AppColors.lavender),
                    ),
                    child: const Text('Replay'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restartQuiz,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cream,
                      side: const BorderSide(color: AppColors.lavender),
                    ),
                    child: const Text('Retry Quiz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Next Video',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakeawayView() {
    return Container(
      color: AppColors.plum.withValues(alpha: 0.98),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.correct, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Lesson Finished',
              style: TextStyle(
                fontFamily: AppFonts.basteleur,
                color: AppColors.cream,
                fontSize: 24,
              ),
            ),
            if (widget.takeaway != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.takeaway!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.lavender,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: widget.onReplay,
                  child: const Text('Replay'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpleAccent),
                  child: const Text('Next Video'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
