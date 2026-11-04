import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AppMessage(
      {super.key,
      required this.icon,
      required this.title,
      this.detail,
      this.actionLabel,
      this.onAction});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 38, color: AppColors.purpleAccent),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!))
          ],
        ]),
      ));
}
