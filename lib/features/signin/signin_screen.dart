import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/brand_wordmark.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Wordmark
              const BrandWordmark(fontSize: 32),
              const SizedBox(height: 12),
              // Tagline
              Text(
                "Your agent's work, as reels",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 17,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Illustration area
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 80,
                  color: AppColors.purpleAccent,
                ),
              ),
              const Spacer(flex: 2),
              // Continue with Google button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signIn(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    backgroundColor: AppColors.plum,
                    foregroundColor: AppColors.cream,
                    disabledBackgroundColor:
                        AppColors.plum.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.cream,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.plum,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                'Continue with Google',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Disclaimer
              Text(
                'Unofficial, non-commercial fan project. Characters and\ngameplay belong to their owners; voices are AI clones.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
