import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../providers/wizard_navigation_provider.dart';

class WizardFooter extends ConsumerWidget {
  final Future<void> Function()? onNext;

  const WizardFooter({super.key, this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navData = ref.watch(wizardNavigationProvider);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(top: BorderSide(color: theme.borderLight, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                navData.progressLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                navData.currentStep.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          CustomButton(
            text: 'Next',
            icon: Icon(Icons.arrow_forward, color: theme.onPrimary, size: 16),
            onTap: navData.canGoNext
                ? () async {
                    await onNext?.call();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
