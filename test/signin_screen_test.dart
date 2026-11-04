import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrotgram/features/signin/signin_screen.dart';
import 'package:brainrotgram/shared/widgets/brand_wordmark.dart';
import 'package:brainrotgram/theme/app_theme.dart';
import 'package:flutter/rendering.dart';

void main() {
  group('SignInScreen', () {
    testWidgets('displays wordmark and sign-in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInScreen(),
          ),
        ),
      );

      // Wordmark
      expect(find.text('brainrotgram'), findsOneWidget);

      // Tagline
      expect(find.text("Your agent's work, as reels"), findsOneWidget);

      // Google button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Disclaimer
      expect(
        find.textContaining('Unofficial, non-commercial fan project'),
        findsOneWidget,
      );
    });
  });
  for (final width in [320.0, 384.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
          'wordmark stays on one line at $width dp and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SignInScreen(),
        )));
        final brand = find.text('brainrotgram');
        expect(brand, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
            of: find.byType(BrandWordmark), matching: find.byType(RichText)));
        final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 12));
        expect(boxes.map((box) => box.top).toSet(), hasLength(1));
        final fitted = tester.getRect(find.byType(FittedBox).first);
        expect(fitted.left, greaterThanOrEqualTo(0));
        expect(fitted.right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
        expect(find.text('Continue with Google'), findsOneWidget);
      });
    }
  }
}
