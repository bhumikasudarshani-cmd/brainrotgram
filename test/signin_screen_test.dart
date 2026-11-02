import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrotgram/features/signin/signin_screen.dart';

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
      expect(find.text('BrainRotGram'), findsOneWidget);

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
}
