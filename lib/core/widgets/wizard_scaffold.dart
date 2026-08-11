import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/property_wizard/providers/wizard_navigation_provider.dart';
import '../theme/theme_provider.dart';
import 'wizard_app_bar.dart';
import 'wizard_header.dart';
import '../../features/property_wizard/presentation/widgets/wizard_footer.dart';

class WizardScaffold extends ConsumerWidget {
  final String title;
  final String? description;
  final List<Widget> children;
  final Future<void> Function()? onNext;
  final VoidCallback? onBack;
  final Widget? bottomWidget;

  const WizardScaffold({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.onNext,
    this.onBack,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeConfigProvider);
    final navData = ref.watch(wizardNavigationProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: WizardAppBar(
        title: navData.headerTitle,
        onBack: onBack,
        theme: theme,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizardHeader(
                progressLabel: navData.progressLabel,
                title: title,
                description: description,
                theme: theme,
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomWidget ??
          (onNext != null
              ? WizardFooter(onNext: onNext)
              : null),
    );
  }
}
