import 'package:flutter/material.dart';

import '../theme/themes.dart';
import 'real_estate_dialog.dart';

/// Opens a tick-list sheet and returns the final selection, or null if the
/// agent cancelled.
///
/// Everything in [initiallySelected] starts ticked, so the same sheet adds
/// and removes in one pass. With [createCustom], the agent can also type an
/// entry that is not listed; it joins the list already ticked.
///
/// The confirm button is pinned under the list with the running count, so it
/// is always reachable however long the list is.
Future<List<T>?> showMultiSelectSheet<T>({
  required BuildContext context,
  required RealEstateTheme theme,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  IconData Function(T)? iconOf,
  Iterable<T> initiallySelected = const [],
  String subtitle = 'Tick everything that applies.',
  String confirmLabel = 'Add',
  bool allowEmpty = false,
  T Function(String)? createCustom,
}) {
  return showRealEstateBottomSheet<List<T>>(
    context: context,
    theme: theme,
    builder: (_) => _MultiSelectSheet<T>(
      theme: theme,
      title: title,
      subtitle: subtitle,
      options: options,
      labelOf: labelOf,
      iconOf: iconOf,
      initiallySelected: initiallySelected.toList(),
      confirmLabel: confirmLabel,
      allowEmpty: allowEmpty,
      createCustom: createCustom,
    ),
  );
}

class _MultiSelectSheet<T> extends StatefulWidget {
  final RealEstateTheme theme;
  final String title;
  final String subtitle;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final List<T> initiallySelected;
  final String confirmLabel;
  final bool allowEmpty;
  final T Function(String)? createCustom;

  const _MultiSelectSheet({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.labelOf,
    required this.iconOf,
    required this.initiallySelected,
    required this.confirmLabel,
    required this.allowEmpty,
    required this.createCustom,
  });

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  final _customController = TextEditingController();

  /// Custom entries typed in this session, listed first.
  final List<T> _custom = [];

  /// Ticked options, in the order they were ticked.
  late final List<T> _selected = List.of(widget.initiallySelected);

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(T option) {
    setState(() {
      if (!_selected.remove(option)) _selected.add(option);
    });
  }

  void _submitCustom() {
    final text = _customController.text.trim();
    final create = widget.createCustom;
    if (text.isEmpty || create == null) return;
    // Typing a name that is already listed ticks that entry instead.
    final match = [..._custom, ...widget.options]
        .where((o) => widget.labelOf(o).toLowerCase() == text.toLowerCase())
        .firstOrNull;
    setState(() {
      final option = match ?? create(text);
      if (match == null) _custom.add(option);
      if (!_selected.contains(option)) _selected.add(option);
      _customController.clear();
    });
  }

  String get _confirmText {
    final count = _selected.length;
    return count == 0 ? widget.confirmLabel : '${widget.confirmLabel} ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final options = [..._custom, ...widget.options];
    final canConfirm = widget.allowEmpty || _selected.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              if (widget.createCustom != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customController,
                  textCapitalization: TextCapitalization.sentences,
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Something else?',
                    hintText: 'Type it and tap +',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.5),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Add to list',
                      icon: Icon(Icons.add_circle, color: theme.primaryColor),
                      onPressed: _submitCustom,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitCustom(),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        Flexible(
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Everything listed is already added.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final option = options[i];
                    final icon = widget.iconOf?.call(option);
                    return CheckboxListTile(
                      value: _selected.contains(option),
                      onChanged: (_) => _toggle(option),
                      dense: true,
                      activeColor: theme.primaryColor,
                      checkColor: theme.onPrimary,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: icon == null
                          ? null
                          : Icon(icon, color: theme.textSecondary, size: 20),
                      title: Text(
                        widget.labelOf(option),
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.borderLight)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.pop(context, List.of(_selected))
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_confirmText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
