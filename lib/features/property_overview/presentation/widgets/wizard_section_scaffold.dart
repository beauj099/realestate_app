import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../providers/property_provider.dart';

/// Shared chrome for every property-wizard section screen.
///
/// Gives each section one explicit way to commit — a Save button pinned to the
/// bottom of the screen, always visible regardless of how long the form is.
/// Backing out never writes anything: if the agent changed something they are
/// asked to confirm, and on confirm the shared [PropertyState] is rolled back
/// to what it was when the screen opened.
///
/// Content is supplied unscrolled via [child]; this widget owns the scroll view
/// so it can reserve room for the action bar and fade the content underneath it,
/// which is what signals there is more to scroll.
class WizardSectionScaffold extends ConsumerStatefulWidget {
  /// App bar title.
  final String title;

  /// Section body. Laid out in a [Column]; do not wrap in a scroll view.
  final Widget child;

  /// Persists the section. Returns the failure message, or `null` on success.
  final Future<String?> Function() onSave;

  /// Noun used in the discard prompt, e.g. "address".
  final String sectionName;

  /// Label for the commit button.
  final String saveLabel;

  /// Blocks saving and explains why, e.g. a validation failure.
  final String? Function()? validate;

  const WizardSectionScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    required this.sectionName,
    this.saveLabel = 'Save',
    this.validate,
  });

  @override
  ConsumerState<WizardSectionScaffold> createState() =>
      _WizardSectionScaffoldState();
}

class _WizardSectionScaffoldState extends ConsumerState<WizardSectionScaffold> {
  final _scrollController = ScrollController();
  bool _isSaving = false;
  bool _canScrollFurther = false;

  @override
  void initState() {
    super.initState();
    // Snapshot the shared state so a discard can restore it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(propertyViewModelProvider.notifier).beginSectionEdit();
      _updateScrollAffordance();
    });
    _scrollController.addListener(_updateScrollAffordance);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollAffordance);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollAffordance() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final more = position.pixels < position.maxScrollExtent - 8;
    if (more != _canScrollFurther) setState(() => _canScrollFurther = more);
  }

  Future<void> _handleSave() async {
    final validationError = widget.validate?.call();
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final error = await widget.onSave();
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    ref.read(propertyViewModelProvider.notifier).commitSectionEdit();
    if (mounted) context.pop();
  }

  /// Back gesture: discard, after confirming when there is something to lose.
  Future<void> _handleBack() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    if (!viewModel.hasUnsavedSectionChanges) {
      viewModel.discardSectionEdit();
      if (mounted) context.pop();
      return;
    }

    final theme = ref.read(themeConfigProvider);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: const Text('Discard changes?'),
        content: Text(
          'Your ${widget.sectionName} changes have not been saved. '
          'Go back and they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Keep editing',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: theme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard != true || !mounted) return;
    viewModel.discardSectionEdit();
    if (mounted) context.pop();
  }

  void _showMessage(String message, {required bool isError}) {
    final theme = ref.read(themeConfigProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.error : theme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: widget.title,
          onBack: _handleBack,
          theme: theme,
        ),
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    // Bottom padding clears the pinned action bar so the last
                    // field is never trapped underneath it.
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: widget.child,
                  ),
                ),
                // Fade hinting at content continuing below the action bar.
                if (_canScrollFurther)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.backgroundColor.withValues(alpha: 0),
                              theme.backgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildActionBar(theme, textTheme),
      ),
    );
  }

  Widget _buildActionBar(RealEstateTheme theme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(top: BorderSide(color: theme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: _isSaving
                ? Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.primaryColor,
                      ),
                    ),
                  )
                : CustomButton(
                    text: widget.saveLabel,
                    fullWidth: true,
                    theme: theme,
                    onTap: _handleSave,
                  ),
          ),
        ),
      ),
    );
  }
}
