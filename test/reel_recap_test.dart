import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainrotgram/api/models/models.dart';
import 'package:brainrotgram/features/quiz/end_quiz_overlay.dart';
import 'package:brainrotgram/theme/app_theme.dart';

void main() {
  testWidgets('last reel recap is dismissible and has no dead Next action',
      (tester) async {
    var closed = false, replayed = false;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: EndQuizOverlay(
                questions: const [],
                takeaway: 'Check the widget lifetime after an await.',
                onAnswer: (_, __) {},
                onResetAnswers: () {},
                onReplay: () => replayed = true,
                onClose: () => closed = true))));
    expect(find.text('Lesson Finished'), findsNothing);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.byTooltip('Close recap'));
    expect(closed, isTrue);
    await tester.tap(find.text('Replay'));
    expect(replayed, isTrue);
  });
  testWidgets('quiz records the selected answer and shows its real score',
      (tester) async {
    int? answer;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: EndQuizOverlay(
                questions: const [
              LearningQuestion(
                  id: 'q1',
                  prompt: 'Which guard?',
                  choices: ['mounted', 'delay'],
                  answer: 0,
                  explanation: 'Check the widget lifetime.',
                  startMs: 0,
                  endMs: 1000)
            ],
                onAnswer: (_, choice) => answer = choice,
                onResetAnswers: () {},
                onReplay: () {}))));
    await tester.tap(find.text('mounted'));
    await tester.pumpAndSettle();
    expect(answer, 0);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1 correct'), findsOneWidget);
  });
}
